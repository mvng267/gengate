import { apiRequest } from "@/lib/api/client";

export type DirectConversation = {
  id: string;
  conversation_type: string;
  member_user_ids: string[];
  latest_message_id: string | null;
  latest_message_sender_user_id: string | null;
  latest_message_preview: string | null;
  latest_message_created_at: string | null;
};

export type MessageItem = {
  id: string;
  conversation_id: string;
  sender_user_id: string;
  payload_text: string;
  deleted_at?: string | null;
};

export type MessageAttachmentItem = {
  id: string;
  message_id: string;
  attachment_type: string;
  encrypted_attachment_blob: string;
  storage_key: string | null;
};

export type ConversationMemberItem = {
  id: string;
  conversation_id: string;
  user_id: string;
  last_read_message_id: string | null;
};

export async function getOrCreateDirectConversation(userAId: string, userBId: string): Promise<DirectConversation> {
  const response = await apiRequest("/conversations/direct", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      user_a_id: userAId,
      user_b_id: userBId,
    }),
  });

  if (!response.ok) {
    throw new Error(`direct_conversation_failed:${response.status}`);
  }

  return (await response.json()) as DirectConversation;
}

export async function listDirectConversationsForUser(userId: string): Promise<DirectConversation[]> {
  const response = await apiRequest(`/conversations/direct?user_id=${encodeURIComponent(userId)}`);
  if (!response.ok) {
    throw new Error(`direct_conversation_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: DirectConversation[];
  };

  return payload.items;
}

export async function listMessages(conversationId: string): Promise<MessageItem[]> {
  const response = await apiRequest(`/messages?conversation_id=${encodeURIComponent(conversationId)}`);
  if (!response.ok) {
    throw new Error(`message_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: MessageItem[];
  };

  return payload.items;
}

export async function listConversationMembers(conversationId: string): Promise<ConversationMemberItem[]> {
  const response = await apiRequest(`/conversations/${encodeURIComponent(conversationId)}/members`);
  if (!response.ok) {
    throw new Error(`conversation_member_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: ConversationMemberItem[];
  };

  return payload.items;
}

export async function updateConversationMemberReadCursor(input: {
  conversationId: string;
  userId: string;
  lastReadMessageId: string;
}): Promise<ConversationMemberItem> {
  const response = await apiRequest(
    `/conversations/${encodeURIComponent(input.conversationId)}/members/${encodeURIComponent(input.userId)}/read-cursor`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
      },
      body: JSON.stringify({
        last_read_message_id: input.lastReadMessageId,
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`conversation_member_read_cursor_update_failed:${response.status}`);
  }

  return (await response.json()) as ConversationMemberItem;
}

export async function sendMessage(input: {
  conversationId: string;
  senderUserId: string;
  payloadText: string;
}): Promise<MessageItem> {
  const response = await apiRequest("/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      conversation_id: input.conversationId,
      sender_user_id: input.senderUserId,
      payload_text: input.payloadText,
    }),
  });

  if (!response.ok) {
    throw new Error(`message_create_failed:${response.status}`);
  }

  return (await response.json()) as MessageItem;
}

export async function deleteMessage(messageId: string): Promise<void> {
  const response = await apiRequest(`/messages/${encodeURIComponent(messageId)}`, {
    method: "DELETE",
  });

  if (!response.ok) {
    throw new Error(`message_delete_failed:${response.status}`);
  }
}

export async function createMessageAttachment(input: {
  messageId: string;
  attachmentType: string;
  encryptedAttachmentBlob: string;
  storageKey?: string;
}): Promise<MessageAttachmentItem> {
  const response = await apiRequest(`/messages/${encodeURIComponent(input.messageId)}/attachments`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      attachment_type: input.attachmentType,
      encrypted_attachment_blob: input.encryptedAttachmentBlob,
      storage_key: input.storageKey ?? null,
    }),
  });

  if (!response.ok) {
    throw new Error(`message_attachment_create_failed:${response.status}`);
  }

  return (await response.json()) as MessageAttachmentItem;
}

export async function listMessageAttachments(messageId: string): Promise<MessageAttachmentItem[]> {
  const response = await apiRequest(`/messages/${encodeURIComponent(messageId)}/attachments`);
  if (!response.ok) {
    throw new Error(`message_attachment_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: MessageAttachmentItem[];
  };

  return payload.items;
}
