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

  const profileHref = userId ? `/profile?user=${encodeURIComponent(userId)}` : "/profile";
  const feedHref = userId ? `/feed?author=${encodeURIComponent(userId)}&viewer=${encodeURIComponent(userId)}` : "/feed";
  const inboxHref = userId ? `/inbox?userA=${encodeURIComponent(userId)}&sender=${encodeURIComponent(userId)}` : "/inbox";
  const locationHref = userId ? `/location?owner=${encodeURIComponent(userId)}` : "/location";

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
            Suggested pivots after validating notifications: <Link href={profileHref}>Profile</Link> · <Link href={feedHref}>Feed</Link> ·{" "}
            <Link href={inboxHref}>Inbox</Link> · <Link href={locationHref}>Location</Link>
          </p>
          <p>
            Tip: these pivots now carry the current notifications user forward, so you can keep cross-seam testing without retyping the same UUID.
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
