import Link from "next/link";

import { FriendGraphShell } from "@/components/friend-graph-shell";

type ProfilePageProps = {
  searchParams?: Promise<{
    user?: string;
  }>;
};

export default async function ProfilePage({ searchParams }: ProfilePageProps) {
  const params = searchParams ? await searchParams : undefined;
  const selectedUserId = params?.user?.trim() ?? "";
  const feedHref = selectedUserId ? `/feed?author=${encodeURIComponent(selectedUserId)}&viewer=${encodeURIComponent(selectedUserId)}` : "/feed";
  const inboxHref = selectedUserId ? `/inbox?userA=${encodeURIComponent(selectedUserId)}&sender=${encodeURIComponent(selectedUserId)}` : "/inbox";
  const notificationsHref = selectedUserId ? `/notifications?user=${encodeURIComponent(selectedUserId)}` : "/notifications";
  const locationHref = selectedUserId ? `/location?owner=${encodeURIComponent(selectedUserId)}` : "/location";

  return (
    <section>
      <h1>Profile</h1>
      <p>Friend graph shell is the best launcher for inspecting one user context, then pivoting into nearby MVP seams.</p>
      <p>
        Use the launcher form below or paste a registered user UUID into the URL as <code>?user=&lt;uuid&gt;</code>.
      </p>

      <form method="GET" action="/profile" style={{ display: "grid", gap: 12, maxWidth: 720, marginBottom: 20 }}>
        <label htmlFor="profile-user-id">
          Profile user UUID
          <input
            id="profile-user-id"
            name="user"
            type="text"
            defaultValue={selectedUserId}
            placeholder="Paste registered user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <button type="submit" style={{ width: "fit-content", padding: "10px 14px" }}>
          Load friend graph shell
        </button>
      </form>

      {selectedUserId ? (
        <>
          <p>
            Active profile user: <code>{selectedUserId}</code>
          </p>
          <p>
            Quick pivots for the same browser test session: <Link href={feedHref}>Feed</Link> · <Link href={inboxHref}>Inbox</Link> ·{" "}
            <Link href={notificationsHref}>Notifications</Link> · <Link href={locationHref}>Location</Link>
          </p>
          <p>
            Tip: these pivots now carry the active profile UUID into nearby launcher pages, so you only need to fill the second user when a seam truly requires it.
          </p>
          <FriendGraphShell userId={selectedUserId} />
        </>
      ) : (
        <>
          <p>
            Provide a registered user UUID to inspect the friend graph shell and unlock related quick pivots.
          </p>
          <ul>
            <li>
              Start from <Link href="/login">Login</Link> if you still need to create or restore a test session.
            </li>
            <li>
              Then load one user context here before pivoting into <Link href="/feed">Feed</Link>, <Link href="/inbox">Inbox</Link>,{" "}
              <Link href="/notifications">Notifications</Link>, and <Link href="/location">Location</Link>.
            </li>
          </ul>
        </>
      )}
    </section>
  );
}
