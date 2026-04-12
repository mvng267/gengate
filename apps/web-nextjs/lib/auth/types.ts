export type AuthLoginInput = {
  email: string;
  password: string;
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
};

export type StoredAuthSession = {
  refreshToken: string;
  session: BackendSessionSnapshot;
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
      reason: "not-implemented" | "network-error" | "invalid-response";
      message: string;
      details?: string;
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
    };
