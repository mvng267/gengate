"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useMemo, useState } from "react";

import {
  clearPersistedAuthSession,
  getLoginRedirectPath,
  loginWithEmailPassword,
  logoutPersistedSession,
  readPersistedAuthSession,
  refreshPersistedSession,
  registerAndLoginWithEmailPassword,
  restorePersistedSession,
} from "@/lib/auth/client";

const initialForm = {
  email: "",
  password: "",
};

function buildStatusClass(tone: "neutral" | "success" | "error") {
  if (tone === "error") {
    return "text-red-700";
  }

  if (tone === "success") {
    return "text-green-700";
  }

  return "text-neutral-700";
}

function formatStoredSessionPreview() {
  const stored = readPersistedAuthSession();
  if (!stored) {
    return null;
  }

  return [
    `refresh_token: ${stored.refreshToken}`,
    `user_id: ${stored.session.user_id}`,
    `email: ${stored.session.email}`,
    `session_id: ${stored.session.session_id}`,
    `device_id: ${stored.session.device_id}`,
    `token_type: ${stored.session.token_type}`,
    `session_status: ${stored.session.session_status}`,
    `expires_in_seconds: ${stored.session.expires_in_seconds}`,
  ].join("\n");
}

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [form, setForm] = useState(initialForm);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isRestoring, setIsRestoring] = useState(true);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [statusTone, setStatusTone] = useState<"neutral" | "success" | "error">("neutral");
  const [sessionPreview, setSessionPreview] = useState<string | null>(null);
  const [storedSessionPreview, setStoredSessionPreview] = useState<string | null>(null);
  const [logoutOutcomePreview, setLogoutOutcomePreview] = useState<string | null>(null);

  const nextPath = useMemo(() => {
    const value = searchParams.get("next");
    if (!value || !value.startsWith("/")) {
      return getLoginRedirectPath();
    }

    return value;
  }, [searchParams]);

  const loginCta = useMemo(() => {
    if (isSubmitting) {
      return "Đang thử đăng nhập...";
    }

    return "Đăng nhập + lưu session";
  }, [isSubmitting]);

  useEffect(() => {
    let isMounted = true;

    async function restore() {
      const localSession = readPersistedAuthSession();
      if (isMounted) {
        setStoredSessionPreview(formatStoredSessionPreview());
      }
      if (!localSession) {
        if (isMounted) {
          setIsRestoring(false);
        }
        return;
      }

      const result = await restorePersistedSession();
      if (!isMounted) {
        return;
      }

      if (result.ok) {
        setStatusTone("success");
        setStatusMessage(
          `Đã restore session local hợp lệ cho ${result.session.session.email}. Đang chuyển tới ${nextPath}`,
        );
        setSessionPreview(
          [
            `user_id: ${result.session.session.user_id}`,
            `session_id: ${result.session.session.session_id}`,
            `device_id: ${result.session.session.device_id}`,
            `token_type: ${result.session.session.token_type}`,
            `session_status: ${result.session.session.session_status}`,
            `expires_in_seconds: ${result.session.session.expires_in_seconds}`,
          ].join("\n"),
        );
        setStoredSessionPreview(formatStoredSessionPreview());
        setIsRestoring(false);
        router.replace(nextPath);
        return;
      }

      if (result.reason !== "missing") {
        setStatusTone(result.reason === "unauthorized" ? "neutral" : "error");
        setStatusMessage(
          result.reason === "unauthorized"
            ? `${result.message} Hãy đăng nhập lại để tạo session mới.`
            : result.message,
        );
        setSessionPreview(null);
        setStoredSessionPreview(formatStoredSessionPreview());
      }

      setIsRestoring(false);
    }

    void restore();

    return () => {
      isMounted = false;
    };
  }, [nextPath, router]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setStatusMessage(null);
    setSessionPreview(null);
    setLogoutOutcomePreview(null);

    const result = await loginWithEmailPassword(form);
    if (result.ok) {
      setStatusTone("success");
      setStatusMessage(`${result.message} Đang chuyển tới ${nextPath}`);
      setSessionPreview(
        [
          `user_id: ${result.payload.user_id}`,
          `session_id: ${result.payload.session_id}`,
          `device_id: ${result.payload.device_id}`,
          `token_type: ${result.payload.token_type}`,
          `bootstrap_mode: ${result.payload.bootstrap_mode}`,
          `session_status: ${result.payload.session_status}`,
          `expires_in_seconds: ${result.payload.expires_in_seconds}`,
        ].join("\n"),
      );
      setStoredSessionPreview(formatStoredSessionPreview());
    } else {
      setStatusTone("error");
      setStatusMessage(result.message);
      setSessionPreview(null);
      setStoredSessionPreview(formatStoredSessionPreview());
    }

    setIsSubmitting(false);

    if (result.ok) {
      router.replace(nextPath);
    }
  }

  async function handleLogout() {
    setIsLoggingOut(true);
    setLogoutOutcomePreview(null);
    const result = await logoutPersistedSession();
    setStatusTone(result.ok ? "neutral" : "error");
    setStatusMessage(
      result.ok
        ? `${result.message} Bạn có thể đăng nhập lại bất cứ lúc nào.`
        : result.message,
    );
    setLogoutOutcomePreview(
      [
        `logout_result: ${result.ok ? "local_cleared" : "request_failed_local_cleared"}`,
        `backend_detail: ${result.backendDetail ?? "none"}`,
        `message: ${result.message}`,
      ].join("\n"),
    );
    setSessionPreview(null);
    setStoredSessionPreview(formatStoredSessionPreview());
    setIsLoggingOut(false);
  }

  function handleClearSession() {
    clearPersistedAuthSession();
    setStatusTone("neutral");
    setStatusMessage("Đã xóa session local đã lưu trên web shell.");
    setLogoutOutcomePreview(null);
    setSessionPreview(null);
    setStoredSessionPreview(formatStoredSessionPreview());
  }

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-5xl flex-col gap-10 px-6 py-12 lg:flex-row lg:items-start">
      <section className="flex-1 space-y-4">
        <span className="inline-flex rounded-full border border-black px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em]">
          Batch 42 · Web logout outcome signal
        </span>
        <h1 className="text-4xl font-black tracking-tight text-black">
          Web shell nay có thêm logout outcome signal rõ hơn để phân biệt revoke thành công với session đã mất hiệu lực.
        </h1>
        <p className="max-w-2xl text-base leading-7 text-neutral-700">
          Batch 42 ưu tiên thêm 1 action outcome surface hẹp: khi logout, màn web hiển thị riêng kết quả local clear và backend detail để auth loop dễ verify hơn.
        </p>
        <ul className="space-y-2 text-sm text-neutral-700">
          <li>• Password/OTP vẫn là placeholder trên UI, chưa dùng cho API ở batch này.</li>
          <li>• Web shell nay có persisted-session inspector và thêm logout outcome panel để nhìn rõ backend detail sau revoke.</li>
          <li>• Redirect đích mặc định vẫn là <code>/feed</code> nếu không có <code>?next=...</code> hợp lệ.</li>
        </ul>
      </section>

      <section className="w-full max-w-xl border-4 border-black bg-white p-6 shadow-[10px_10px_0_#000]">
        <form className="space-y-5" onSubmit={handleSubmit}>
          <div className="space-y-2">
            <label className="text-sm font-bold text-black" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={form.email}
              onChange={(event) => setForm((current) => ({ ...current, email: event.target.value }))}
              className="w-full border-2 border-black px-4 py-3 outline-none focus:bg-yellow-100"
              placeholder="you@example.com"
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-bold text-black" htmlFor="password">
              Password / OTP placeholder
            </label>
            <input
              id="password"
              type="password"
              required
              value={form.password}
              onChange={(event) => setForm((current) => ({ ...current, password: event.target.value }))}
              className="w-full border-2 border-black px-4 py-3 outline-none focus:bg-yellow-100"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting || isRegistering || isRestoring || isLoggingOut || isRefreshing}
            className="w-full border-2 border-black bg-black px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-white transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#facc15] disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isRestoring ? "Đang restore session..." : loginCta}
          </button>
        </form>

        <button
          type="button"
          onClick={() => {
            void (async () => {
              setIsRegistering(true);
              setStatusMessage(null);
              setSessionPreview(null);
              setLogoutOutcomePreview(null);

              const result = await registerAndLoginWithEmailPassword(form);
              if (result.ok) {
                setStatusTone("success");
                setStatusMessage(`Tạo account shell + đăng nhập thành công. Đang chuyển tới ${nextPath}`);
                setSessionPreview(
                  [
                    `user_id: ${result.payload.user_id}`,
                    `session_id: ${result.payload.session_id}`,
                    `device_id: ${result.payload.device_id}`,
                    `token_type: ${result.payload.token_type}`,
                    `bootstrap_mode: ${result.payload.bootstrap_mode}`,
                    `session_status: ${result.payload.session_status}`,
                    `expires_in_seconds: ${result.payload.expires_in_seconds}`,
                  ].join("\n"),
                );
                setStoredSessionPreview(formatStoredSessionPreview());
                setIsRegistering(false);
                router.replace(nextPath);
                return;
              }

              setStatusTone(result.reason === "conflict" ? "neutral" : "error");
              setStatusMessage(result.message);
              setStoredSessionPreview(formatStoredSessionPreview());
              setIsRegistering(false);
            })();
          }}
          disabled={isSubmitting || isRegistering || isRestoring || isLoggingOut || isRefreshing}
          className="mt-3 w-full border-2 border-black bg-yellow-300 px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-black transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#000] disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isRegistering ? "Đang tạo account..." : "Tạo account + đăng nhập"}
        </button>

        <button
          type="button"
          onClick={() => {
            void (async () => {
              setIsRefreshing(true);
              setStatusMessage(null);
              setSessionPreview(null);
              setLogoutOutcomePreview(null);

              const result = await refreshPersistedSession();
              if (result.ok) {
                setStatusTone("success");
                setStatusMessage("Đã manual refresh session với backend và rotate refresh token local.");
                setSessionPreview(
                  [
                    `user_id: ${result.session.session.user_id}`,
                    `session_id: ${result.session.session.session_id}`,
                    `device_id: ${result.session.session.device_id}`,
                    `token_type: ${result.session.session.token_type}`,
                    `session_status: ${result.session.session.session_status}`,
                    `expires_in_seconds: ${result.session.session.expires_in_seconds}`,
                  ].join("\n"),
                );
                setStoredSessionPreview(formatStoredSessionPreview());
              } else {
                setStatusTone(result.reason === "unauthorized" ? "neutral" : "error");
                setStatusMessage(
                  result.reason === "unauthorized"
                    ? `${result.message} Hãy đăng nhập lại để tạo session mới.`
                    : result.message,
                );
                setSessionPreview(null);
                setStoredSessionPreview(formatStoredSessionPreview());
              }

              setIsRefreshing(false);
            })();
          }}
          disabled={isSubmitting || isRegistering || isRestoring || isLoggingOut || isRefreshing}
          className="mt-3 w-full border-2 border-black bg-white px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-black transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#d4d4d4] disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isRefreshing ? "Đang refresh session..." : "Refresh persisted session"}
        </button>

        <button
          type="button"
          onClick={() => {
            void handleLogout();
          }}
          disabled={isSubmitting || isRegistering || isRestoring || isLoggingOut || isRefreshing}
          className="mt-3 w-full border-2 border-black bg-white px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-black transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#d4d4d4] disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isLoggingOut ? "Đang logout..." : "Logout + revoke session"}
        </button>

        <button
          type="button"
          onClick={handleClearSession}
          className="mt-3 w-full border-2 border-black bg-white px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-black transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#d4d4d4]"
        >
          Xóa session local
        </button>

        <div className="mt-5 border-2 border-dashed border-black p-4 text-sm leading-6">
          <div className="font-semibold">Status</div>
          <p className={buildStatusClass(statusTone)}>
            {statusMessage ??
              "Chưa submit. Batch 42 shell này ưu tiên giúp auth E2E flow hiện rõ logout outcome thật bên cạnh persisted-session state."}
          </p>

          {statusMessage?.includes("đăng nhập lại") ? (
            <p className="mt-2 text-xs text-neutral-600">
              Persisted session cũ đã bị loại bỏ khỏi local storage để tránh restore lặp lại sai state.
            </p>
          ) : null}

          {sessionPreview ? (
            <pre className="mt-3 overflow-x-auto border border-black bg-neutral-100 p-3 text-xs text-black">
              {sessionPreview}
            </pre>
          ) : null}

          <div className="mt-3">
            <div className="font-semibold">Logout outcome</div>
            {logoutOutcomePreview ? (
              <pre className="mt-2 overflow-x-auto border border-black bg-neutral-100 p-3 text-xs text-black">
                {logoutOutcomePreview}
              </pre>
            ) : (
              <p className="mt-2 text-xs text-neutral-600">
                Chưa có logout attempt nào trong phiên shell hiện tại.
              </p>
            )}
          </div>

          <div className="mt-3">
            <div className="font-semibold">Persisted session snapshot</div>
            {storedSessionPreview ? (
              <pre className="mt-2 overflow-x-auto border border-black bg-neutral-100 p-3 text-xs text-black">
                {storedSessionPreview}
              </pre>
            ) : (
              <p className="mt-2 text-xs text-neutral-600">Chưa có persisted session trong local storage.</p>
            )}
          </div>
        </div>
      </section>
    </main>
  );
}
