"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import {
  logoutPersistedSession,
  readPersistedAuthSession,
  restorePersistedSession,
} from "@/lib/auth/client";

type AuthenticatedRouteShellProps = {
  title: string;
  summary: string;
};

type RestoreState =
  | { status: "checking" }
  | { status: "signed-out"; message: string }
  | {
      status: "authenticated";
      message: string;
      email: string;
      sessionId: string;
      sessionStatus: string;
    };

export function AuthenticatedRouteShell({
  title,
  summary,
}: AuthenticatedRouteShellProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [restoreState, setRestoreState] = useState<RestoreState>({ status: "checking" });

  useEffect(() => {
    let isMounted = true;

    async function checkSession() {
      const localSession = readPersistedAuthSession();
      if (!localSession) {
        if (isMounted) {
          setRestoreState({
            status: "signed-out",
            message: "Chưa có persisted session. Đang chuyển sang login để mở route này.",
          });
          router.replace(`/login?next=${encodeURIComponent(pathname || "/feed")}`);
        }
        return;
      }

      const result = await restorePersistedSession();
      if (!isMounted) {
        return;
      }

      if (result.ok) {
        setRestoreState({
          status: "authenticated",
          message: "Persisted session hợp lệ. Route shell đã được mở bằng auth contract hiện tại.",
          email: result.session.session.email,
          sessionId: result.session.session.session_id,
          sessionStatus: result.session.session.session_status,
        });
        return;
      }

      setRestoreState({
        status: "signed-out",
        message: `${result.message} Đang chuyển sang login để xác thực lại.`,
      });
      router.replace(`/login?next=${encodeURIComponent(pathname || "/feed")}`);
    }

    void checkSession();

    return () => {
      isMounted = false;
    };
  }, [pathname, router]);

  if (restoreState.status === "checking") {
    return (
      <section>
        <h1>{title}</h1>
        <p>Đang kiểm tra persisted session với backend auth shell...</p>
      </section>
    );
  }

  if (restoreState.status === "signed-out") {
    return (
      <section>
        <h1>{title}</h1>
        <p>{summary}</p>
        <p>
          <strong>Access:</strong> locked bởi vì chưa có persisted session hợp lệ.
        </p>
        <p>{restoreState.message}</p>
      </section>
    );
  }

  return (
    <section>
      <h1>{title}</h1>
      <p>{summary}</p>
      <p>
        <strong>Status:</strong> route shell đã mở bằng persisted session tối thiểu.
      </p>
      <p>
        <strong>Signed in:</strong> {restoreState.email}
      </p>
      <p>
        <strong>Session:</strong> {restoreState.sessionId} ({restoreState.sessionStatus})
      </p>
      <button
        type="button"
        onClick={() => {
          void logoutPersistedSession().then((result) => {
            setRestoreState({
              status: "signed-out",
              message: `${result.message} Đang quay lại login.`,
            });
            router.replace(`/login?next=${encodeURIComponent(pathname || "/feed")}`);
          });
        }}
      >
        Logout + clear persisted session
      </button>
    </section>
  );
}
