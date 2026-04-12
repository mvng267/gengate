"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { useEffect, useState } from "react";

import { readPersistedAuthSession, restorePersistedSession } from "@/lib/auth/client";

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
        setSessionLabel(result.session.session.email);
        setSessionMeta(
          `${result.session.session.session_status} · expires in ${result.session.session.expires_in_seconds}s`,
        );
      } else {
        setSessionLabel("Guest");
        setSessionMeta("Persisted session unavailable");
      }
    }

    void syncSessionLabel();

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <>
      <header>
        <strong>GenGate • Web</strong>
        <div>Session: {sessionLabel}</div>
        <div>Status: {sessionMeta}</div>
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
