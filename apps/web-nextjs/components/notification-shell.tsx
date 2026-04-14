"use client";

import { useEffect, useState } from "react";

import {
  createNotification,
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

type NotificationLoadWindow = {
  userId: string;
  limit: number;
  offset: number;
  unreadOnly: boolean;
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
  const [lastLoadedWindow, setLastLoadedWindow] = useState<NotificationLoadWindow | null>(null);

  useEffect(() => {
    setForm((current) => ({
      ...current,
      userId: initialUserId,
    }));
    setItems([]);
    setListMeta(null);
    setPagination({ limit: 20, offset: 0, unreadOnly: false });
    setLastLoadedWindow(null);
  }, [initialUserId]);

  function currentLoadWindow(overrides?: Partial<NotificationLoadWindow>): NotificationLoadWindow {
    return {
      userId: overrides?.userId ?? form.userId.trim(),
      limit: overrides?.limit ?? pagination.limit,
      offset: overrides?.offset ?? pagination.offset,
      unreadOnly: overrides?.unreadOnly ?? pagination.unreadOnly,
    };
  }

  async function handleLoad(windowOverride?: Partial<NotificationLoadWindow>) {
    const window = currentLoadWindow(windowOverride);

    setIsLoading(true);
    setStatus("Loading notifications...");

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
      setStatus(
        `Loaded ${payload.count} notification(s) for ${window.userId || "unknown-user"}. ` +
          `Page unread: ${payload.unread_count}. Total unread: ${payload.total_unread_count}. ` +
          `Page window limit=${window.limit}, offset=${window.offset}, unread_only=${window.unreadOnly}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notifications_list_failed");
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

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsCreating(true);
    setStatus("Creating notification shell item...");

    try {
      const created = await createNotification({
        userId: form.userId.trim(),
        notificationType: form.notificationType.trim(),
        payloadJson: JSON.parse(form.payloadJson) as Record<string, unknown>,
      });
      setItems((current) => [created, ...current.filter((item) => item.id !== created.id)]);
      setLastLoadedWindow(null);
      setStatus(`Created notification ${created.id}. Reload to refresh unread summary.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notification_create_failed");
    }

    setIsCreating(false);
  }

  async function toggleRead(item: NotificationItem) {
    setBusyId(item.id);
    setStatus(item.read_at ? "Marking notification unread..." : "Marking notification read...");

    try {
      const updated = item.read_at ? await markNotificationUnread(item.id) : await markNotificationRead(item.id);
      setItems((current) => current.map((entry) => (entry.id === updated.id ? updated : entry)));
      setLastLoadedWindow(null);
      setStatus(
        `Updated notification ${updated.id} to ${updated.read_at ? "read (●)" : "unread (○)"}. ` +
          "Reload to refresh unread summary.",
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notification_toggle_failed");
    }

    setBusyId(null);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> notification shell now wires per-user list plus read/unread state to backend contracts.
      </p>
      <p>{status}</p>
      <p>{pendingWindowHint}</p>

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
            onClick={() =>
              setPagination((current) => ({
                ...current,
                unreadOnly: false,
                offset: 0,
              }))
            }
            disabled={!pagination.unreadOnly}
          >
            All
          </button>
          <button
            type="button"
            onClick={() =>
              setPagination((current) => ({
                ...current,
                unreadOnly: true,
                offset: 0,
              }))
            }
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
          onClick={() => {
            const sessionUserId = initialUserId.trim();
            if (!sessionUserId) {
              setStatus("session_user_missing_for_quick_apply");
              return;
            }

            const draftUserId = form.userId.trim();
            if (draftUserId === sessionUserId) {
              setStatus("Session user already selected. Reloading first page for current user.");
            } else {
              setStatus("Applied current session user. Reloading first page.");
            }

            setForm((current) => ({
              ...current,
              userId: sessionUserId,
            }));
            setPagination((current) => ({
              ...current,
              offset: 0,
            }));
            void handleLoad({
              userId: sessionUserId,
              offset: 0,
            });
          }}
          disabled={isLoading || initialUserId.trim().length === 0}
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
          Page count: <strong>{listMeta.count}</strong> · Page unread: <strong>{listMeta.unread_count}</strong> · Total unread: <strong>{listMeta.total_unread_count}</strong> · Limit: <strong>{pagination.limit}</strong> · Offset: <strong>{pagination.offset}</strong> · unread_only: <strong>{String(pagination.unreadOnly)}</strong>
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
              <button type="button" onClick={() => void toggleRead(item)} disabled={busyId === item.id}>
                {busyId === item.id ? "Saving..." : `${item.read_at ? "●" : "○"} ${item.read_at ? "Mark unread" : "Mark read"}`}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
