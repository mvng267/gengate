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
            Suggested pivot after validating the thread: <Link href="/profile">Profile</Link> · <Link href="/feed">Feed</Link> ·{" "}
            <Link href="/notifications">Notifications</Link> · <Link href="/location">Location</Link>
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
