"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  acceptFriendRequest,
  createFriendRequest,
  fetchFriendGraphSnapshot,
  rejectFriendRequest,
  type FriendGraphSnapshot,
} from "@/lib/friends/client";

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
  const [lastFriendGraphDeltaLine, setLastFriendGraphDeltaLine] = useState<string | null>(null);
  const [lastFriendGraphDeltaCopiedLine, setLastFriendGraphDeltaCopiedLine] = useState<string | null>(null);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");

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
  const quickDeltaSummary = pendingDirectionSummary
    ? `accepted_count=${snapshot?.friendshipCount ?? 0} / pending_inbound=${pendingDirectionSummary.inbound} / pending_outbound=${pendingDirectionSummary.outbound}`
    : "accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)";

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

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

  async function copyToClipboard(text: string, statusPrefix: string, emptyCode: string, failedCode: string) {
    const normalizedText = text.trim();
    if (!normalizedText) {
      setStatus(emptyCode);
      return;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      return;
    }

    try {
      await navigator.clipboard.writeText(normalizedText);
      setLastFriendGraphDeltaCopiedLine(normalizedText);
      setStatus(`${statusPrefix} (${normalizedText}).`);
    } catch {
      setStatus(failedCode);
    }
  }

  function applyDeltaFromSnapshot(nextSnapshot: FriendGraphSnapshot, actingRequestId: string, action: "accepted" | "rejected") {
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

    const deltaLine =
      `request_id=${actingRequestId} / action=${action} / accepted_count=${nextSnapshot.friendshipCount} / ` +
      `pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}`;
    setLastFriendGraphDeltaLine(deltaLine);
  }

  async function handleCopyQuickDeltaSummary() {
    await copyToClipboard(
      quickDeltaSummary,
      "Copied friend graph quick delta summary to clipboard",
      "friend_graph_quick_delta_summary_empty",
      "friend_graph_quick_delta_summary_copy_failed",
    );
  }

  async function handleCopyLastFriendGraphDeltaLine() {
    await copyToClipboard(
      lastFriendGraphDeltaLine ?? "",
      "Copied friend graph action delta line to clipboard",
      "friend_graph_action_delta_missing",
      "friend_graph_action_delta_copy_failed",
    );
  }

  async function handleApplyCurrentSessionUserAsRequester() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_requester_missing_for_quick_apply");
      return;
    }

    if (sessionUserId === userId) {
      await loadSnapshot("Requester already matches current session user (requester_source=session_user). Reloading friend graph snapshot...");
      return;
    }

    setStatus("Applied current session user as requester (requester_source=session_user). Redirecting profile context...");
    window.location.assign(`/profile?user=${encodeURIComponent(sessionUserId)}`);
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
      setLastFriendGraphDeltaLine(null);
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
      const nextSnapshot = await fetchFriendGraphSnapshot(userId);
      setSnapshot(nextSnapshot);
      applyDeltaFromSnapshot(nextSnapshot, requestId, "accepted");

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
        `Accepted friend request ${requestId}. ` +
          `accepted_count=${nextSnapshot.friendshipCount} / pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_request_accept_failed");
    }

    setBusyRequestId(null);
  }

  async function handleRejectRequest(requestId: string) {
    setBusyRequestId(requestId);
    setStatus(`Rejecting friend request ${requestId}...`);

    try {
      await rejectFriendRequest(requestId);
      const nextSnapshot = await fetchFriendGraphSnapshot(userId);
      setSnapshot(nextSnapshot);
      applyDeltaFromSnapshot(nextSnapshot, requestId, "rejected");

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
        `Rejected friend request ${requestId}. ` +
          `accepted_count=${nextSnapshot.friendshipCount} / pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_request_reject_failed");
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
      {currentSessionUserId ? (
        <p>
          <strong>Current session user_id:</strong> <code>{currentSessionUserId}</code>
        </p>
      ) : null}
      {pendingDirectionSummary ? (
        <>
          <p>
            Pending summary: Inbound pending <strong>{pendingDirectionSummary.inbound}</strong> · Outbound pending{" "}
            <strong>{pendingDirectionSummary.outbound}</strong> · Total pending <strong>{pendingDirectionSummary.total}</strong>
          </p>
          <p>
            Quick copy: <code>{quickCopySummary}</code>
          </p>
          <p>
            Quick delta summary: <code>{quickDeltaSummary}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyQuickDeltaSummary()}>
              Copy quick delta summary
            </button>
          </p>
          {lastFriendGraphDeltaLine ? (
            <>
              <p>
                Last action delta: <code>{lastFriendGraphDeltaLine}</code>
              </p>
              <p>
                <button type="button" onClick={() => void handleCopyLastFriendGraphDeltaLine()}>
                  Copy last action delta
                </button>
              </p>
            </>
          ) : null}
          {lastFriendGraphDeltaCopiedLine ? (
            <p>
              Last copied delta: <code>{lastFriendGraphDeltaCopiedLine}</code>
            </p>
          ) : null}
        </>
      ) : (
        <p>Pending summary: load snapshot to view inbound/outbound pending counts.</p>
      )}
      <p>
        Next seam pivots for this profile context: <Link href={feedHref}>Feed</Link> · <Link href={inboxHref}>Inbox</Link> ·{" "}
        <Link href={notificationsHref}>Notifications</Link> · <Link href={locationHref}>Location</Link>
      </p>

      <div style={{ marginBottom: 16, display: "grid", gap: 8 }}>
        <button type="button" onClick={() => void loadSnapshot()} disabled={isLoadingSnapshot}>
          {isLoadingSnapshot ? "Loading..." : "Load friend graph snapshot"}
        </button>
        <button
          type="button"
          onClick={() => void handleApplyCurrentSessionUserAsRequester()}
          disabled={!currentSessionUserId || isLoadingSnapshot || isCreatingRequest}
        >
          Use current session user as requester
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
                      {busyRequestId === request.id ? "Processing..." : "Accept"}
                    </button>
                    {" "}
                    <button
                      type="button"
                      onClick={() => void handleRejectRequest(request.id)}
                      disabled={busyRequestId === request.id}
                    >
                      {busyRequestId === request.id ? "Processing..." : "Reject"}
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
