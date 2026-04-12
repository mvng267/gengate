import { apiRequest } from "@/lib/api/client";
import { env } from "@/lib/config/env";

import type {
  AuthLoginInput,
  AuthLoginResult,
  AuthRegisterInput,
  BackendLoginPayload,
  BackendSessionSnapshot,
  RestoreSessionResult,
  StoredAuthSession,
} from "./types";

const DEFAULT_LOGIN_REDIRECT = "/feed";
const AUTH_SESSION_STORAGE_KEY = "gengate.auth.session";

function normalizeEmail(value: string) {
  return value.trim().toLowerCase();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object";
}

async function readErrorDetail(response: Response): Promise<string | undefined> {
  try {
    const data: unknown = await response.json();
    if (isRecord(data) && typeof data.detail === "string") {
      return data.detail;
    }
  } catch {
    return undefined;
  }

  return undefined;
}

function isBackendLoginPayload(value: unknown): value is BackendLoginPayload {
  if (!isRecord(value)) {
    return false;
  }

  return (
    typeof value.user_id === "string" &&
    typeof value.email === "string" &&
    typeof value.device_id === "string" &&
    typeof value.session_id === "string" &&
    typeof value.refresh_token === "string" &&
    typeof value.expires_at === "string" &&
    typeof value.expires_in_seconds === "number" &&
    typeof value.token_type === "string" &&
    typeof value.bootstrap_mode === "string" &&
    typeof value.session_status === "string"
  );
}

function isBackendSessionSnapshot(value: unknown): value is BackendSessionSnapshot {
  if (!isRecord(value)) {
    return false;
  }

  return (
    typeof value.user_id === "string" &&
    typeof value.email === "string" &&
    typeof value.device_id === "string" &&
    typeof value.session_id === "string" &&
    typeof value.expires_at === "string" &&
    typeof value.expires_in_seconds === "number" &&
    typeof value.token_type === "string" &&
    typeof value.session_status === "string"
  );
}

async function readSessionSnapshot(response: Response): Promise<BackendSessionSnapshot | undefined> {
  try {
    const data: unknown = await response.json();
    if (isBackendSessionSnapshot(data)) {
      return data;
    }
  } catch {
    return undefined;
  }

  return undefined;
}

async function registerWithEmail(email: string, username: string) {
  const response = await apiRequest(env.authRegisterPath, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      email,
      username,
    }),
  });

  return response;
}

function canUseBrowserStorage() {
  return typeof window !== "undefined" && typeof window.localStorage !== "undefined";
}

export function persistAuthSession(payload: BackendLoginPayload): StoredAuthSession | null {
  const session: StoredAuthSession = {
    refreshToken: payload.refresh_token,
    session: {
      user_id: payload.user_id,
      email: payload.email,
      device_id: payload.device_id,
      session_id: payload.session_id,
      expires_at: payload.expires_at,
      expires_in_seconds: payload.expires_in_seconds,
      token_type: payload.token_type,
      session_status: payload.session_status,
    },
  };

  if (canUseBrowserStorage()) {
    window.localStorage.setItem(AUTH_SESSION_STORAGE_KEY, JSON.stringify(session));
  }

  return session;
}

export function clearPersistedAuthSession() {
  if (canUseBrowserStorage()) {
    window.localStorage.removeItem(AUTH_SESSION_STORAGE_KEY);
  }
}

export async function logoutPersistedSession(): Promise<{
  ok: boolean;
  message: string;
  backendDetail?: string;
}> {
  const stored = readPersistedAuthSession();
  if (!stored) {
    clearPersistedAuthSession();
    return {
      ok: true,
      message: "Không có persisted session để logout; local state đã sạch.",
    };
  }

  try {
    const response = await apiRequest(env.authLogoutPath, {
      method: "POST",
      headers: {
        "content-type": "application/json",
      },
      body: JSON.stringify({
        refresh_token: stored.refreshToken,
      }),
    });

    if (response.ok) {
      const snapshot = await readSessionSnapshot(response);
      clearPersistedAuthSession();
      const backendDetail = snapshot?.session_status;
      const suffix = backendDetail ? ` (${backendDetail})` : "";
      return {
        ok: true,
        message: `Đã revoke session hiện tại${suffix} và xóa persisted session local.`,
        backendDetail,
      };
    }

    if (response.status === 401) {
      const backendDetail = await readErrorDetail(response);
      clearPersistedAuthSession();
      const suffix = backendDetail ? ` (${backendDetail})` : "";
      return {
        ok: true,
        message: `Backend báo session logout không còn hợp lệ${suffix}; local session vẫn đã được xóa.`,
        backendDetail,
      };
    }

    clearPersistedAuthSession();
    return {
      ok: false,
      message: `Logout request failed with status ${response.status}; local session vẫn đã được xóa.`,
    };
  } catch {
    clearPersistedAuthSession();
    return {
      ok: false,
      message: "Không thể gọi logout endpoint; local session vẫn đã được xóa.",
    };
  }
}

export function readPersistedAuthSession(): StoredAuthSession | null {
  if (!canUseBrowserStorage()) {
    return null;
  }

  const raw = window.localStorage.getItem(AUTH_SESSION_STORAGE_KEY);
  if (!raw) {
    return null;
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!isRecord(parsed)) {
      return null;
    }

    const refreshToken = parsed.refreshToken;
    const session = parsed.session;
    if (typeof refreshToken !== "string" || !isBackendSessionSnapshot(session)) {
      return null;
    }

    return {
      refreshToken,
      session,
    };
  } catch {
    return null;
  }
}

async function fetchSessionSnapshot(refreshToken: string) {
  const response = await apiRequest(env.authSessionPath, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      refresh_token: refreshToken,
    }),
  });

  return response;
}

async function fetchRefreshSession(refreshToken: string) {
  const response = await apiRequest(env.authRefreshPath, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      refresh_token: refreshToken,
    }),
  });

  return response;
}

/**
 * Thin auth boundary for web auth shell.
 *
 * Backend contract now supports:
 * - POST /auth/login => issue refresh token + session continuity metadata
 * - POST /auth/session => validate persisted refresh token for shell restore
 */
export async function loginWithEmailPassword(
  input: AuthLoginInput,
): Promise<AuthLoginResult> {
  const email = normalizeEmail(input.email);

  void input.password;

  try {
    const response = await apiRequest(env.authLoginPath, {
      method: "POST",
      headers: {
        "content-type": "application/json",
      },
      body: JSON.stringify({
        email,
        platform: "web",
        device_name: "GenGate Web Shell",
      }),
    });

    if (response.ok) {
      const data: unknown = await response.json();
      if (!isBackendLoginPayload(data)) {
        return {
          ok: false,
          reason: "invalid-response",
          message: "Backend login response thiếu field theo auth/session contract hiện tại.",
        };
      }

      persistAuthSession(data);

      return {
        ok: true,
        mode: "backend",
        message:
          "Đăng nhập shell thành công và đã lưu refresh/session tối thiểu ở web client.",
        redirectTo: DEFAULT_LOGIN_REDIRECT,
        sessionStatus: "persisted",
        payload: data,
      };
    }

    if (response.status === 404 || response.status === 501) {
      return {
        ok: false,
        reason: "not-implemented",
        message:
          "Backend auth endpoint chưa implement xong. UI shell đã sẵn sàng để map vào contract sau.",
      };
    }

    return {
      ok: false,
      reason: "invalid-response",
      message: `Login request failed with status ${response.status}.`,
      details: response.statusText,
    };
  } catch (error) {
    return {
      ok: false,
      reason: "network-error",
      message: "Không thể kết nối auth endpoint từ web client.",
      details: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function registerAndLoginWithEmailPassword(
  input: AuthRegisterInput,
): Promise<AuthLoginResult> {
  const email = normalizeEmail(input.email);
  const username = input.username?.trim() || email.split("@")[0] || "gengate_user";

  void input.password;

  try {
    const registerResponse = await registerWithEmail(email, username);
    if (!registerResponse.ok) {
      if (registerResponse.status === 409) {
        return {
          ok: false,
          reason: "conflict",
          message: "Email này đã tồn tại. Hãy đăng nhập bằng session shell hiện có.",
        };
      }

      if (registerResponse.status === 404 || registerResponse.status === 501) {
        return {
          ok: false,
          reason: "not-implemented",
          message: "Backend register endpoint chưa implement xong theo auth shell contract hiện tại.",
        };
      }

      return {
        ok: false,
        reason: "invalid-response",
        message: `Register request failed with status ${registerResponse.status}.`,
        details: registerResponse.statusText,
      };
    }

    return await loginWithEmailPassword({ email, password: input.password });
  } catch (error) {
    return {
      ok: false,
      reason: "network-error",
      message: "Không thể kết nối register endpoint từ web client.",
      details: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function restorePersistedSession(): Promise<RestoreSessionResult> {
  const stored = readPersistedAuthSession();
  if (!stored) {
    return {
      ok: false,
      reason: "missing",
      message: "Chưa có session local để restore.",
    };
  }

  try {
    const response = await fetchSessionSnapshot(stored.refreshToken);
    if (response.ok) {
      const data: unknown = await response.json();
      if (!isBackendSessionSnapshot(data)) {
        clearPersistedAuthSession();
        return {
          ok: false,
          reason: "invalid-response",
          message: "Backend session snapshot response thiếu field cần thiết.",
        };
      }

      const nextSession: StoredAuthSession = {
        refreshToken: stored.refreshToken,
        session: data,
      };
      if (canUseBrowserStorage()) {
        window.localStorage.setItem(AUTH_SESSION_STORAGE_KEY, JSON.stringify(nextSession));
      }
      return {
        ok: true,
        session: nextSession,
        source: "storage",
      };
    }

    if (response.status === 401) {
      const backendDetail = await readErrorDetail(response);
      clearPersistedAuthSession();
      const suffix = backendDetail ? ` (${backendDetail})` : "";
      return {
        ok: false,
        reason: "unauthorized",
        message: `Refresh token cũ không còn hợp lệ${suffix}; đã xóa session local.`,
        backendDetail,
      };
    }

    return {
      ok: false,
      reason: "invalid-response",
      message: `Session restore failed with status ${response.status}.`,
    };
  } catch {
    return {
      ok: false,
      reason: "network-error",
      message: "Không thể kiểm tra session đã lưu với backend.",
    };
  }
}

export async function refreshPersistedSession(): Promise<RestoreSessionResult> {
  const stored = readPersistedAuthSession();
  if (!stored) {
    return {
      ok: false,
      reason: "missing",
      message: "Chưa có session local để refresh.",
    };
  }

  try {
    const response = await fetchRefreshSession(stored.refreshToken);
    if (response.ok) {
      const data: unknown = await response.json();
      if (!isBackendLoginPayload(data)) {
        clearPersistedAuthSession();
        return {
          ok: false,
          reason: "invalid-response",
          message: "Backend refresh response thiếu field theo auth/session contract hiện tại.",
        };
      }

      const nextSession = persistAuthSession(data);
      if (!nextSession) {
        return {
          ok: false,
          reason: "invalid-response",
          message: "Không thể lưu rotated refresh/session state vào local storage.",
        };
      }

      return {
        ok: true,
        session: nextSession,
        source: "storage",
      };
    }

    if (response.status === 401) {
      const backendDetail = await readErrorDetail(response);
      clearPersistedAuthSession();
      const suffix = backendDetail ? ` (${backendDetail})` : "";
      return {
        ok: false,
        reason: "unauthorized",
        message: `Manual refresh cho thấy refresh token cũ không còn hợp lệ${suffix}; đã xóa session local.`,
        backendDetail,
      };
    }

    return {
      ok: false,
      reason: "invalid-response",
      message: `Session refresh failed with status ${response.status}.`,
    };
  } catch {
    return {
      ok: false,
      reason: "network-error",
      message: "Không thể refresh session đã lưu với backend.",
    };
  }
}

export function getLoginRedirectPath() {
  return DEFAULT_LOGIN_REDIRECT;
}
