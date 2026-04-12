const DEFAULT_API_BASE_URL = "http://localhost:8000";
const DEFAULT_AUTH_LOGIN_PATH = "/auth/login";
const DEFAULT_AUTH_REFRESH_PATH = "/auth/refresh";
const DEFAULT_AUTH_SESSION_PATH = "/auth/session";
const DEFAULT_AUTH_LOGOUT_PATH = "/auth/logout";

function readOptionalEnv(value: string | undefined) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

export const env = {
  apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL ?? DEFAULT_API_BASE_URL,
  authLoginPath:
    readOptionalEnv(process.env.NEXT_PUBLIC_AUTH_LOGIN_PATH) ?? DEFAULT_AUTH_LOGIN_PATH,
  authRefreshPath:
    readOptionalEnv(process.env.NEXT_PUBLIC_AUTH_REFRESH_PATH) ?? DEFAULT_AUTH_REFRESH_PATH,
  authSessionPath:
    readOptionalEnv(process.env.NEXT_PUBLIC_AUTH_SESSION_PATH) ?? DEFAULT_AUTH_SESSION_PATH,
  authLogoutPath:
    readOptionalEnv(process.env.NEXT_PUBLIC_AUTH_LOGOUT_PATH) ?? DEFAULT_AUTH_LOGOUT_PATH,
};
