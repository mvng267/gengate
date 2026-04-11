import { env } from "@/lib/config/env";

type HttpMethod = "GET" | "POST" | "PATCH" | "PUT" | "DELETE";

type ApiRequestOptions = {
  method?: HttpMethod;
  headers?: HeadersInit;
  body?: BodyInit | null;
};

/**
 * Foundation-only helper for wiring upcoming API calls.
 * TODO(web): Add auth/session headers and standardized error mapping.
 */
export async function apiRequest(path: string, options: ApiRequestOptions = {}) {
  const response = await fetch(`${env.apiBaseUrl}${path}`, {
    method: options.method ?? "GET",
    headers: options.headers,
    body: options.body,
    cache: "no-store",
  });

  return response;
}
