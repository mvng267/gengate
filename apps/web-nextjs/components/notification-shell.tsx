"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createNotification,
  deleteNotification,
  listNotifications,
  markNotificationRead,
  markNotificationUnread,
  type NotificationItem,
  type NotificationListPayload,
} from "@/lib/notifications/client";

type NotificationShellProps = {
  initialUserId?: string;
};

const initialForm = {
  userId: "",
  notificationType: "friend_request",
  payloadJson: '{"message":"Demo notification"}',
};

const notificationNotFoundFallbackMessage = "Notification no longer exists. Reload notifications and retry on a fresh notification row.";
const userNotFoundFallbackMessage = "A referenced user was not found. Verify user UUID and retry load/create action.";
const validationErrorFallbackMessage = "Request payload is invalid. Re-check user/type/payload JSON and retry.";
const notificationUserRequiredFallbackMessage = "Provide a user UUID before loading or creating notifications.";
const notificationTypeRequiredFallbackMessage = "Provide a notification type before creating a notification.";
const notificationPayloadJsonInvalidFallbackMessage = "Payload JSON must be a valid object. Fix JSON format then retry create.";
const sessionUserMissingFallbackMessage =
  "Current session user is missing. Sign in first or manually provide user UUID for quick apply actions.";

function resolveNotificationErrorHint(message: string): string | null {
  if (message.includes("notification_not_found")) {
    return notificationNotFoundFallbackMessage;
  }

  if (message.includes("user_not_found")) {
    return userNotFoundFallbackMessage;
  }

  if (message.includes("validation_error")) {
    return validationErrorFallbackMessage;
  }

  if (message.includes("notification_user_id_required")) {
    return notificationUserRequiredFallbackMessage;
  }

  if (message.includes("notification_type_required")) {
    return notificationTypeRequiredFallbackMessage;
  }

  if (message.includes("notification_payload_json_invalid")) {
    return notificationPayloadJsonInvalidFallbackMessage;
  }

  if (message.includes("session_user_missing_for_quick_apply")) {
    return sessionUserMissingFallbackMessage;
  }

  return null;
}

type NotificationLoadWindow = {
  userId: string;
  limit: number;
  offset: number;
  unreadOnly: boolean;
};

type NotificationMutationDelta = {
  notificationId: string;
  readState: "read" | "unread";
  currentPageUnread: number | null;
  totalUnreadCount: number | null;
};

type NotificationCreateResultDelta = {
  notificationId: string;
  readState: "read" | "unread";
  currentPageUnread: number | null;
  totalUnreadCount: number | null;
};

type NotificationDeleteResultDelta = {
  notificationId: string;
  previousReadState: "read" | "unread";
  currentPageCount: number | null;
  currentPageUnread: number | null;
  totalUnreadCount: number | null;
  window: NotificationLoadWindow;
};

type NotificationLifecyclePair = {
  createResult: NotificationCreateResultDelta;
  mutationDelta: NotificationMutationDelta;
};

type NotificationCreateFlowInput = {
  userIdOverride?: string;
  statusPrefix?: string;
  reloadAfterCreate?: boolean;
  loadWindowOverride?: Partial<NotificationLoadWindow>;
};

export function NotificationShell({ initialUserId = "" }: NotificationShellProps) {
  const [form, setForm] = useState({
    ...initialForm,
    userId: initialUserId,
  });
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [listMeta, setListMeta] = useState<Pick<NotificationListPayload, "count" | "unread_count" | "total_unread_count"> | null>(null);
  const [pagination, setPagination] = useState({ limit: 20, offset: 0, unreadOnly: false });
  const [status, setStatus] = useState("Provide a real user UUID to load notifications or create a minimal notification shell item.");
  const [isLoading, setIsLoading] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [lastLoadedWindow, setLastLoadedWindow] = useState<NotificationLoadWindow | null>(null);
  const [lastMutationDelta, setLastMutationDelta] = useState<NotificationMutationDelta | null>(null);
  const [lastCreateResultDelta, setLastCreateResultDelta] = useState<NotificationCreateResultDelta | null>(null);
  const [lastDeleteResultDelta, setLastDeleteResultDelta] = useState<NotificationDeleteResultDelta | null>(null);
  const [lastLifecyclePair, setLastLifecyclePair] = useState<NotificationLifecyclePair | null>(null);
  const [lastQuickLifecycleSnapshotAuditCopiedText, setLastQuickLifecycleSnapshotAuditCopiedText] = useState("");
  const [quickLifecycleSnapshotAuditCopiedAt, setQuickLifecycleSnapshotAuditCopiedAt] = useState<number | null>(null);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");

  useEffect(() => {
    setForm((current) => ({
      ...current,
      userId: initialUserId,
    }));
    setItems([]);
    setListMeta(null);
    setPagination({ limit: 20, offset: 0, unreadOnly: false });
    setDeletingId(null);
    setLastLoadedWindow(null);
    setLastMutationDelta(null);
    setLastCreateResultDelta(null);
    setLastDeleteResultDelta(null);
    setLastLifecyclePair(null);
    setLastQuickLifecycleSnapshotAuditCopiedText("");
    setQuickLifecycleSnapshotAuditCopiedAt(null);
  }, [initialUserId]);

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  function currentLoadWindow(overrides?: Partial<NotificationLoadWindow>): NotificationLoadWindow {
    return {
      userId: overrides?.userId ?? form.userId.trim(),
      limit: overrides?.limit ?? pagination.limit,
      offset: overrides?.offset ?? pagination.offset,
      unreadOnly: overrides?.unreadOnly ?? pagination.unreadOnly,
    };
  }

  async function handleLoad(windowOverride?: Partial<NotificationLoadWindow>, statusPrefix?: string) {
    const window = currentLoadWindow(windowOverride);
    const normalizedStatusPrefix = statusPrefix?.trim();

    setIsLoading(true);
    setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} Loading notifications...` : "Loading notifications...");

    try {
      const payload = await listNotifications(window.userId, {
        limit: window.limit,
        offset: window.offset,
        unreadOnly: window.unreadOnly,
      });
      setItems(payload.items);
      setListMeta({
        count: payload.count,
        unread_count: payload.unread_count,
        total_unread_count: payload.total_unread_count,
      });
      setLastLoadedWindow(window);

      const loadedStatus =
        `Loaded ${payload.count} notification(s) for ${window.userId || "unknown-user"}. ` +
        `Page unread: ${payload.unread_count}. Total unread: ${payload.total_unread_count}. ` +
        `Page window limit=${window.limit}, offset=${window.offset}, unread_only=${window.unreadOnly}.`;
      setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} ${loadedStatus}` : loadedStatus);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "notifications_list_failed";
      setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} ${errorMessage}` : errorMessage);
    }

    setIsLoading(false);
  }

  const pendingWindowChange =
    lastLoadedWindow === null ||
    lastLoadedWindow.userId !== form.userId.trim() ||
    lastLoadedWindow.limit !== pagination.limit ||
    lastLoadedWindow.offset !== pagination.offset ||
    lastLoadedWindow.unreadOnly !== pagination.unreadOnly;

  const pendingWindowHint =
    lastLoadedWindow === null
      ? "Window hint: no list window has been loaded yet. Use Load notifications to sync the first result set."
      : pendingWindowChange
        ? "Window hint: current user/page/filter differs from the last loaded window. Reload to sync the list and summary."
        : "Window hint: current user/page/filter is in sync with the last loaded window.";

  const notificationErrorHint = resolveNotificationErrorHint(status);

  const quickUnreadSummaryLine = listMeta
    ? `current_page_unread=${listMeta.unread_count} / total_unread_count=${listMeta.total_unread_count}`
    : "current_page_unread=(none) / total_unread_count=(none)";

  const quickPageMetaLine = listMeta
    ? `count=${listMeta.count} / unread_count=${listMeta.unread_count} / total_unread_count=${listMeta.total_unread_count} / limit=${pagination.limit} / offset=${pagination.offset} / filter_mode=${pagination.unreadOnly ? "unread_only" : "all"}`
    : "count=(none) / unread_count=(none) / total_unread_count=(none) / limit=(none) / offset=(none) / filter_mode=(none)";

  const cursorWindow = lastLoadedWindow ?? currentLoadWindow();
  const quickPageCursorSummaryLine =
    `user_id=${cursorWindow.userId || "(empty)"}` +
    ` / limit=${cursorWindow.limit}` +
    ` / offset=${cursorWindow.offset}` +
    ` / filter_mode=${cursorWindow.unreadOnly ? "unread_only" : "all"}` +
    ` / count=${listMeta ? listMeta.count : "(none)"}` +
    ` / unread_count=${listMeta ? listMeta.unread_count : "(none)"}` +
    ` / total_unread_count=${listMeta ? listMeta.total_unread_count : "(none)"}`;

  const quickMutationDeltaLine = lastMutationDelta
    ? `notification_id=${lastMutationDelta.notificationId} / read_state=${lastMutationDelta.readState} / current_page_unread=${lastMutationDelta.currentPageUnread ?? "(none)"} / total_unread_count=${lastMutationDelta.totalUnreadCount ?? "(none)"}`
    : "notification_id=(none) / read_state=(none) / current_page_unread=(none) / total_unread_count=(none)";

  const quickCreateResultDeltaLine = lastCreateResultDelta
    ? `notification_id=${lastCreateResultDelta.notificationId} / read_state=${lastCreateResultDelta.readState} / current_page_unread=${lastCreateResultDelta.currentPageUnread ?? "(none)"} / total_unread_count=${lastCreateResultDelta.totalUnreadCount ?? "(none)"}`
    : "notification_id=(none) / read_state=(none) / current_page_unread=(none) / total_unread_count=(none)";

  const quickDeleteResultSummaryLine = lastDeleteResultDelta
    ? `delete_result=deleted / notification_id=${lastDeleteResultDelta.notificationId} / previous_read_state=${lastDeleteResultDelta.previousReadState} / current_page_count=${lastDeleteResultDelta.currentPageCount ?? "(none)"} / current_page_unread=${lastDeleteResultDelta.currentPageUnread ?? "(none)"} / total_unread_count=${lastDeleteResultDelta.totalUnreadCount ?? "(none)"} / window(limit=${lastDeleteResultDelta.window.limit},offset=${lastDeleteResultDelta.window.offset},filter_mode=${lastDeleteResultDelta.window.unreadOnly ? "unread_only" : "all"})`
    : "delete_result=(none) / notification_id=(none) / previous_read_state=(none) / current_page_count=(none) / current_page_unread=(none) / total_unread_count=(none) / window(limit=(none),offset=(none),filter_mode=(none))";

  const quickLifecyclePairState = lastLifecyclePair
    ? "matched"
    : lastCreateResultDelta && lastMutationDelta
      ? "mismatched"
      : "missing";

  const lifecyclePairSubject =
    quickLifecyclePairState === "missing"
      ? "none"
      : quickLifecyclePairState === "matched"
        ? "same_notification"
        : "cross_notification";

  const lifecycleCreateResult = lastLifecyclePair?.createResult ?? lastCreateResultDelta;
  const lifecycleMutationDelta = lastLifecyclePair?.mutationDelta ?? lastMutationDelta;

  const lifecyclePairTransition =
    quickLifecyclePairState === "missing"
      ? "none->none"
      : `${lifecycleCreateResult?.readState ?? "none"}->${lifecycleMutationDelta?.readState ?? "none"}`;

  const lifecyclePairTransitionContext =
    lifecyclePairTransition === "none->none"
      ? "none"
      : lifecyclePairTransition === "read->read" || lifecyclePairTransition === "unread->unread"
        ? "unchanged"
        : "changed";

  const lifecyclePairTransitionText = `lifecycle_pair_transition=${lifecyclePairTransition}`;
  const lifecyclePairTransitionContextText = `lifecycle_pair_transition_context=${lifecyclePairTransitionContext}`;

  const quickLifecyclePairLine =
    `lifecycle_pair_state=${quickLifecyclePairState}` +
    ` / lifecycle_pair_subject=${lifecyclePairSubject}` +
    ` / ${lifecyclePairTransitionText}` +
    ` / ${lifecyclePairTransitionContextText}` +
    ` / create_result(notification_id=${lifecycleCreateResult?.notificationId ?? "(none)"},read_state=${lifecycleCreateResult?.readState ?? "(none)"},current_page_unread=${lifecycleCreateResult?.currentPageUnread ?? "(none)"},total_unread_count=${lifecycleCreateResult?.totalUnreadCount ?? "(none)"})` +
    ` / mutation_delta(notification_id=${lifecycleMutationDelta?.notificationId ?? "(none)"},read_state=${lifecycleMutationDelta?.readState ?? "(none)"},current_page_unread=${lifecycleMutationDelta?.currentPageUnread ?? "(none)"},total_unread_count=${lifecycleMutationDelta?.totalUnreadCount ?? "(none)"})`;

  const quickLifecyclePairMutationLine =
    `lifecycle_pair_state=${quickLifecyclePairState}` +
    ` / lifecycle_pair_subject=${lifecyclePairSubject}` +
    ` / ${lifecyclePairTransitionText}` +
    ` / ${lifecyclePairTransitionContextText}` +
    ` / mutation_delta(notification_id=${lifecycleMutationDelta?.notificationId ?? "(none)"},read_state=${lifecycleMutationDelta?.readState ?? "(none)"},current_page_unread=${lifecycleMutationDelta?.currentPageUnread ?? "(none)"},total_unread_count=${lifecycleMutationDelta?.totalUnreadCount ?? "(none)"})`;

  const quickUnreadLifecycleMutationBundleLine =
    `unread_summary(${quickUnreadSummaryLine})` +
    ` / lifecycle_pair_state=${quickLifecyclePairState}` +
    ` / lifecycle_pair_subject=${lifecyclePairSubject}` +
    ` / ${lifecyclePairTransitionText}` +
    ` / ${lifecyclePairTransitionContextText}` +
    ` / mutation_delta(notification_id=${lifecycleMutationDelta?.notificationId ?? "(none)"},read_state=${lifecycleMutationDelta?.readState ?? "(none)"},current_page_unread=${lifecycleMutationDelta?.currentPageUnread ?? "(none)"},total_unread_count=${lifecycleMutationDelta?.totalUnreadCount ?? "(none)"})`;

  const quickLifecycleSnapshotAuditLine =
    `lifecycle_pair_state=${quickLifecyclePairState}` +
    ` / lifecycle_pair_subject=${lifecyclePairSubject}` +
    ` / ${lifecyclePairTransitionText}` +
    ` / ${lifecyclePairTransitionContextText}` +
    ` / create_notification_id=${lifecycleCreateResult?.notificationId ?? "(none)"}` +
    ` / mutation_notification_id=${lifecycleMutationDelta?.notificationId ?? "(none)"}` +
    ` / unread_summary(${quickUnreadSummaryLine})` +
    ` / window(limit=${cursorWindow.limit},offset=${cursorWindow.offset},filter_mode=${cursorWindow.unreadOnly ? "unread_only" : "all"})`;

  const quickLifecycleSnapshotAuditCopiedFeedbackText = (() => {
    if (quickLifecycleSnapshotAuditCopiedAt === null) {
      return null;
    }

    const elapsedSeconds = Math.floor((Date.now() - quickLifecycleSnapshotAuditCopiedAt) / 1000);
    if (elapsedSeconds < 0 || elapsedSeconds >= 6) {
      return null;
    }

    return `Copied quick lifecycle snapshot audit (${elapsedSeconds}s ago): ${lastQuickLifecycleSnapshotAuditCopiedText}`;
  })();

  async function submitNotificationCreateFlow(input?: NotificationCreateFlowInput) {
    const userId = (input?.userIdOverride ?? form.userId).trim();
    const normalizedStatusPrefix = input?.statusPrefix?.trim();

    if (!userId) {
      setStatus("notification_user_id_required");
      return;
    }

    const trimmedNotificationType = form.notificationType.trim();
    if (!trimmedNotificationType) {
      setStatus("notification_type_required");
      return;
    }

    let payloadJson: Record<string, unknown>;
    try {
      const parsedPayload = JSON.parse(form.payloadJson) as unknown;
      if (!parsedPayload || typeof parsedPayload !== "object" || Array.isArray(parsedPayload)) {
        setStatus("notification_payload_json_invalid");
        return;
      }
      payloadJson = parsedPayload as Record<string, unknown>;
    } catch {
      setStatus("notification_payload_json_invalid");
      return;
    }

    setIsCreating(true);
    setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} Creating notification shell item...` : "Creating notification shell item...");

    try {
      const created = await createNotification({
        userId,
        notificationType: trimmedNotificationType,
        payloadJson,
      });

      const createdIsRead = created.read_at !== null;
      let nextMeta = listMeta;
      if (listMeta) {
        nextMeta = {
          ...listMeta,
          count: listMeta.count + 1,
          unread_count: createdIsRead ? listMeta.unread_count : listMeta.unread_count + 1,
          total_unread_count: createdIsRead ? listMeta.total_unread_count : listMeta.total_unread_count + 1,
        };
        setListMeta(nextMeta);
      }

      const createResultDelta: NotificationCreateResultDelta = {
        notificationId: created.id,
        readState: createdIsRead ? "read" : "unread",
        currentPageUnread: nextMeta ? nextMeta.unread_count : null,
        totalUnreadCount: nextMeta ? nextMeta.total_unread_count : null,
      };
      setLastCreateResultDelta(createResultDelta);
      setLastDeleteResultDelta(null);
      setLastLifecyclePair(null);
      setQuickLifecycleSnapshotAuditCopiedAt(null);
      setLastQuickLifecycleSnapshotAuditCopiedText("");

      setForm((current) => ({
        ...current,
        userId,
      }));
      setItems((current) => [created, ...current.filter((item) => item.id !== created.id)]);
      setLastLoadedWindow(null);

      const createdStatus =
        `Created notification ${created.id}. ` +
        `Quick create-result delta: notification_id=${createResultDelta.notificationId} / ` +
        `read_state=${createResultDelta.readState} / ` +
        `current_page_unread=${createResultDelta.currentPageUnread ?? "(none)"} / ` +
        `total_unread_count=${createResultDelta.totalUnreadCount ?? "(none)"}.`;

      if (input?.reloadAfterCreate) {
        await handleLoad(input.loadWindowOverride ?? { userId, offset: 0 }, normalizedStatusPrefix ? `${normalizedStatusPrefix} ${createdStatus}` : createdStatus);
      } else {
        setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} ${createdStatus}` : createdStatus);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "notification_create_failed";
      setStatus(normalizedStatusPrefix ? `${normalizedStatusPrefix} ${errorMessage}` : errorMessage);
    }

    setIsCreating(false);
  }

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await submitNotificationCreateFlow();
  }

  async function applyCurrentSessionUserAndLoad() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_user_missing_for_quick_apply");
      return;
    }

    const userSourceStatus =
      form.userId.trim() === sessionUserId
        ? "User already matches current session user (user_source=session_user)."
        : "Applied current session user (user_source=session_user).";

    setForm((current) => ({
      ...current,
      userId: sessionUserId,
    }));
    setPagination((current) => ({
      ...current,
      offset: 0,
    }));

    await handleLoad(
      {
        userId: sessionUserId,
        offset: 0,
      },
      userSourceStatus,
    );
  }

  async function applyCurrentSessionUserCreateAndLoad() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_user_missing_for_quick_apply");
      return;
    }

    const userSourceStatus =
      form.userId.trim() === sessionUserId
        ? "User already matches current session user (user_source=session_user)."
        : "Applied current session user (user_source=session_user).";

    setForm((current) => ({
      ...current,
      userId: sessionUserId,
    }));
    setPagination((current) => ({
      ...current,
      offset: 0,
    }));

    await submitNotificationCreateFlow({
      userIdOverride: sessionUserId,
      statusPrefix: userSourceStatus,
      reloadAfterCreate: true,
      loadWindowOverride: {
        userId: sessionUserId,
        offset: 0,
      },
    });
  }

  async function toggleRead(item: NotificationItem) {
    setBusyId(item.id);
    setStatus(item.read_at ? "Marking notification unread..." : "Marking notification read...");

    try {
      const updated = item.read_at ? await markNotificationUnread(item.id) : await markNotificationRead(item.id);

      let nextMeta = listMeta;
      if (listMeta) {
        const wasRead = item.read_at !== null;
        const isRead = updated.read_at !== null;
        const unreadDelta = wasRead === isRead ? 0 : isRead ? -1 : 1;

        if (unreadDelta !== 0) {
          nextMeta = {
            ...listMeta,
            unread_count: Math.max(0, listMeta.unread_count + unreadDelta),
            total_unread_count: Math.max(0, listMeta.total_unread_count + unreadDelta),
          };
          setListMeta(nextMeta);
        }
      }

      setItems((current) => current.map((entry) => (entry.id === updated.id ? updated : entry)));
      setLastLoadedWindow(null);
      setLastDeleteResultDelta(null);
      setQuickLifecycleSnapshotAuditCopiedAt(null);
      setLastQuickLifecycleSnapshotAuditCopiedText("");

      const mutationDelta: NotificationMutationDelta = {
        notificationId: updated.id,
        readState: updated.read_at ? "read" : "unread",
        currentPageUnread: nextMeta ? nextMeta.unread_count : null,
        totalUnreadCount: nextMeta ? nextMeta.total_unread_count : null,
      };
      setLastMutationDelta(mutationDelta);
      if (lastCreateResultDelta && lastCreateResultDelta.notificationId === updated.id) {
        setLastLifecyclePair({
          createResult: lastCreateResultDelta,
          mutationDelta,
        });
      } else {
        setLastLifecyclePair(null);
      }

      const mutationDeltaLine =
        `notification_id=${mutationDelta.notificationId} / read_state=${mutationDelta.readState} / ` +
        `current_page_unread=${mutationDelta.currentPageUnread ?? "(none)"} / total_unread_count=${mutationDelta.totalUnreadCount ?? "(none)"}`;
      setStatus(
        `Updated notification ${updated.id} to ${updated.read_at ? "read (●)" : "unread (○)"}. ` +
          `Quick mutation delta: ${mutationDeltaLine}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notification_toggle_failed");
    }

    setBusyId(null);
  }

  async function handleDelete(item: NotificationItem) {
    setDeletingId(item.id);
    setStatus("Deleting notification...");

    try {
      const deleted = await deleteNotification(item.id);
      const currentWindow = lastLoadedWindow ?? currentLoadWindow();
      const wasRead = item.read_at !== null;

      let nextMeta = listMeta;
      if (listMeta) {
        const unreadDelta = wasRead ? 0 : -1;
        nextMeta = {
          ...listMeta,
          count: Math.max(0, listMeta.count - 1),
          unread_count: Math.max(0, listMeta.unread_count + unreadDelta),
          total_unread_count: Math.max(0, listMeta.total_unread_count + unreadDelta),
        };
        setListMeta(nextMeta);
      }

      setItems((current) => current.filter((entry) => entry.id !== deleted.id));
      setLastLoadedWindow(null);
      setLastMutationDelta(null);
      setLastCreateResultDelta((current) => (current && current.notificationId === deleted.id ? null : current));
      setLastLifecyclePair(null);
      setQuickLifecycleSnapshotAuditCopiedAt(null);
      setLastQuickLifecycleSnapshotAuditCopiedText("");

      const deleteResultDelta: NotificationDeleteResultDelta = {
        notificationId: deleted.id,
        previousReadState: wasRead ? "read" : "unread",
        currentPageCount: nextMeta ? nextMeta.count : null,
        currentPageUnread: nextMeta ? nextMeta.unread_count : null,
        totalUnreadCount: nextMeta ? nextMeta.total_unread_count : null,
        window: currentWindow,
      };
      setLastDeleteResultDelta(deleteResultDelta);

      const deleteResultSummaryLine =
        `delete_result=deleted / notification_id=${deleteResultDelta.notificationId} / previous_read_state=${deleteResultDelta.previousReadState} / ` +
        `current_page_count=${deleteResultDelta.currentPageCount ?? "(none)"} / current_page_unread=${deleteResultDelta.currentPageUnread ?? "(none)"} / ` +
        `total_unread_count=${deleteResultDelta.totalUnreadCount ?? "(none)"} / ` +
        `window(limit=${deleteResultDelta.window.limit},offset=${deleteResultDelta.window.offset},filter_mode=${deleteResultDelta.window.unreadOnly ? "unread_only" : "all"})`;

      setStatus(`Deleted notification ${deleted.id}. Quick delete result summary: ${deleteResultSummaryLine}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notification_delete_failed");
    }

    setDeletingId(null);
  }

  async function copyToClipboard(text: string, statusPrefix: string, emptyCode: string, failedCode: string): Promise<boolean> {
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
      setStatus(`${statusPrefix} (${normalizedText}).`);
      return true;
    } catch {
      setStatus(failedCode);
      return false;
    }
  }

  async function handleCopyQuickUnreadSummary() {
    await copyToClipboard(
      quickUnreadSummaryLine,
      "Copied quick unread summary to clipboard",
      "quick_unread_summary_empty",
      "quick_unread_summary_copy_failed",
    );
  }

  async function handleCopyQuickPageMeta() {
    await copyToClipboard(
      quickPageMetaLine,
      "Copied quick page meta to clipboard",
      "quick_page_meta_empty",
      "quick_page_meta_copy_failed",
    );
  }

  async function handleCopyQuickPageCursorSummary() {
    await copyToClipboard(
      quickPageCursorSummaryLine,
      "Copied quick page cursor summary to clipboard",
      "quick_page_cursor_summary_empty",
      "quick_page_cursor_summary_copy_failed",
    );
  }

  async function handleCopyQuickMutationDelta() {
    if (!lastMutationDelta) {
      setStatus("quick_mutation_delta_missing");
      return;
    }

    await copyToClipboard(
      quickMutationDeltaLine,
      "Copied quick mutation delta to clipboard",
      "quick_mutation_delta_missing",
      "quick_mutation_delta_copy_failed",
    );
  }

  async function handleCopyQuickCreateResultDelta() {
    if (!lastCreateResultDelta) {
      setStatus("quick_create_result_delta_missing");
      return;
    }

    await copyToClipboard(
      quickCreateResultDeltaLine,
      "Copied quick create-result delta to clipboard",
      "quick_create_result_delta_missing",
      "quick_create_result_delta_copy_failed",
    );
  }

  async function handleCopyQuickLifecyclePair() {
    if (quickLifecyclePairState === "missing") {
      setStatus("quick_lifecycle_pair_missing");
      return;
    }

    await copyToClipboard(
      quickLifecyclePairLine,
      "Copied quick lifecycle pair to clipboard",
      "quick_lifecycle_pair_missing",
      "quick_lifecycle_pair_copy_failed",
    );
  }

  async function handleCopyQuickLifecyclePairMutation() {
    if (!lifecycleMutationDelta) {
      setStatus("quick_lifecycle_pair_mutation_missing");
      return;
    }

    await copyToClipboard(
      quickLifecyclePairMutationLine,
      "Copied quick lifecycle pair mutation to clipboard",
      "quick_lifecycle_pair_mutation_missing",
      "quick_lifecycle_pair_mutation_copy_failed",
    );
  }

  async function handleCopyQuickUnreadLifecycleMutationBundle() {
    if (!lifecycleMutationDelta) {
      setStatus("quick_unread_lifecycle_mutation_bundle_missing");
      return;
    }

    await copyToClipboard(
      quickUnreadLifecycleMutationBundleLine,
      "Copied quick unread lifecycle mutation bundle to clipboard",
      "quick_unread_lifecycle_mutation_bundle_missing",
      "quick_unread_lifecycle_mutation_bundle_copy_failed",
    );
  }

  async function handleCopyQuickLifecycleSnapshotAudit() {
    if (!lastCreateResultDelta && !lifecycleMutationDelta) {
      setStatus("quick_lifecycle_snapshot_audit_missing");
      return;
    }

    const copied = await copyToClipboard(
      quickLifecycleSnapshotAuditLine,
      "Copied quick lifecycle snapshot audit to clipboard",
      "quick_lifecycle_snapshot_audit_missing",
      "quick_lifecycle_snapshot_audit_copy_failed",
    );

    if (!copied) {
      setLastQuickLifecycleSnapshotAuditCopiedText("");
      setQuickLifecycleSnapshotAuditCopiedAt(null);
      return;
    }

    setLastQuickLifecycleSnapshotAuditCopiedText(quickLifecycleSnapshotAuditLine);
    setQuickLifecycleSnapshotAuditCopiedAt(Date.now());
  }

  async function handleCopyQuickDeleteResultSummary() {
    if (!lastDeleteResultDelta) {
      setStatus("quick_delete_result_summary_missing");
      return;
    }

    await copyToClipboard(
      quickDeleteResultSummaryLine,
      "Copied quick delete result summary to clipboard",
      "quick_delete_result_summary_missing",
      "quick_delete_result_summary_copy_failed",
    );
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> notification shell now wires per-user list plus read/unread state to backend contracts.
      </p>
      <p>{status}</p>
      <p>{pendingWindowHint}</p>
      {notificationErrorHint ? <p>Hint: {notificationErrorHint}</p> : null}
      <p>
        Current session user_id: <code>{currentSessionUserId || "(missing)"}</code>
      </p>
      <p>
        Quick unread summary: <code>{quickUnreadSummaryLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickUnreadSummary()}>
          Copy quick unread summary
        </button>
      </p>
      <p>
        Quick page meta: <code>{quickPageMetaLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickPageMeta()}>
          Copy quick page meta
        </button>
      </p>
      <p>
        Quick page cursor summary: <code>{quickPageCursorSummaryLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickPageCursorSummary()}>
          Copy quick page cursor summary
        </button>
      </p>
      <p>
        Quick mutation delta: <code>{quickMutationDeltaLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickMutationDelta()}>
          Copy quick mutation delta
        </button>
      </p>
      <p>
        Quick create-result delta: <code>{quickCreateResultDeltaLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickCreateResultDelta()}>
          Copy quick create-result delta
        </button>
      </p>
      <p>
        Quick lifecycle pair state: <code>lifecycle_pair_state={quickLifecyclePairState}</code>
      </p>
      <p>
        Quick lifecycle pair subject: <code>lifecycle_pair_subject={lifecyclePairSubject}</code>
      </p>
      <p>
        Quick lifecycle pair transition: <code>{lifecyclePairTransitionText}</code>
      </p>
      <p>
        Quick lifecycle pair transition context: <code>{lifecyclePairTransitionContextText}</code>
      </p>
      <p>
        Quick lifecycle pair: <code>{quickLifecyclePairLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickLifecyclePair()}>
          Copy quick lifecycle pair
        </button>
      </p>
      <p>
        Quick lifecycle pair mutation: <code>{quickLifecyclePairMutationLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickLifecyclePairMutation()}>
          Copy quick lifecycle pair mutation
        </button>
      </p>
      <p>
        Quick unread lifecycle mutation bundle: <code>{quickUnreadLifecycleMutationBundleLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickUnreadLifecycleMutationBundle()}>
          Copy quick unread lifecycle mutation bundle
        </button>
      </p>
      <p>
        Quick lifecycle snapshot audit: <code>{quickLifecycleSnapshotAuditLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickLifecycleSnapshotAudit()}>
          Copy quick lifecycle snapshot audit
        </button>
      </p>
      {quickLifecycleSnapshotAuditCopiedFeedbackText ? <p>{quickLifecycleSnapshotAuditCopiedFeedbackText}</p> : null}
      <p>
        Quick delete result summary: <code>{quickDeleteResultSummaryLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickDeleteResultSummary()}>
          Copy quick delete result summary
        </button>
      </p>
      <p>Filter mode: {pagination.unreadOnly ? "Unread only" : "All notifications"}</p>

      <form onSubmit={(event) => void handleCreate(event)}>
        <label>
          Page limit
          <input
            type="number"
            min={1}
            max={200}
            value={pagination.limit}
            onChange={(event) => {
              const value = Number(event.target.value);
              if (Number.isNaN(value)) {
                return;
              }
              setPagination((current) => ({
                ...current,
                limit: Math.min(200, Math.max(1, value)),
              }));
            }}
          />
        </label>
        <label>
          Page offset
          <input
            type="number"
            min={0}
            value={pagination.offset}
            onChange={(event) => {
              const value = Number(event.target.value);
              if (Number.isNaN(value)) {
                return;
              }
              setPagination((current) => ({
                ...current,
                offset: Math.max(0, value),
              }));
            }}
          />
        </label>
        <div>
          <button
            type="button"
            onClick={() =>
              setPagination((current) => ({
                ...current,
                offset: 0,
              }))
            }
            disabled={pagination.offset === 0}
          >
            First page
          </button>
          <button
            type="button"
            onClick={() =>
              setPagination((current) => ({
                ...current,
                offset: Math.max(0, current.offset - current.limit),
              }))
            }
            disabled={pagination.offset === 0}
          >
            Prev page
          </button>
          <button
            type="button"
            onClick={() =>
              setPagination((current) => ({
                ...current,
                offset: current.offset + current.limit,
              }))
            }
          >
            Next page
          </button>
        </div>
        <label>
          <input
            type="checkbox"
            checked={pagination.unreadOnly}
            onChange={(event) => {
              setPagination((current) => ({
                ...current,
                unreadOnly: event.target.checked,
                offset: 0,
              }));
            }}
          />
          Load unread only
        </label>
        <div>
          <button
            type="button"
            onClick={() => {
              setPagination((current) => ({
                ...current,
                unreadOnly: false,
                offset: 0,
              }));
              setStatus("Preset selected: All notifications. Press Load notifications to refresh this window.");
            }}
            disabled={!pagination.unreadOnly}
          >
            All
          </button>
          <button
            type="button"
            onClick={() => {
              setPagination((current) => ({
                ...current,
                unreadOnly: true,
                offset: 0,
              }));
              setStatus("Preset selected: Unread only. Press Load notifications to refresh this window.");
            }}
            disabled={pagination.unreadOnly}
          >
            Unread only
          </button>
        </div>
        <label>
          User UUID
          <input
            value={form.userId}
            onChange={(event) => {
              const nextUserId = event.target.value;
              const nextTrimmedUserId = nextUserId.trim();

              setForm((current) => ({ ...current, userId: nextUserId }));
              setPagination((current) => {
                const shouldResetOffset = current.offset !== 0 && nextTrimmedUserId !== currentLoadWindow().userId;
                return shouldResetOffset
                  ? {
                      ...current,
                      offset: 0,
                    }
                  : current;
              });
            }}
            placeholder="paste registered user uuid"
          />
        </label>
        <label>
          Notification type
          <input
            value={form.notificationType}
            onChange={(event) => setForm((current) => ({ ...current, notificationType: event.target.value }))}
          />
        </label>
        <label>
          Payload JSON
          <textarea
            value={form.payloadJson}
            onChange={(event) => setForm((current) => ({ ...current, payloadJson: event.target.value }))}
            placeholder='{"message":"Demo notification"}'
          />
        </label>
        <button type="submit" disabled={isCreating}>
          {isCreating ? "Creating..." : "Create notification"}
        </button>
        <button
          type="button"
          onClick={() => void applyCurrentSessionUserCreateAndLoad()}
          disabled={isLoading || isCreating || currentSessionUserId.trim().length === 0}
        >
          Use current session user + create notification + load
        </button>
        <button
          type="button"
          onClick={() => void applyCurrentSessionUserAndLoad()}
          disabled={isLoading || isCreating || currentSessionUserId.trim().length === 0}
        >
          Use current session user + load
        </button>
        <button type="button" onClick={() => void handleLoad()} disabled={isLoading}>
          {isLoading ? "Loading..." : pendingWindowChange ? "Load notifications (window changed)" : "Load notifications"}
        </button>
      </form>

      <h2>Notifications</h2>
      <p>
        Legend: <strong>●</strong> read · <strong>○</strong> unread
      </p>
      {listMeta ? (
        <p>
          Page count: <strong>{listMeta.count}</strong> · Page unread: <strong>{listMeta.unread_count}</strong> · Total unread: <strong>{listMeta.total_unread_count}</strong> · Limit: <strong>{pagination.limit}</strong> · Offset: <strong>{pagination.offset}</strong> · Filter mode: <strong>{pagination.unreadOnly ? "Unread only" : "All notifications"}</strong>
        </p>
      ) : null}
      {items.length === 0 ? (
        <p>No notifications loaded yet.</p>
      ) : (
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              <strong>{item.notification_type}</strong>
              {" · status: "}
              {item.read_at ? "read" : "unread"}
              {" · payload: "}
              {JSON.stringify(item.payload_json)} {" "}
              <button type="button" onClick={() => void toggleRead(item)} disabled={busyId === item.id || deletingId === item.id}>
                {busyId === item.id ? "Saving..." : `${item.read_at ? "●" : "○"} ${item.read_at ? "Mark unread" : "Mark read"}`}
              </button>
              {" "}
              <button type="button" onClick={() => void handleDelete(item)} disabled={busyId === item.id || deletingId === item.id}>
                {deletingId === item.id ? "Deleting..." : "Delete"}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
