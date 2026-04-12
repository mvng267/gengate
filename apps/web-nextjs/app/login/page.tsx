"use client";

import { useMemo, useState } from "react";

import { getLoginRedirectPath, loginWithEmailPassword } from "@/lib/auth/client";

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

export default function LoginPage() {
  const [form, setForm] = useState(initialForm);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [statusTone, setStatusTone] = useState<"neutral" | "success" | "error">("neutral");
  const [sessionPreview, setSessionPreview] = useState<string | null>(null);

  const loginCta = useMemo(() => {
    return isSubmitting ? "Đang thử đăng nhập..." : "Thử login shell";
  }, [isSubmitting]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setStatusMessage(null);
    setSessionPreview(null);

    const result = await loginWithEmailPassword(form);
    if (result.ok) {
      setStatusTone("success");
      setStatusMessage(
        `${result.message} Điều hướng đích dự kiến: ${
          result.redirectTo ?? getLoginRedirectPath()
        }`,
      );
      setSessionPreview(
        [
          `user_id: ${result.payload.user_id}`,
          `session_id: ${result.payload.session_id}`,
          `device_id: ${result.payload.device_id}`,
          `token_type: ${result.payload.token_type}`,
          `bootstrap_mode: ${result.payload.bootstrap_mode}`,
        ].join("\n"),
      );
    } else {
      setStatusTone("error");
      setStatusMessage(result.message);
      setSessionPreview(null);
    }

    setIsSubmitting(false);
  }

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-5xl flex-col gap-10 px-6 py-12 lg:flex-row lg:items-start">
      <section className="flex-1 space-y-4">
        <span className="inline-flex rounded-full border border-black px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em]">
          Batch 30 · Web auth shell
        </span>
        <h1 className="text-4xl font-black tracking-tight text-black">
          Login shell đã nối vào backend auth/session shell.
        </h1>
        <p className="max-w-2xl text-base leading-7 text-neutral-700">
          Màn này giữ đúng contract backend hiện tại: gửi <code>email</code> + <code>platform</code> + <code>device_name</code>,
          nhận về payload session shell để bám vertical slice.
        </p>
        <ul className="space-y-2 text-sm text-neutral-700">
          <li>• Password/OTP vẫn là placeholder trên UI, chưa dùng cho API ở batch này.</li>
          <li>
            • Path login mặc định là <code>/auth/login</code>, có thể override bằng <code>NEXT_PUBLIC_AUTH_LOGIN_PATH</code>.
          </li>
          <li>• Sau khi login OK, hướng điều hướng mặc định là <code>/feed</code>.</li>
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
            disabled={isSubmitting}
            className="w-full border-2 border-black bg-black px-4 py-3 text-sm font-bold uppercase tracking-[0.2em] text-white transition hover:-translate-y-0.5 hover:shadow-[6px_6px_0_#facc15] disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loginCta}
          </button>
        </form>

        <div className="mt-5 border-2 border-dashed border-black p-4 text-sm leading-6">
          <div className="font-semibold">Status</div>
          <p className={buildStatusClass(statusTone)}>
            {statusMessage ?? "Chưa submit. UI shell này dùng để verify wiring và chờ batch session persistence tiếp theo."}
          </p>

          {sessionPreview ? (
            <pre className="mt-3 overflow-x-auto border border-black bg-neutral-100 p-3 text-xs text-black">
              {sessionPreview}
            </pre>
          ) : null}
        </div>
      </section>
    </main>
  );
}
