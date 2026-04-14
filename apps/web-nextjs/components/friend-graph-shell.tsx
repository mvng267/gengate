"use client";

import Link from "next/link";
import { useState } from "react";

import { acceptFriendRequest, createFriendRequest, fetchFriendGraphSnapshot, type FriendGraphSnapshot } from "@/lib/friends/client";

type FriendGraphShellProps = {
  userId: string;
};

export function FriendGraphShell({ userId }: FriendGraphShellProps) {
  const [snapshot, setSnapshot] = useState<FriendGraphSnapshot | null>(null);
  const [status, setStatus] = useState("Ready to load the friend graph snapshot for this profile context.");
  const [targetUserId, setTargetUserId] = useState("");
  const [isLoadingSnapshot, setIsLoadingSnapshot] = useState(false);
  const [isCreatingRequest, setIsCreatingRequest] = useState(false);
  const [busyRequestId, setBusyRequestId] = useState<string | null>(null);

  const feedHref = `/feed?author=${encodeURIComponent(userId)}&viewer=${encodeURIComponent(userId)}`;
  const inboxHref = `/inbox?userA=${encodeURIComponent(userId)}&sender=${encodeURIComponent(userId)}`;
  const notificationsHref = `/notifications?user=${encodeURIComponent(userId)}`;
  const locationHref = `/location?owner=${encodeURIComponent(userId)}`;
  const pendingDirectionSummary = snapshot
    ? snapshot.pendingRequests.reduce(
        (acc, request) => {
          if (request.status !== "pending") {
            return acc;
          }

          if (request.receiver.id === userId) {
            acc.inbound += 1;
          }

          if (request.requester.id === userId) {
            acc.outbound += 1;
          }

          acc.total += 1;
          return acc;
        },
        { inbound: 0, outbound: 0, total: 0 },
      )
    : null;
  const quickCopySummary = pendingDirectionSummary
    ? `user=${userId} | pending_inbound=${pendingDirectionSummary.inbound} | pending_outbound=${pendingDirectionSummary.outbound} | pending_total=${pendingDirectionSummary.total} | accepted=${snapshot?.friendshipCount ?? 0}`
    : null;

  async function loadSnapshot(message?: string) {
    setIsLoadingSnapshot(true);
    setStatus(message ?? "Loading friend graph snapshot...");

    try {
      const nextSnapshot = await fetchFriendGraphSnapshot(userId);
      setSnapshot(nextSnapshot);

      const pendingBreakdown = nextSnapshot.pendingRequests.reduce(
        (acc, request) => {
          if (request.status !== "pending") {
            return acc;
          }

          if (request.receiver.id === userId) {
            acc.inbound += 1;
          }

          if (request.requester.id === userId) {
            acc.outbound += 1;
          }

          return acc;
        },
        { inbound: 0, outbound: 0 },
      );

      setStatus(
        `Loaded friend graph: ${nextSnapshot.requestCount} pending request(s), ${nextSnapshot.friendshipCount} accepted friendship(s) · inbound: ${pendingBreakdown.inbound} · outbound: ${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_graph_fetch_failed");
    }

    setIsLoadingSnapshot(false);
  }

  async function handleCreateRequest(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    setIsCreatingRequest(true);
    setStatus("Creating friend request...");

    try {
      const created = await createFriendRequest({
        requesterUserId: userId,
        receiverUserId: targetUserId.trim(),
      });
      setStatus(`Created friend request ${created.id}. Reloading friend graph snapshot...`);
      await loadSnapshot("Reloading friend graph after friend-request creation...");
      setTargetUserId("");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_request_create_failed");
    }

    setIsCreatingRequest(false);
  }

  async function handleAcceptRequest(requestId: string) {
    setBusyRequestId(requestId);
    setStatus(`Accepting friend request ${requestId}...`);

    try {
      await acceptFriendRequest(requestId);
      setStatus(`Accepted friend request ${requestId}. Reloading friend graph snapshot...`);
      await loadSnapshot("Reloading friend graph after request accept...");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_request_accept_failed");
    }

    setBusyRequestId(null);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> friend graph MVP shell is wired to live backend contracts.
      </p>
      <p>{status}</p>
      <p>
        <strong>User:</strong> {userId}
      </p>
      {pendingDirectionSummary ? (
        <>
          <p>
            Pending summary: Inbound pending <strong>{pendingDirectionSummary.inbound}</strong> · Outbound pending{" "}
            <strong>{pendingDirectionSummary.outbound}</strong> · Total pending <strong>{pendingDirectionSummary.total}</strong>
          </p>
          <p>
            Quick copy: <code>{quickCopySummary}</code>
          </p>
        </>
      ) : (
        <p>Pending summary: load snapshot to view inbound/outbound pending counts.</p>
      )}
      <p>
        Next seam pivots for this profile context: <Link href={feedHref}>Feed</Link> · <Link href={inboxHref}>Inbox</Link> ·{" "}
        <Link href={notificationsHref}>Notifications</Link> · <Link href={locationHref}>Location</Link>
      </p>

      <div style={{ marginBottom: 16 }}>
        <button type="button" onClick={() => void loadSnapshot()} disabled={isLoadingSnapshot}>
          {isLoadingSnapshot ? "Loading..." : "Load friend graph snapshot"}
        </button>
      </div>

      <form onSubmit={(event) => void handleCreateRequest(event)} style={{ display: "grid", gap: 8, maxWidth: 640, marginBottom: 20 }}>
        <label>
          Receiver user UUID
          <input
            value={targetUserId}
            onChange={(event) => setTargetUserId(event.target.value)}
            placeholder="paste target user uuid to send friend request"
          />
        </label>
        <button type="submit" disabled={isCreatingRequest}>
          {isCreatingRequest ? "Sending..." : "Send friend request"}
        </button>
      </form>

      <h2>Pending friend requests</h2>
      {!snapshot ? (
        <p>Load snapshot to view pending requests.</p>
      ) : snapshot.pendingRequests.length === 0 ? (
        <p>No pending friend requests for this user yet.</p>
      ) : (
        <ul>
          {snapshot.pendingRequests.map((request) => {
            const canAccept = request.receiver.id === userId && request.status === "pending";
            return (
              <li key={request.id}>
                <strong>{request.requester.username ?? request.requester.email}</strong>
                {" → "}
                <strong>{request.receiver.username ?? request.receiver.email}</strong>
                {" · status: "}
                {request.status}
                {canAccept ? (
                  <>
                    {" "}
                    <button
                      type="button"
                      onClick={() => void handleAcceptRequest(request.id)}
                      disabled={busyRequestId === request.id}
                    >
                      {busyRequestId === request.id ? "Accepting..." : "Accept"}
                    </button>
                  </>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}

      <h2>Accepted friendships</h2>
      {!snapshot ? (
        <p>Load snapshot to view accepted friendships.</p>
      ) : snapshot.friendships.length === 0 ? (
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
}
