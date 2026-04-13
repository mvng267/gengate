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

  return (
    <section>
      <h1>Profile</h1>
      <p>Friend graph shell is the best launcher for inspecting one user context, then pivoting into nearby MVP seams.</p>
      <p>
        Paste a registered user UUID into the URL as <code>?user=&lt;uuid&gt;</code>. Example: <code>/profile?user=YOUR_USER_UUID</code>
      </p>
      {selectedUserId ? (
        <>
          <p>
            Active profile user: <code>{selectedUserId}</code>
          </p>
          <p>
            Quick pivots: <Link href={`/feed`}>Feed</Link> · <Link href={`/inbox`}>Inbox</Link> ·{" "}
            <Link href={`/notifications`}>Notifications</Link> · <Link href={`/location`}>Location</Link>
          </p>
          <FriendGraphShell userId={selectedUserId} />
        </>
      ) : (
        <p>
          Provide <code>?user=&lt;uuid&gt;</code> on this route after creating users and friend requests in backend to inspect the
          friend graph shell and unlock related quick pivots.
        </p>
      )}
    </section>
  );
}
