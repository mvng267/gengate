"use client";

import { useEffect, useState } from "react";

import {
  getOrCreateDirectConversation,
  listMessages,
  sendMessage,
  type DirectConversation,
  type MessageItem,
} from "@/lib/inbox/client";

type DirectMessageShellProps = {
  initialUserAId?: string;
  initialUserBId?: string;
  initialSenderUserId?: string;
};

const initialForm = {
  userAId: "",
  userBId: "",
  senderUserId: "",
  payloadText: "",
};

export function DirectMessageShell({ initialUserAId = "", initialUserBId = "", initialSenderUserId = "" }: DirectMessageShellProps) {
  const [form, setForm] = useState({
    ...initialForm,
    userAId: initialUserAId,
    userBId: initialUserBId,
    senderUserId: initialSenderUserId || initialUserAId,
  });
  const [status, setStatus] = useState(
    "Provide two registered user UUIDs to open a direct thread, then send a text message from one member.",
  );
  const [conversation, setConversation] = useState<DirectConversation | null>(null);
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [isOpening, setIsOpening] = useState(false);
  const [isReloading, setIsReloading] = useState(false);
  const [isSending, setIsSending] = useState(false);

  useEffect(() => {
    setForm((current) => ({
      ...current,
      userAId: initialUserAId,
      userBId: initialUserBId,
      senderUserId: initialSenderUserId || initialUserAId,
    }));
    setConversation(null);
    setMessages([]);
  }, [initialSenderUserId, initialUserAId, initialUserBId]);

  async function handleOpenThread() {
    setIsOpening(true);
    setStatus("Opening direct thread shell...");

    try {
      const nextConversation = await getOrCreateDirectConversation(form.userAId.trim(), form.userBId.trim());
      setConversation(nextConversation);
      const nextMessages = await listMessages(nextConversation.id);
      setMessages(nextMessages);
      setStatus(`Loaded direct thread ${nextConversation.id} with ${nextMessages.length} message(s).`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "direct_conversation_failed");
    }

    setIsOpening(false);
  }

  async function handleReloadMessages() {
    if (!conversation) {
      setStatus("open_thread_first");
      return;
    }

    setIsReloading(true);
    setStatus("Reloading direct thread messages...");

    try {
      const nextMessages = await listMessages(conversation.id);
      setMessages(nextMessages);
      setStatus(`Reloaded ${nextMessages.length} message(s) for thread ${conversation.id}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_list_failed");
    }

    setIsReloading(false);
  }

  async function handleSendMessage(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!conversation) {
      setStatus("open_thread_first");
      return;
    }

    setIsSending(true);
    setStatus("Sending direct message shell...");

    try {
      const created = await sendMessage({
        conversationId: conversation.id,
        senderUserId: form.senderUserId.trim(),
        payloadText: form.payloadText.trim(),
      });
      setMessages((current) => [...current, created]);
      setForm((current) => ({ ...current, payloadText: "" }));
      setStatus(`Sent message ${created.id} into direct thread ${conversation.id}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_create_failed");
    }

    setIsSending(false);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> direct messaging shell now wires 1:1 thread open/create plus text send/list to backend contracts.
      </p>
      <p>{status}</p>

      <div>
        <label>
          User A UUID
          <input
            value={form.userAId}
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                userAId: event.target.value,
                senderUserId: current.senderUserId || event.target.value,
              }))
            }
            placeholder="paste first user uuid"
          />
        </label>
        <label>
          User B UUID
          <input
            value={form.userBId}
            onChange={(event) => setForm((current) => ({ ...current, userBId: event.target.value }))}
            placeholder="paste second user uuid"
          />
        </label>
        <button type="button" onClick={() => void handleOpenThread()} disabled={isOpening}>
          {isOpening ? "Opening..." : "Open direct thread"}
        </button>
        <button type="button" onClick={() => void handleReloadMessages()} disabled={isReloading || !conversation}>
          {isReloading ? "Reloading..." : "Reload thread messages"}
        </button>
      </div>

      <form onSubmit={(event) => void handleSendMessage(event)}>
        <label>
          Sender user UUID
          <input
            value={form.senderUserId}
            onChange={(event) => setForm((current) => ({ ...current, senderUserId: event.target.value }))}
            placeholder="must match one thread member"
          />
        </label>
        <label>
          Message text
          <textarea
            value={form.payloadText}
            onChange={(event) => setForm((current) => ({ ...current, payloadText: event.target.value }))}
            placeholder="type a direct message"
          />
        </label>
        <button type="submit" disabled={isSending || !conversation}>
          {isSending ? "Sending..." : "Send text message"}
        </button>
      </form>

      <h2>Current thread</h2>
      {!conversation ? (
        <p>No direct thread opened yet.</p>
      ) : (
        <ul>
          <li>
            <strong>{conversation.id}</strong>
            {" · type: "}
            {conversation.conversation_type}
            {" · members: "}
            {conversation.member_user_ids.join(", ")}
          </li>
        </ul>
      )}

      <h2>Messages</h2>
      {messages.length === 0 ? (
        <p>No thread messages loaded yet.</p>
      ) : (
        <ul>
          {messages.map((message) => (
            <li key={message.id}>
              <strong>{message.payload_text}</strong>
              {" · sender: "}
              {message.sender_user_id}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
