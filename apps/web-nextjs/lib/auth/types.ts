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
  token_type: string;
  bootstrap_mode: string;
};

export type AuthLoginResult =
  | {
      ok: true;
      mode: "backend";
      message: string;
      redirectTo?: string;
      sessionStatus: "pending-contract";
      payload: BackendLoginPayload;
    }
  | {
      ok: false;
      reason: "not-implemented" | "network-error" | "invalid-response";
      message: string;
      details?: string;
    };
