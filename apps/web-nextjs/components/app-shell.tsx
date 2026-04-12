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

  useEffect(() => {
    let isMounted = true;

    async function syncSessionLabel() {
      const localSession = readPersistedAuthSession();
      if (!localSession) {
        if (isMounted) {
          setSessionLabel("Guest");
        }
        return;
      }

      const result = await restorePersistedSession();
      if (!isMounted) {
        return;
      }

      if (result.ok) {
        setSessionLabel(result.session.session.email);
      } else {
        setSessionLabel("Guest");
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
