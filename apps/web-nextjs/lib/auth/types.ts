export type AuthLoginInput = {
  email: string;
  password: string;
};

export type AuthRegisterInput = {
  email: string;
  password: string;
  username?: string;
};

export type BackendLoginPayload = {
  user_id: string;
  email: string;
  device_id: string;
  session_id: string;
  refresh_token: string;
  expires_at: string;
  expires_in_seconds: number;
  token_type: string;
  bootstrap_mode: string;
  session_status: string;
  local_clear_recommended: boolean;
  backend_detail: string | null;
};

export type BackendSessionSnapshot = {
  user_id: string;
  email: string;
  device_id: string;
  session_id: string;
  expires_at: string;
  expires_in_seconds: number;
  token_type: string;
  session_status: string;
  local_clear_recommended: boolean;
  backend_detail: string | null;
};

export type StoredAuthSession = {
  refreshToken: string;
  session: BackendSessionSnapshot;
  friendGraphPeerUserId?: string;
};

export type AuthLoginResult =
  | {
      ok: true;
      mode: "backend";
      message: string;
      redirectTo?: string;
      sessionStatus: "persisted";
      payload: BackendLoginPayload;
    }
  | {
      ok: false;
      reason:
        | "not-implemented"
        | "network-error"
        | "invalid-response"
        | "conflict"
        | "unauthorized"
        | "not-found";
      message: string;
      details?: string;
      backendDetail?: string;
      localClearRecommended?: boolean;
    };

export type RestoreSessionResult =
  | {
      ok: true;
      session: StoredAuthSession;
      source: "storage";
    }
  | {
      ok: false;
      reason: "missing" | "unauthorized" | "network-error" | "invalid-response";
      message: string;
      backendDetail?: string;
      localClearRecommended?: boolean;
    };
