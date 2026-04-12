import { apiRequest } from "@/lib/api/client";
import { env } from "@/lib/config/env";

import type { AuthLoginInput, AuthLoginResult, BackendLoginPayload } from "./types";

const DEFAULT_LOGIN_REDIRECT = "/feed";

function normalizeEmail(value: string) {
  return value.trim().toLowerCase();
}

function isBackendLoginPayload(value: unknown): value is BackendLoginPayload {
  if (!value || typeof value !== "object") {
    return false;
  }

  const payload = value as Partial<BackendLoginPayload>;
  return (
    typeof payload.user_id === "string" &&
    typeof payload.email === "string" &&
    typeof payload.device_id === "string" &&
    typeof payload.session_id === "string" &&
    typeof payload.refresh_token === "string" &&
    typeof payload.expires_at === "string" &&
    typeof payload.token_type === "string" &&
    typeof payload.bootstrap_mode === "string"
  );
}

/**
 * Thin auth boundary for batch 30 web shell.
 *
 * Backend contract currently expects: email + platform + device_name.
 * Password is still captured in UI shell but intentionally not sent yet.
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
          message: "Backend login response thiếu field theo auth shell contract hiện tại.",
        };
      }

      return {
        ok: true,
        mode: "backend",
        message:
          "Đăng nhập shell thành công theo contract backend hiện tại. Session persistence thật sẽ nối ở batch sau.",
        redirectTo: DEFAULT_LOGIN_REDIRECT,
        sessionStatus: "pending-contract",
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

export function getLoginRedirectPath() {
  return DEFAULT_LOGIN_REDIRECT;
}
