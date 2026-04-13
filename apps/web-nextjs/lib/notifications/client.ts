import { apiRequest } from "@/lib/api/client";

export type NotificationItem = {
  id: string;
  user_id: string;
  notification_type: string;
  payload_json: Record<string, unknown>;
  read_at: string | null;
};

export async function listNotifications(userId: string): Promise<NotificationItem[]> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(userId)}`);
  if (!response.ok) {
    throw new Error(`notifications_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: NotificationItem[];
  };

  return payload.items;
}

export async function createNotification(input: {
  userId: string;
  notificationType: string;
  payloadJson: Record<string, unknown>;
}): Promise<NotificationItem> {
  const response = await apiRequest("/notifications", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      user_id: input.userId,
      notification_type: input.notificationType,
      payload_json: input.payloadJson,
    }),
  });

  if (!response.ok) {
    throw new Error(`notification_create_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}

export async function markNotificationRead(notificationId: string): Promise<NotificationItem> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(notificationId)}/read`, {
    method: "PATCH",
  });
  if (!response.ok) {
    throw new Error(`notification_mark_read_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}

export async function markNotificationUnread(notificationId: string): Promise<NotificationItem> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(notificationId)}/unread`, {
    method: "PATCH",
  });
  if (!response.ok) {
    throw new Error(`notification_mark_unread_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}
