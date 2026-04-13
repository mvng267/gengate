import { apiRequest } from "@/lib/api/client";

export type DirectConversation = {
  id: string;
  conversation_type: string;
  member_user_ids: string[];
};

export type MessageItem = {
  id: string;
  conversation_id: string;
  sender_user_id: string;
  payload_text: string;
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
