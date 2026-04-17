import { apiRequest } from "@/lib/api/client";

type ApiErrorPayload = {
  detail?: string;
  error?: {
    code?: string;
    message?: string;
  };
};

export type NotificationItem = {
  id: string;
  user_id: string;
  notification_type: string;
  payload_json: Record<string, unknown>;
  read_at: string | null;
};

export type NotificationListPayload = {
  count: number;
  unread_count: number;
  total_unread_count: number;
  items: NotificationItem[];
};

export type NotificationListQuery = {
  limit?: number;
  offset?: number;
  unreadOnly?: boolean;
};

function toNotificationListQueryString(query?: NotificationListQuery): string {
  if (!query) {
    return "";
  }

  const params = new URLSearchParams();
  if (query.limit !== undefined) {
    params.set("limit", String(query.limit));
  }
  if (query.offset !== undefined) {
    params.set("offset", String(query.offset));
  }
  if (query.unreadOnly !== undefined) {
    params.set("unread_only", query.unreadOnly ? "true" : "false");
  }

  const queryString = params.toString();
  return queryString ? `?${queryString}` : "";
}

async function readApiErrorCode(response: Response): Promise<string | null> {
  try {
    const payload = (await response.json()) as ApiErrorPayload;
    const normalizedCode = payload.error?.code?.trim();
    if (normalizedCode) {
      return normalizedCode;
    }

    const normalizedDetail = payload.detail?.trim();
    if (normalizedDetail) {
      return normalizedDetail;
    }

    const normalizedMessage = payload.error?.message?.trim();
    return normalizedMessage || null;
  } catch {
    return null;
  }
}

export async function listNotifications(userId: string, query?: NotificationListQuery): Promise<NotificationListPayload> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(userId)}${toNotificationListQueryString(query)}`);
  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode) {
      throw new Error(errorCode);
    }
    throw new Error(`notifications_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    unread_count?: number;
    total_unread_count?: number;
    items: NotificationItem[];
  };

  const fallbackUnreadCount = payload.items.filter((item) => item.read_at === null).length;
  const unreadCount = payload.unread_count ?? fallbackUnreadCount;

  return {
    count: payload.count,
    unread_count: unreadCount,
    total_unread_count: payload.total_unread_count ?? unreadCount,
    items: payload.items,
  };
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
    const errorCode = await readApiErrorCode(response);
    if (errorCode) {
      throw new Error(errorCode);
    }
    throw new Error(`notification_create_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}

export async function markNotificationRead(notificationId: string): Promise<NotificationItem> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(notificationId)}/read`, {
    method: "PATCH",
  });
  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode) {
      throw new Error(errorCode);
    }
    throw new Error(`notification_mark_read_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}

export async function markNotificationUnread(notificationId: string): Promise<NotificationItem> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(notificationId)}/unread`, {
    method: "PATCH",
  });
  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode) {
      throw new Error(errorCode);
    }
    throw new Error(`notification_mark_unread_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}

export async function deleteNotification(notificationId: string): Promise<NotificationItem> {
  const response = await apiRequest(`/notifications/${encodeURIComponent(notificationId)}`, {
    method: "DELETE",
  });
  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode) {
      throw new Error(errorCode);
    }
    throw new Error(`notification_delete_failed:${response.status}`);
  }

  return (await response.json()) as NotificationItem;
}
