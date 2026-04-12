"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { useEffect, useState } from "react";

import {
  readPersistedAuthSession,
  refreshPersistedSession,
  restorePersistedSession,
} from "@/lib/auth/client";

type AppShellProps = {
  children: ReactNode;
};

const navItems = [
  { href: "/login", label: "Login" },
  { href: "/feed", label: "Feed" },
  { href: "/inbox", label: "Inbox" },
  { href: "/location", label: "Location" },
  { href: "/profile", label: "Profile" },
];

export function AppShell({ children }: AppShellProps) {
  const [sessionLabel, setSessionLabel] = useState("Guest");
  const [sessionMeta, setSessionMeta] = useState<string>("No active persisted session");
  const [isRefreshing, setIsRefreshing] = useState(false);

  function applySignedOutState(message = "Persisted session unavailable") {
    setSessionLabel("Guest");
    setSessionMeta(message);
  }

  function applyRestoredState(email: string, sessionStatus: string, expiresInSeconds: number) {
    setSessionLabel(email);
    setSessionMeta(`${sessionStatus} · expires in ${expiresInSeconds}s`);
  }

  useEffect(() => {
    let isMounted = true;

    async function syncSessionLabel() {
      const localSession = readPersistedAuthSession();
      if (!localSession) {
        if (isMounted) {
          setSessionLabel("Guest");
          setSessionMeta("No active persisted session");
        }
        return;
      }

      const result = await restorePersistedSession();
      if (!isMounted) {
        return;
      }

      if (result.ok) {
        applyRestoredState(
          result.session.session.email,
          result.session.session.session_status,
          result.session.session.expires_in_seconds,
        );
      } else {
        applySignedOutState();
      }
    }

    void syncSessionLabel();

    return () => {
      isMounted = false;
    };
  }, []);

  async function handleRefreshSession() {
    setIsRefreshing(true);
    const localSession = readPersistedAuthSession();
    if (!localSession) {
      applySignedOutState("No local session to refresh");
      setIsRefreshing(false);
      return;
    }

    const result = await refreshPersistedSession();
    if (result.ok) {
      applyRestoredState(
        result.session.session.email,
        result.session.session.session_status,
        result.session.session.expires_in_seconds,
      );
    } else {
      applySignedOutState(result.message);
    }
    setIsRefreshing(false);
  }

  return (
    <>
      <header>
        <strong>GenGate • Web</strong>
        <div>Session: {sessionLabel}</div>
        <div>Status: {sessionMeta}</div>
        <button type="button" onClick={() => void handleRefreshSession()} disabled={isRefreshing}>
          {isRefreshing ? "Refreshing session..." : "Refresh session"}
        </button>
        <nav aria-label="Primary">
          {navItems.map((item) => (
            <Link key={item.href} href={item.href}>
              {item.label}
            </Link>
          ))}
        </nav>
      </header>
      <main>{children}</main>
    </>
  );
}
