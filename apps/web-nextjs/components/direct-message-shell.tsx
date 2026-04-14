"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createMessageAttachment,
  getOrCreateDirectConversation,
  listMessageAttachments,
  listMessages,
  sendMessage,
  type DirectConversation,
  type MessageAttachmentItem,
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

const initialAttachmentForm = {
  targetMessageId: "",
  attachmentType: "image",
  encryptedAttachmentBlob: "demo-encrypted-image-blob",
  storageKey: "attachments/web-shell/demo-image.enc",
};

export function DirectMessageShell({ initialUserAId = "", initialUserBId = "", initialSenderUserId = "" }: DirectMessageShellProps) {
  const [form, setForm] = useState({
    ...initialForm,
    userAId: initialUserAId,
    userBId: initialUserBId,
    senderUserId: initialSenderUserId || initialUserAId,
  });
  const [attachmentForm, setAttachmentForm] = useState({
    ...initialAttachmentForm,
  });
  const [status, setStatus] = useState(
    "Provide two registered user UUIDs to open a direct thread, then send a text message from one member.",
  );
  const [conversation, setConversation] = useState<DirectConversation | null>(null);
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [attachmentItems, setAttachmentItems] = useState<MessageAttachmentItem[]>([]);
  const [isOpening, setIsOpening] = useState(false);
  const [isReloading, setIsReloading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [isCreatingAttachment, setIsCreatingAttachment] = useState(false);
  const [isLoadingAttachments, setIsLoadingAttachments] = useState(false);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const conversationQuickCopy = `user_a=${form.userAId.trim() || "(empty)"} | user_b=${form.userBId.trim() || "(empty)"} | message_count=${messages.length} | last_message_id=${messages[messages.length - 1]?.id ?? "(none)"}`;

  useEffect(() => {
    setForm((current) => ({
      ...current,
      userAId: initialUserAId,
      userBId: initialUserBId,
      senderUserId: initialSenderUserId || initialUserAId,
    }));
    setConversation(null);
    setMessages([]);
    setAttachmentItems([]);
    setAttachmentForm({ ...initialAttachmentForm });
  }, [initialSenderUserId, initialUserAId, initialUserBId]);

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  async function handleOpenThread() {
    setIsOpening(true);
    setStatus("Opening direct thread shell...");

    try {
      const nextConversation = await getOrCreateDirectConversation(form.userAId.trim(), form.userBId.trim());
      setConversation(nextConversation);
      const nextMessages = await listMessages(nextConversation.id);
      setMessages(nextMessages);

      const firstMessageId = nextMessages[0]?.id ?? "";
      if (firstMessageId) {
        const nextAttachments = await listMessageAttachments(firstMessageId);
        setAttachmentItems(nextAttachments);
        setAttachmentForm((current) => ({ ...current, targetMessageId: firstMessageId }));
      } else {
        setAttachmentItems([]);
        setAttachmentForm((current) => ({ ...current, targetMessageId: "" }));
      }

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
      const firstMessageId = nextMessages[0]?.id ?? "";
      setAttachmentForm((current) => ({ ...current, targetMessageId: current.targetMessageId || firstMessageId }));
      setStatus(`Reloaded ${nextMessages.length} message(s) for thread ${conversation.id}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_list_failed");
    }

    setIsReloading(false);
  }

  async function handleSendMessage(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await sendMessageWithCurrentSender();
  }

  async function applyCurrentSessionUserAsSenderAndSend() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_sender_missing_for_quick_apply");
      return;
    }

    if (!conversation) {
      setStatus("open_thread_first");
      return;
    }

    const senderStatus =
      form.senderUserId.trim() === sessionUserId
        ? "Sender already matches current session user (sender_source=session_user)."
        : "Applied current session user as sender (sender_source=session_user).";

    setForm((current) => ({
      ...current,
      senderUserId: sessionUserId,
    }));

    setStatus(`${senderStatus} Sending direct message shell...`);
    await sendMessageWithCurrentSender({ senderUserIdOverride: sessionUserId, statusPrefix: senderStatus });
  }

  async function sendMessageWithCurrentSender(input?: { senderUserIdOverride?: string; statusPrefix?: string }) {
    if (!conversation) {
      setStatus("open_thread_first");
      return;
    }

    const senderUserId = input?.senderUserIdOverride ?? form.senderUserId.trim();
    const statusPrefix = input?.statusPrefix?.trim();

    setIsSending(true);
    setStatus(statusPrefix ? `${statusPrefix} Sending direct message shell...` : "Sending direct message shell...");

    try {
      const created = await sendMessage({
        conversationId: conversation.id,
        senderUserId,
        payloadText: form.payloadText.trim(),
      });
      setMessages((current) => [created, ...current]);
      setAttachmentForm((current) => ({ ...current, targetMessageId: current.targetMessageId || created.id }));
      setForm((current) => ({ ...current, payloadText: "" }));
      const sentStatus = `Sent message ${created.id} into direct thread ${conversation.id}.`;
      setStatus(statusPrefix ? `${statusPrefix} ${sentStatus}` : sentStatus);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_create_failed");
    }

    setIsSending(false);
  }

  async function handleCreateAttachment(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const targetMessageId = attachmentForm.targetMessageId.trim();
    if (!targetMessageId) {
      setStatus("attachment_target_message_required");
      return;
    }

    setIsCreatingAttachment(true);
    setStatus(`Creating attachment for message ${targetMessageId}...`);

    try {
      const created = await createMessageAttachment({
        messageId: targetMessageId,
        attachmentType: attachmentForm.attachmentType.trim(),
        encryptedAttachmentBlob: attachmentForm.encryptedAttachmentBlob.trim(),
        storageKey: attachmentForm.storageKey.trim(),
      });

      setAttachmentItems((current) => [created, ...current.filter((item) => item.id !== created.id)]);
      setStatus(`Created attachment ${created.id} for message ${targetMessageId}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_attachment_create_failed");
    }

    setIsCreatingAttachment(false);
  }

  async function handleLoadAttachments() {
    const targetMessageId = attachmentForm.targetMessageId.trim();
    if (!targetMessageId) {
      setStatus("attachment_target_message_required");
      return;
    }

    setIsLoadingAttachments(true);
    setStatus(`Loading attachments for message ${targetMessageId}...`);

    try {
      const nextItems = await listMessageAttachments(targetMessageId);
      setAttachmentItems(nextItems);
      setStatus(`Loaded ${nextItems.length} attachment(s) for message ${targetMessageId}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "message_attachment_list_failed");
    }

    setIsLoadingAttachments(false);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> direct messaging shell wires direct thread open/create, text send/list, and image attachment create/list.
      </p>
      <p>{status}</p>
      <p>
        Quick copy conversation: <code>{conversationQuickCopy}</code>
      </p>

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
        <button
          type="button"
          onClick={() => void applyCurrentSessionUserAsSenderAndSend()}
          disabled={isSending || !conversation || currentSessionUserId.trim().length === 0}
        >
          Use current session user as sender + send
        </button>
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
              {" · id: "}
              <code>{message.id}</code>
            </li>
          ))}
        </ul>
      )}

      <h2>Message attachments</h2>
      <form onSubmit={(event) => void handleCreateAttachment(event)} style={{ display: "grid", gap: 8, maxWidth: 760 }}>
        <label>
          Target message UUID
          <input
            value={attachmentForm.targetMessageId}
            onChange={(event) => setAttachmentForm((current) => ({ ...current, targetMessageId: event.target.value }))}
            placeholder="paste message id from list above"
          />
        </label>
        <label>
          Attachment type
          <input
            value={attachmentForm.attachmentType}
            onChange={(event) => setAttachmentForm((current) => ({ ...current, attachmentType: event.target.value }))}
            placeholder="image"
          />
        </label>
        <label>
          Encrypted attachment blob
          <textarea
            value={attachmentForm.encryptedAttachmentBlob}
            onChange={(event) => setAttachmentForm((current) => ({ ...current, encryptedAttachmentBlob: event.target.value }))}
            placeholder="encrypted attachment payload"
          />
        </label>
        <label>
          Storage key (optional)
          <input
            value={attachmentForm.storageKey}
            onChange={(event) => setAttachmentForm((current) => ({ ...current, storageKey: event.target.value }))}
            placeholder="attachments/thread/image1.enc"
          />
        </label>
        <div style={{ display: "flex", gap: 8 }}>
          <button type="submit" disabled={isCreatingAttachment}>
            {isCreatingAttachment ? "Creating..." : "Create attachment"}
          </button>
          <button type="button" onClick={() => void handleLoadAttachments()} disabled={isLoadingAttachments}>
            {isLoadingAttachments ? "Loading..." : "Load attachments"}
          </button>
        </div>
      </form>

      {attachmentItems.length === 0 ? (
        <p>No message attachments loaded yet.</p>
      ) : (
        <ul>
          {attachmentItems.map((attachment) => (
            <li key={attachment.id}>
              <strong>{attachment.attachment_type}</strong>
              {" · storage: "}
              {attachment.storage_key ?? "(none)"}
              {" · message: "}
              <code>{attachment.message_id}</code>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
