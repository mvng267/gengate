import Link from "next/link";

import { fetchFriendGraphSnapshot } from "@/lib/friends/client";

type FriendGraphShellProps = {
  userId: string;
};

export async function FriendGraphShell({ userId }: FriendGraphShellProps) {
  try {
    const snapshot = await fetchFriendGraphSnapshot(userId);

    return (
      <section>
        <p>
          <strong>Status:</strong> friend graph MVP shell is wired to live backend contracts.
        </p>
        <p>
          <strong>User:</strong> {snapshot.userId}
        </p>
        <p>
          <strong>Pending requests:</strong> {snapshot.requestCount}
        </p>
        <p>
          <strong>Accepted friendships:</strong> {snapshot.friendshipCount}
        </p>

        <p>
          Next seam pivots for this profile context: <Link href="/feed">Feed</Link> · <Link href="/inbox">Inbox</Link> ·{" "}
          <Link href="/notifications">Notifications</Link> · <Link href="/location">Location</Link>
        </p>

        <h2>Pending friend requests</h2>
        {snapshot.pendingRequests.length === 0 ? (
          <p>No pending friend requests for this user yet.</p>
        ) : (
          <ul>
            {snapshot.pendingRequests.map((request) => (
              <li key={request.id}>
                <strong>{request.requester.username ?? request.requester.email}</strong>
                {" → "}
                <strong>{request.receiver.username ?? request.receiver.email}</strong>
                {" · status: "}
                {request.status}
              </li>
            ))}
          </ul>
        )}

        <h2>Accepted friendships</h2>
        {snapshot.friendships.length === 0 ? (
          <p>No accepted friendships for this user yet.</p>
        ) : (
          <ul>
            {snapshot.friendships.map((friendship) => (
              <li key={friendship.id}>
                <strong>{friendship.user_a.username ?? friendship.user_a.email}</strong>
                {" ↔ "}
                <strong>{friendship.user_b.username ?? friendship.user_b.email}</strong>
                {" · state: "}
                {friendship.state}
              </li>
            ))}
          </ul>
        )}
      </section>
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "friend_graph_fetch_failed";

    return (
      <section>
        <p>
          <strong>Status:</strong> friend graph shell is ready but backend data is not reachable from this web runtime yet.
        </p>
        <p>
          <strong>Requested user:</strong> {userId}
        </p>
        <p>
          <strong>Fetch error:</strong> {message}
        </p>
        <p>
          To test this seam, create/register two users in backend, post <code>/friends/requests</code>, optionally accept one request,
          then reload this page with <code>?user=&lt;uuid&gt;</code>.
        </p>
        <p>
          After friend graph data is visible here, you can pivot to <Link href="/feed">Feed</Link>, <Link href="/inbox">Inbox</Link>,{" "}
          <Link href="/notifications">Notifications</Link>, and <Link href="/location">Location</Link> from the same test session.
        </p>
      </section>
    );
  }
}
