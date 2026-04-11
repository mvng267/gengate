import Link from "next/link";
import type { ReactNode } from "react";

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
  return (
    <>
      <header>
        <strong>GenGate • Web</strong>
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
