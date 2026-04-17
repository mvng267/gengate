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
  autoloadSnapshot?: boolean;
  initialTargetUserId?: string;
};

const FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY =
  "request_id=(none) / action=created / requester=(none) / receiver=(none)";
const FRIEND_REQUEST_ACCEPT_QUICK_COPY_EMPTY =
  "request_id=(none) / action=accepted / accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)";
const FRIEND_REQUEST_REJECT_QUICK_COPY_EMPTY =
  "request_id=(none) / action=rejected / accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)";
const FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY =
  "request_id=(none) / action=(none) / accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)";
const FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY =
  "accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)";
const REQUEST_NOT_PENDING_FALLBACK_MESSAGE = "This request is no longer pending. Reload friend graph to continue.";

function resolveFriendRequestActionError(error: unknown, fallbackCode: string): string {
  if (error instanceof Error) {
    if (error.message.includes("request_not_pending")) {
      return REQUEST_NOT_PENDING_FALLBACK_MESSAGE;
    }
    return error.message;
  }

  return fallbackCode;
}

export function FriendGraphShell({
  userId,
  autoloadSnapshot = false,
  initialTargetUserId = "",
}: FriendGraphShellProps) {
  const [snapshot, setSnapshot] = useState<FriendGraphSnapshot | null>(null);
  const [status, setStatus] = useState("Ready to load the friend graph snapshot for this profile context.");
  const [targetUserId, setTargetUserId] = useState(() => initialTargetUserId.trim());
  const [isLoadingSnapshot, setIsLoadingSnapshot] = useState(false);
  const [isCreatingRequest, setIsCreatingRequest] = useState(false);
  const [busyRequestId, setBusyRequestId] = useState<string | null>(null);
  const [lastFriendGraphDeltaLine, setLastFriendGraphDeltaLine] = useState<string | null>(null);
  const [lastFriendGraphDeltaCopiedLine, setLastFriendGraphDeltaCopiedLine] = useState<string | null>(null);
  const [lastFriendRequestCreateQuickCopy, setLastFriendRequestCreateQuickCopy] = useState(FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY);
  const [lastFriendRequestAcceptQuickCopy, setLastFriendRequestAcceptQuickCopy] = useState(FRIEND_REQUEST_ACCEPT_QUICK_COPY_EMPTY);
  const [lastFriendRequestRejectQuickCopy, setLastFriendRequestRejectQuickCopy] = useState(FRIEND_REQUEST_REJECT_QUICK_COPY_EMPTY);
  const [lastFriendRequestDecisionQuickCopy, setLastFriendRequestDecisionQuickCopy] = useState(FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY);
  const [lastFriendRequestCountsQuickCopy, setLastFriendRequestCountsQuickCopy] = useState(FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY);
  const [lastFriendRequestCreateAcceptBundleQuickCopy, setLastFriendRequestCreateAcceptBundleQuickCopy] = useState(
    `friend_request_create_marker={${FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY}} | friend_request_accept_marker={${FRIEND_REQUEST_ACCEPT_QUICK_COPY_EMPTY}}`,
  );
  const [lastFriendRequestCreateRejectBundleQuickCopy, setLastFriendRequestCreateRejectBundleQuickCopy] = useState(
    `friend_request_create_marker={${FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY}} | friend_request_reject_marker={${FRIEND_REQUEST_REJECT_QUICK_COPY_EMPTY}}`,
  );
  const [lastFriendRequestLastActionBundleQuickCopy, setLastFriendRequestLastActionBundleQuickCopy] = useState(
    `friend_request_create_marker={${FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY}} | ` +
      `friend_request_decision_marker={${FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY}} | ` +
      `friend_request_counts={${FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY}}`,
  );
  const [lastFriendRequestLastActionBundleCopiedText, setLastFriendRequestLastActionBundleCopiedText] = useState("");
  const [friendRequestLastActionBundleCopiedAt, setFriendRequestLastActionBundleCopiedAt] = useState<number | null>(null);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const [hasAutoLoadedSnapshot, setHasAutoLoadedSnapshot] = useState(false);
  const [pendingPairMode, setPendingPairMode] = useState<"same" | "reverse" | null>(null);

  const normalizedTargetUserId = targetUserId.trim();
  const selectedPendingPairModeLabel = pendingPairMode ? ` · pending pair mode: ${pendingPairMode}` : "";
  const selectedPeerUserId = normalizedTargetUserId || userId;
  const feedHref = `/feed?author=${encodeURIComponent(userId)}&viewer=${encodeURIComponent(selectedPeerUserId)}`;
  const inboxHref = `/inbox?userA=${encodeURIComponent(userId)}&userB=${encodeURIComponent(selectedPeerUserId)}&sender=${encodeURIComponent(userId)}`;
  const notificationsHref = `/notifications?user=${encodeURIComponent(userId)}`;
  const locationHref = normalizedTargetUserId
    ? `/location?owner=${encodeURIComponent(userId)}&allowed=${encodeURIComponent(normalizedTargetUserId)}`
    : `/location?owner=${encodeURIComponent(userId)}`;
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

  const friendRequestLastActionBundleCopiedFeedbackText = (() => {
    if (friendRequestLastActionBundleCopiedAt === null) {
      return null;
    }

    const elapsedSeconds = Math.floor((Date.now() - friendRequestLastActionBundleCopiedAt) / 1000);
    if (elapsedSeconds < 0 || elapsedSeconds >= 6) {
      return null;
    }

    return `Copied friend-request last-action summary bundle (${elapsedSeconds}s ago): ${lastFriendRequestLastActionBundleCopiedText}`;
  })();

  function buildFriendRequestCreateAcceptBundleQuickCopy(input?: {
    createQuickCopy?: string;
    acceptQuickCopy?: string;
  }) {
    const normalizedCreateQuickCopy =
      input?.createQuickCopy?.trim() || lastFriendRequestCreateQuickCopy || FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY;
    const normalizedAcceptQuickCopy =
      input?.acceptQuickCopy?.trim() || lastFriendRequestAcceptQuickCopy || FRIEND_REQUEST_ACCEPT_QUICK_COPY_EMPTY;

    return `friend_request_create_marker={${normalizedCreateQuickCopy}} | friend_request_accept_marker={${normalizedAcceptQuickCopy}}`;
  }

  function buildFriendRequestCreateRejectBundleQuickCopy(input?: {
    createQuickCopy?: string;
    rejectQuickCopy?: string;
  }) {
    const normalizedCreateQuickCopy =
      input?.createQuickCopy?.trim() || lastFriendRequestCreateQuickCopy || FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY;
    const normalizedRejectQuickCopy =
      input?.rejectQuickCopy?.trim() || lastFriendRequestRejectQuickCopy || FRIEND_REQUEST_REJECT_QUICK_COPY_EMPTY;

    return `friend_request_create_marker={${normalizedCreateQuickCopy}} | friend_request_reject_marker={${normalizedRejectQuickCopy}}`;
  }

  function buildFriendRequestLastActionBundleQuickCopy(input?: {
    createQuickCopy?: string;
    decisionQuickCopy?: string;
    countsQuickCopy?: string;
  }) {
    const normalizedCreateQuickCopy =
      input?.createQuickCopy?.trim() || lastFriendRequestCreateQuickCopy || FRIEND_REQUEST_CREATE_QUICK_COPY_EMPTY;
    const normalizedDecisionQuickCopy =
      input?.decisionQuickCopy?.trim() || lastFriendRequestDecisionQuickCopy || FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY;
    const normalizedCountsQuickCopy =
      input?.countsQuickCopy?.trim() || lastFriendRequestCountsQuickCopy || FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY;

    return (
      `friend_request_create_marker={${normalizedCreateQuickCopy}} | ` +
      `friend_request_decision_marker={${normalizedDecisionQuickCopy}} | ` +
      `friend_request_counts={${normalizedCountsQuickCopy}}`
    );
  }

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  useEffect(() => {
    setTargetUserId(initialTargetUserId.trim());
  }, [initialTargetUserId]);

  useEffect(() => {
    if (!autoloadSnapshot || hasAutoLoadedSnapshot || !userId.trim()) {
      return;
    }

    setHasAutoLoadedSnapshot(true);
    void loadSnapshot("Auto-loading friend graph snapshot for profile context...");
  }, [autoloadSnapshot, hasAutoLoadedSnapshot, userId]);

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

      setPendingPairMode(null);
      setStatus(
        `Loaded friend graph: ${nextSnapshot.requestCount} pending request(s), ${nextSnapshot.friendshipCount} accepted friendship(s) · inbound: ${pendingBreakdown.inbound} · outbound: ${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "friend_graph_fetch_failed");
    }

    setIsLoadingSnapshot(false);
  }

  async function copyToClipboard(
    text: string,
    statusPrefix: string,
    emptyCode: string,
    failedCode: string,
    options?: {
      trackDeltaCopy?: boolean;
    },
  ): Promise<boolean> {
    const normalizedText = text.trim();
    if (!normalizedText) {
      setStatus(emptyCode);
      return false;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      return false;
    }

    try {
      await navigator.clipboard.writeText(normalizedText);
      if (options?.trackDeltaCopy) {
        setLastFriendGraphDeltaCopiedLine(normalizedText);
      }
      setStatus(`${statusPrefix} (${normalizedText}).`);
      return true;
    } catch {
      setStatus(failedCode);
      return false;
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

    const decisionQuickCopy =
      `request_id=${actingRequestId} / action=${action} / accepted_count=${nextSnapshot.friendshipCount} / ` +
      `pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}`;
    const countsQuickCopy =
      `accepted_count=${nextSnapshot.friendshipCount} / pending_inbound=${pendingBreakdown.inbound} / ` +
      `pending_outbound=${pendingBreakdown.outbound}`;

    setLastFriendGraphDeltaLine(decisionQuickCopy);
    setLastFriendRequestDecisionQuickCopy(decisionQuickCopy);
    setLastFriendRequestCountsQuickCopy(countsQuickCopy);

    return {
      decisionQuickCopy,
      countsQuickCopy,
      pendingBreakdown,
    };
  }

  async function handleCopyQuickDeltaSummary() {
    await copyToClipboard(
      quickDeltaSummary,
      "Copied friend graph quick delta summary to clipboard",
      "friend_graph_quick_delta_summary_empty",
      "friend_graph_quick_delta_summary_copy_failed",
      { trackDeltaCopy: true },
    );
  }

  async function handleCopyLastFriendGraphDeltaLine() {
    await copyToClipboard(
      lastFriendGraphDeltaLine ?? "",
      "Copied friend graph action delta line to clipboard",
      "friend_graph_action_delta_missing",
      "friend_graph_action_delta_copy_failed",
      { trackDeltaCopy: true },
    );
  }

  async function handleCopyFriendRequestCreateQuickCopy() {
    await copyToClipboard(
      lastFriendRequestCreateQuickCopy,
      "Copied friend-request create quick copy to clipboard",
      "friend_request_create_quick_copy_empty",
      "friend_request_create_quick_copy_failed",
    );
  }

  async function handleCopyFriendRequestAcceptQuickCopy() {
    await copyToClipboard(
      lastFriendRequestAcceptQuickCopy,
      "Copied friend-request accept quick copy to clipboard",
      "friend_request_accept_quick_copy_empty",
      "friend_request_accept_quick_copy_failed",
    );
  }

  async function handleCopyFriendRequestRejectQuickCopy() {
    await copyToClipboard(
      lastFriendRequestRejectQuickCopy,
      "Copied friend-request reject quick copy to clipboard",
      "friend_request_reject_quick_copy_empty",
      "friend_request_reject_quick_copy_failed",
    );
  }

  async function handleCopyFriendRequestCreateAcceptBundleQuickCopy() {
    await copyToClipboard(
      lastFriendRequestCreateAcceptBundleQuickCopy,
      "Copied friend-request create + accept bundle quick copy to clipboard",
      "friend_request_create_accept_bundle_quick_copy_empty",
      "friend_request_create_accept_bundle_quick_copy_failed",
    );
  }

  async function handleCopyFriendRequestCreateRejectBundleQuickCopy() {
    await copyToClipboard(
      lastFriendRequestCreateRejectBundleQuickCopy,
      "Copied friend-request create + reject bundle quick copy to clipboard",
      "friend_request_create_reject_bundle_quick_copy_empty",
      "friend_request_create_reject_bundle_quick_copy_failed",
    );
  }

  async function handleCopyFriendRequestLastActionBundleQuickCopy() {
    const copied = await copyToClipboard(
      lastFriendRequestLastActionBundleQuickCopy,
      "Copied friend-request last-action summary bundle quick copy to clipboard",
      "friend_request_last_action_bundle_quick_copy_empty",
      "friend_request_last_action_bundle_quick_copy_failed",
    );

    if (!copied) {
      return;
    }

    setLastFriendRequestLastActionBundleCopiedText(lastFriendRequestLastActionBundleQuickCopy);
    setFriendRequestLastActionBundleCopiedAt(Date.now());
  }

  async function handleApplyCurrentSessionUserAsRequesterAndLoad() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_requester_missing_for_quick_apply");
      return;
    }

    if (sessionUserId === userId) {
      await loadSnapshot("Requester already matches current session user (requester_source=session_user). Reloading friend graph snapshot...");
      return;
    }

    setStatus(
      "Applied current session user as requester (requester_source=session_user). Redirecting profile context and auto-loading friend graph snapshot...",
    );
    window.location.assign(`/profile?user=${encodeURIComponent(sessionUserId)}&autoload=1`);
  }

  async function submitSessionBoundFriendRequestCreateFlow(input: {
    requesterUserId: string;
    receiverUserId: string;
    statusPrefix: string;
    reloadedStatusMessage: string;
    fallbackErrorCode: string;
  }) {
    setIsCreatingRequest(true);
    setStatus(`${input.statusPrefix} Sending friend request...`);

    try {
      const created = await createFriendRequest({
        requesterUserId: input.requesterUserId,
        receiverUserId: input.receiverUserId,
      });
      const createQuickCopy =
        `request_id=${created.id} / action=created / requester=${input.requesterUserId} / ` +
        `receiver=${input.receiverUserId}`;
      setLastFriendRequestCreateQuickCopy(createQuickCopy);
      setLastFriendRequestCreateAcceptBundleQuickCopy(
        buildFriendRequestCreateAcceptBundleQuickCopy({
          createQuickCopy,
        }),
      );
      setLastFriendRequestCreateRejectBundleQuickCopy(
        buildFriendRequestCreateRejectBundleQuickCopy({
          createQuickCopy,
        }),
      );
      setLastFriendGraphDeltaLine(null);
      setLastFriendRequestDecisionQuickCopy(FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY);
      setLastFriendRequestCountsQuickCopy(FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY);
      setLastFriendRequestLastActionBundleQuickCopy(
        buildFriendRequestLastActionBundleQuickCopy({
          createQuickCopy,
          decisionQuickCopy: FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY,
          countsQuickCopy: FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY,
        }),
      );
      setLastFriendRequestLastActionBundleCopiedText("");
      setFriendRequestLastActionBundleCopiedAt(null);
      setPendingPairMode(null);
      setStatus(`${input.statusPrefix} Created friend request ${created.id}. Reloading friend graph snapshot...`);
      await loadSnapshot(input.reloadedStatusMessage);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : input.fallbackErrorCode);
    }

    setIsCreatingRequest(false);
  }

  async function handleApplyCurrentSessionUserAsReceiverAndSendFriendRequest() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_receiver_missing_for_quick_apply");
      return;
    }

    const requesterUserId = userId.trim();
    if (!requesterUserId) {
      setStatus("friend_request_requester_missing_for_quick_send");
      return;
    }

    if (requesterUserId === sessionUserId) {
      setStatus("friend_request_invalid_request code=invalid_request detail=requester và receiver phải khác nhau");
      return;
    }

    setTargetUserId(sessionUserId);
    await submitSessionBoundFriendRequestCreateFlow({
      requesterUserId,
      receiverUserId: sessionUserId,
      statusPrefix: "Applied current session user as receiver (receiver_source=session_user).",
      reloadedStatusMessage: "Reloading friend graph after session-receiver quick send...",
      fallbackErrorCode: "friend_request_quick_session_receiver_send_failed",
    });
  }

  async function handleApplyCurrentSessionUserAsRequesterKeepReceiverAndSendFriendRequest() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_requester_missing_for_quick_apply");
      return;
    }

    const receiverUserId = targetUserId.trim();
    if (!receiverUserId) {
      setStatus("friend_request_receiver_missing_for_quick_send");
      return;
    }

    if (sessionUserId === receiverUserId) {
      setStatus("friend_request_invalid_request code=invalid_request detail=requester và receiver phải khác nhau");
      return;
    }

    await submitSessionBoundFriendRequestCreateFlow({
      requesterUserId: sessionUserId,
      receiverUserId,
      statusPrefix: "Applied current session user as requester (requester_source=session_user) + kept receiver.",
      reloadedStatusMessage: "Reloading friend graph after session-requester quick send...",
      fallbackErrorCode: "friend_request_quick_session_requester_send_failed",
    });
  }

  async function handleCreateRequest(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const receiverUserId = targetUserId.trim();

    setIsCreatingRequest(true);
    setStatus("Creating friend request...");

    try {
      const created = await createFriendRequest({
        requesterUserId: userId,
        receiverUserId,
      });
      const createQuickCopy =
        `request_id=${created.id} / action=created / requester=${userId.trim()} / ` +
        `receiver=${receiverUserId}`;
      setLastFriendRequestCreateQuickCopy(createQuickCopy);
      setLastFriendRequestCreateAcceptBundleQuickCopy(
        buildFriendRequestCreateAcceptBundleQuickCopy({
          createQuickCopy,
        }),
      );
      setLastFriendRequestCreateRejectBundleQuickCopy(
        buildFriendRequestCreateRejectBundleQuickCopy({
          createQuickCopy,
        }),
      );
      setLastFriendGraphDeltaLine(null);
      setLastFriendRequestDecisionQuickCopy(FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY);
      setLastFriendRequestCountsQuickCopy(FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY);
      setLastFriendRequestLastActionBundleQuickCopy(
        buildFriendRequestLastActionBundleQuickCopy({
          createQuickCopy,
          decisionQuickCopy: FRIEND_REQUEST_DECISION_QUICK_COPY_EMPTY,
          countsQuickCopy: FRIEND_REQUEST_COUNTS_QUICK_COPY_EMPTY,
        }),
      );
      setPendingPairMode(null);
      setLastFriendRequestLastActionBundleCopiedText("");
      setFriendRequestLastActionBundleCopiedAt(null);
      setStatus(`Created friend request ${created.id}. Reloading friend graph snapshot...`);
      await loadSnapshot("Reloading friend graph after friend-request creation...");
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
      const { decisionQuickCopy, countsQuickCopy, pendingBreakdown } = applyDeltaFromSnapshot(nextSnapshot, requestId, "accepted");
      setLastFriendRequestAcceptQuickCopy(decisionQuickCopy);
      setLastFriendRequestCreateAcceptBundleQuickCopy(
        buildFriendRequestCreateAcceptBundleQuickCopy({
          acceptQuickCopy: decisionQuickCopy,
        }),
      );
      setLastFriendRequestLastActionBundleQuickCopy(
        buildFriendRequestLastActionBundleQuickCopy({
          decisionQuickCopy,
          countsQuickCopy,
        }),
      );
      setLastFriendRequestLastActionBundleCopiedText("");
      setFriendRequestLastActionBundleCopiedAt(null);

      setStatus(
        `Accepted friend request ${requestId}. ` +
          `accepted_count=${nextSnapshot.friendshipCount} / pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(resolveFriendRequestActionError(error, "friend_request_accept_failed"));
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
      const { decisionQuickCopy, countsQuickCopy, pendingBreakdown } = applyDeltaFromSnapshot(nextSnapshot, requestId, "rejected");
      setLastFriendRequestRejectQuickCopy(decisionQuickCopy);
      setLastFriendRequestCreateRejectBundleQuickCopy(
        buildFriendRequestCreateRejectBundleQuickCopy({
          rejectQuickCopy: decisionQuickCopy,
        }),
      );
      setLastFriendRequestLastActionBundleQuickCopy(
        buildFriendRequestLastActionBundleQuickCopy({
          decisionQuickCopy,
          countsQuickCopy,
        }),
      );
      setLastFriendRequestLastActionBundleCopiedText("");
      setFriendRequestLastActionBundleCopiedAt(null);

      setStatus(
        `Rejected friend request ${requestId}. ` +
          `accepted_count=${nextSnapshot.friendshipCount} / pending_inbound=${pendingBreakdown.inbound} / pending_outbound=${pendingBreakdown.outbound}.`,
      );
    } catch (error) {
      setStatus(resolveFriendRequestActionError(error, "friend_request_reject_failed"));
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
            Snapshot summary: Requested user: <code>{userId}</code>
            {selectedPendingPairModeLabel}
          </p>
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
          <p>
            Quick copy friend-request create marker: <code>{lastFriendRequestCreateQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestCreateQuickCopy()}>
              Copy quick friend-request create marker
            </button>
          </p>
          <p>
            Quick copy friend-request accept marker: <code>{lastFriendRequestAcceptQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestAcceptQuickCopy()}>
              Copy quick friend-request accept marker
            </button>
          </p>
          <p>
            Quick copy friend-request reject marker: <code>{lastFriendRequestRejectQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestRejectQuickCopy()}>
              Copy quick friend-request reject marker
            </button>
          </p>
          <p>
            Quick copy friend-request create + accept bundle: <code>{lastFriendRequestCreateAcceptBundleQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestCreateAcceptBundleQuickCopy()}>
              Copy quick friend-request create + accept bundle
            </button>
          </p>
          <p>
            Quick copy friend-request create + reject bundle: <code>{lastFriendRequestCreateRejectBundleQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestCreateRejectBundleQuickCopy()}>
              Copy quick friend-request create + reject bundle
            </button>
          </p>
          <p>
            Quick copy friend-request last-action summary bundle: <code>{lastFriendRequestLastActionBundleQuickCopy}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyFriendRequestLastActionBundleQuickCopy()}>
              Copy quick friend-request last-action summary bundle
            </button>
          </p>
          {friendRequestLastActionBundleCopiedFeedbackText ? <p>{friendRequestLastActionBundleCopiedFeedbackText}</p> : null}
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
          onClick={() => void handleApplyCurrentSessionUserAsRequesterAndLoad()}
          disabled={!currentSessionUserId || isLoadingSnapshot || isCreatingRequest}
        >
          Use current session user as requester + load friend graph
        </button>
        <button
          type="button"
          onClick={() => void handleApplyCurrentSessionUserAsReceiverAndSendFriendRequest()}
          disabled={!currentSessionUserId || isLoadingSnapshot || isCreatingRequest}
        >
          Use current session user as receiver + send friend request
        </button>
        <button
          type="button"
          onClick={() => void handleApplyCurrentSessionUserAsRequesterKeepReceiverAndSendFriendRequest()}
          disabled={!currentSessionUserId || isLoadingSnapshot || isCreatingRequest}
        >
          Use current session user as requester + keep receiver + send friend request
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
            const isPending = request.status === "pending";
            const canAccept = isPending && request.receiver.id === userId;
            const canReject = isPending && (request.receiver.id === userId || request.requester.id === userId);
            const isSamePairSelected =
              normalizedTargetUserId === request.receiver.id && userId.trim() === request.requester.id;
            const isReversePairSelected =
              normalizedTargetUserId === request.requester.id && userId.trim() === request.receiver.id;

            return (
              <li key={request.id}>
                <strong>{request.requester.username ?? request.requester.email}</strong>
                {" → "}
                <strong>{request.receiver.username ?? request.receiver.email}</strong>
                {" · status: "}
                {request.status}
                <div style={{ marginTop: 6, display: "flex", gap: 8, flexWrap: "wrap" }}>
                  <button
                    type="button"
                    onClick={() => {
                      setTargetUserId(request.receiver.id);
                      setPendingPairMode("same");
                      setStatus("Filled same pair from pending request (pending_pair_mode=same).");
                    }}
                    disabled={isLoadingSnapshot || isCreatingRequest || isSamePairSelected}
                  >
                    {isSamePairSelected ? "Using same pair" : "Use same pair"}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setTargetUserId(request.requester.id);
                      setPendingPairMode("reverse");
                      setStatus("Filled reverse pair from pending request (pending_pair_mode=reverse).");
                    }}
                    disabled={isLoadingSnapshot || isCreatingRequest || isReversePairSelected}
                  >
                    {isReversePairSelected ? "Using reverse pair" : "Use reverse pair"}
                  </button>
                  {canAccept ? (
                    <button
                      type="button"
                      onClick={() => void handleAcceptRequest(request.id)}
                      disabled={busyRequestId === request.id}
                    >
                      {busyRequestId === request.id ? "Processing..." : "Accept"}
                    </button>
                  ) : null}
                  {canReject ? (
                    <button
                      type="button"
                      onClick={() => void handleRejectRequest(request.id)}
                      disabled={busyRequestId === request.id}
                    >
                      {busyRequestId === request.id ? "Processing..." : "Reject"}
                    </button>
                  ) : null}
                </div>
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
