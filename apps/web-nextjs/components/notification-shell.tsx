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

  useEffect(() => {
    setForm((current) => ({
      ...current,
      userId: initialUserId,
    }));
    setItems([]);
    setListMeta(null);
    setPagination({ limit: 20, offset: 0, unreadOnly: false });
  }, [initialUserId]);

  async function handleLoad() {
    setIsLoading(true);
    setStatus("Loading notifications...");

    try {
      const payload = await listNotifications(form.userId.trim(), {
        limit: pagination.limit,
        offset: pagination.offset,
        unreadOnly: pagination.unreadOnly,
      });
      setItems(payload.items);
      setListMeta({
        count: payload.count,
        unread_count: payload.unread_count,
        total_unread_count: payload.total_unread_count,
      });
      setStatus(
        `Loaded ${payload.count} notification(s) for ${form.userId.trim() || "unknown-user"}. ` +
          `Page unread: ${payload.unread_count}. Total unread: ${payload.total_unread_count}. ` +
          `Page window limit=${pagination.limit}, offset=${pagination.offset}, unread_only=${pagination.unreadOnly}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notifications_list_failed");
    }

    setIsLoading(false);
  }

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
      setStatus(`Updated notification ${updated.id} to ${updated.read_at ? "read" : "unread"}. Reload to refresh unread summary.`);
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
        <label>
          User UUID
          <input
            value={form.userId}
            onChange={(event) => setForm((current) => ({ ...current, userId: event.target.value }))}
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
        <button type="button" onClick={() => void handleLoad()} disabled={isLoading}>
          {isLoading ? "Loading..." : "Load notifications"}
        </button>
      </form>

      <h2>Notifications</h2>
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
                {busyId === item.id ? "Saving..." : item.read_at ? "Mark unread" : "Mark read"}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
