"use client";

import { useState } from "react";

import {
  createNotification,
  listNotifications,
  markNotificationRead,
  markNotificationUnread,
  type NotificationItem,
} from "@/lib/notifications/client";

const initialForm = {
  userId: "",
  notificationType: "friend_request",
  payloadJson: '{"message":"Demo notification"}',
};

export function NotificationShell() {
  const [form, setForm] = useState(initialForm);
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [status, setStatus] = useState("Provide a real user UUID to load notifications or create a minimal notification shell item.");
  const [isLoading, setIsLoading] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function handleLoad() {
    setIsLoading(true);
    setStatus("Loading notifications...");

    try {
      const nextItems = await listNotifications(form.userId.trim());
      setItems(nextItems);
      setStatus(`Loaded ${nextItems.length} notification(s) for ${form.userId.trim() || "unknown-user"}.`);
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
      setStatus(`Created notification ${created.id}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "notification_create_failed");
    }

    setIsCreating(false);
  }

  async function toggleRead(item: NotificationItem) {
    setBusyId(item.id);
    setStatus(item.read_at ? "Marking notification unread..." : "Marking notification read...");

    try {
      const updated = item.read_at
        ? await markNotificationUnread(item.id)
        : await markNotificationRead(item.id);
      setItems((current) => current.map((entry) => (entry.id === updated.id ? updated : entry)));
      setStatus(`Updated notification ${updated.id} to ${updated.read_at ? "read" : "unread"}.`);
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
              {JSON.stringify(item.payload_json)}
              {" "}
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
