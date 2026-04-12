const DEFAULT_API_BASE_URL = "http://localhost:8000";
const DEFAULT_AUTH_LOGIN_PATH = "/auth/login";

function readOptionalEnv(value: string | undefined) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

export const env = {
  apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL ?? DEFAULT_API_BASE_URL,
  authLoginPath:
    readOptionalEnv(process.env.NEXT_PUBLIC_AUTH_LOGIN_PATH) ?? DEFAULT_AUTH_LOGIN_PATH,
};
