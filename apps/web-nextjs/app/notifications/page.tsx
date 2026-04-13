import Link from "next/link";

import { NotificationShell } from "@/components/notification-shell";

type NotificationsPageProps = {
  searchParams?: Promise<{
    user?: string;
  }>;
};

export default async function NotificationsPage({ searchParams }: NotificationsPageProps) {
  const params = searchParams ? await searchParams : undefined;
  const userId = params?.user?.trim() ?? "";

  return (
    <section>
      <h1>Notifications</h1>
      <p>Minimal notification shell is now wired for MVP testing.</p>
      <p>Use the launcher form below to prefill the user UUID before loading, creating, or toggling notifications.</p>

      <form method="GET" action="/notifications" style={{ display: "grid", gap: 12, maxWidth: 720, marginBottom: 20 }}>
        <label htmlFor="notifications-user-id">
          User UUID
          <input
            id="notifications-user-id"
            name="user"
            type="text"
            defaultValue={userId}
            placeholder="Paste user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <button type="submit" style={{ width: "fit-content", padding: "10px 14px" }}>
          Prefill notifications shell
        </button>
      </form>

      {userId ? (
        <>
          <p>
            Active notifications user: <code>{userId}</code>
          </p>
          <p>
            Suggested pivots after validating notifications: <Link href="/profile">Profile</Link> · <Link href="/feed">Feed</Link> ·{" "}
            <Link href="/inbox">Inbox</Link> · <Link href="/location">Location</Link>
          </p>
        </>
      ) : (
        <p>
          Provide one registered user UUID here before using the shell below, instead of manually retyping it for every notification test pass.
        </p>
      )}

      <NotificationShell initialUserId={userId} />
    </section>
  );
}
