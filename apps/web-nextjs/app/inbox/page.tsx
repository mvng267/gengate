import Link from "next/link";

import { DirectMessageShell } from "@/components/direct-message-shell";

type InboxPageProps = {
  searchParams?: Promise<{
    userA?: string;
    userB?: string;
    sender?: string;
  }>;
};

export default async function InboxPage({ searchParams }: InboxPageProps) {
  const params = searchParams ? await searchParams : undefined;
  const userAId = params?.userA?.trim() ?? "";
  const userBId = params?.userB?.trim() ?? "";
  const senderUserId = params?.sender?.trim() ?? userAId;

  const profileHref = senderUserId ? `/profile?user=${encodeURIComponent(senderUserId)}` : userAId ? `/profile?user=${encodeURIComponent(userAId)}` : "/profile";
  const feedHref = userAId || userBId
    ? `/feed?author=${encodeURIComponent(senderUserId || userAId)}&viewer=${encodeURIComponent(userBId || userAId || senderUserId)}`
    : "/feed";
  const notificationsHref = senderUserId ? `/notifications?user=${encodeURIComponent(senderUserId)}` : "/notifications";
  const locationHref = senderUserId ? `/location?owner=${encodeURIComponent(senderUserId)}` : "/location";

  return (
    <section>
      <h1>Inbox</h1>
      <p>1:1 direct messaging shell is now wired for MVP testing.</p>
      <p>Use the launcher form below to prefill the two thread members before opening the direct conversation shell.</p>

      <form method="GET" action="/inbox" style={{ display: "grid", gap: 12, maxWidth: 720, marginBottom: 20 }}>
        <label htmlFor="inbox-user-a-id">
          User A UUID
          <input
            id="inbox-user-a-id"
            name="userA"
            type="text"
            defaultValue={userAId}
            placeholder="Paste first user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <label htmlFor="inbox-user-b-id">
          User B UUID
          <input
            id="inbox-user-b-id"
            name="userB"
            type="text"
            defaultValue={userBId}
            placeholder="Paste second user UUID"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <label htmlFor="inbox-sender-id">
          Sender UUID (optional)
          <input
            id="inbox-sender-id"
            name="sender"
            type="text"
            defaultValue={senderUserId}
            placeholder="Defaults to User A if omitted"
            style={{ display: "block", width: "100%", marginTop: 8, padding: 10 }}
          />
        </label>
        <button type="submit" style={{ width: "fit-content", padding: "10px 14px" }}>
          Prefill inbox shell
        </button>
      </form>

      {userAId && userBId ? (
        <>
          <p>
            Active thread pair: <code>{userAId}</code> ↔ <code>{userBId}</code>
          </p>
          <p>
            Active sender context: <code>{senderUserId || "(not set)"}</code>
          </p>
          <p>
            Suggested pivot after validating the thread: <Link href={profileHref}>Profile</Link> · <Link href={feedHref}>Feed</Link> ·{" "}
            <Link href={notificationsHref}>Notifications</Link> · <Link href={locationHref}>Location</Link>
          </p>
          <p>
            Tip: these pivots now carry the current messaging context forward, so you can keep testing with the sender/user pair instead of retyping IDs from scratch.
          </p>
        </>
      ) : (
        <p>
          Provide two registered user UUIDs here before opening the direct thread, instead of manually retyping them inside the shell.
        </p>
      )}

      <DirectMessageShell initialUserAId={userAId} initialUserBId={userBId} initialSenderUserId={senderUserId} />
    </section>
  );
}
