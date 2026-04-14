"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createMessageAttachment,
  getOrCreateDirectConversation,
  listConversationMembers,
  listMessageAttachments,
  listMessages,
  sendMessage,
  updateConversationMemberReadCursor,
  type ConversationMemberItem,
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
  const [conversationMembers, setConversationMembers] = useState<ConversationMemberItem[]>([]);
  const [isOpening, setIsOpening] = useState(false);
  const [isReloading, setIsReloading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [isCreatingAttachment, setIsCreatingAttachment] = useState(false);
  const [isLoadingAttachments, setIsLoadingAttachments] = useState(false);
  const [isUpdatingReadCursor, setIsUpdatingReadCursor] = useState(false);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const [readStatusFocusUserIdDraft, setReadStatusFocusUserIdDraft] = useState("");
  const [readCursorTargetUserIdDraft, setReadCursorTargetUserIdDraft] = useState("");
  const [lastSendQuickCopy, setLastSendQuickCopy] = useState("sender=(none) | message_id=(none)");
  const [lastReadCursorQuickCopy, setLastReadCursorQuickCopy] = useState(
    "focus_user=(none) | resolved_message=(none) | read_state=unknown",
  );
  const [lastReadCursorApplyQuickCopy, setLastReadCursorApplyQuickCopy] = useState(
    "target_user=(none) | applied_message=(none) | focus_user=(none) | read_state=unknown",
  );
  const conversationQuickCopy = `user_a=${form.userAId.trim() || "(empty)"} | user_b=${form.userBId.trim() || "(empty)"} | message_count=${messages.length} | last_message_id=${messages[messages.length - 1]?.id ?? "(none)"}`;

  const resolvedReadCursorFocusUserId =
    readStatusFocusUserIdDraft.trim() || form.userAId.trim() || currentSessionUserId.trim() || "";
  const resolvedReadCursorTargetUserId =
    readCursorTargetUserIdDraft.trim() || form.userAId.trim() || currentSessionUserId.trim() || "";
  const resolvedReadCursorMessageId = messages[messages.length - 1]?.id ?? "";

  const focusReadState = (() => {
    if (!resolvedReadCursorFocusUserId || !resolvedReadCursorMessageId) {
      return "unknown";
    }

    const isRead = conversationMembers.some(
      (member) =>
        member.user_id === resolvedReadCursorFocusUserId &&
        member.last_read_message_id === resolvedReadCursorMessageId,
    );

    return isRead ? "read" : "unread";
  })();

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
    setConversationMembers([]);
    setAttachmentForm({ ...initialAttachmentForm });
    setReadStatusFocusUserIdDraft("");
    setReadCursorTargetUserIdDraft("");
    setLastSendQuickCopy("sender=(none) | message_id=(none)");
    setLastReadCursorQuickCopy("focus_user=(none) | resolved_message=(none) | read_state=unknown");
    setLastReadCursorApplyQuickCopy("target_user=(none) | applied_message=(none) | focus_user=(none) | read_state=unknown");
  }, [initialSenderUserId, initialUserAId, initialUserBId]);

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  async function handleOpenThread() {
    setIsOpening(true);
    setStatus("Opening direct thread shell...");
    setLastSendQuickCopy("sender=(none) | message_id=(none)");

    try {
      const nextConversation = await getOrCreateDirectConversation(form.userAId.trim(), form.userBId.trim());
      setConversation(nextConversation);
      const [nextMessages, nextMembers] = await Promise.all([
        listMessages(nextConversation.id),
        listConversationMembers(nextConversation.id),
      ]);
      setMessages(nextMessages);
      setConversationMembers(nextMembers);

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
      const [nextMessages, nextMembers] = await Promise.all([
        listMessages(conversation.id),
        listConversationMembers(conversation.id),
      ]);
      setMessages(nextMessages);
      setConversationMembers(nextMembers);
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
      setLastSendQuickCopy(`sender=${senderUserId || "(empty)"} | message_id=${created.id}`);
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

  useEffect(() => {
    const normalizedFocusUser = resolvedReadCursorFocusUserId || "(none)";
    const normalizedMessageId = resolvedReadCursorMessageId || "(none)";
    setLastReadCursorQuickCopy(
      `focus_user=${normalizedFocusUser} | resolved_message=${normalizedMessageId} | read_state=${focusReadState}`,
    );
  }, [focusReadState, resolvedReadCursorFocusUserId, resolvedReadCursorMessageId]);

  async function copyToClipboard(text: string, statusPrefix: string, emptyCode: string, failedCode: string) {
    const normalizedText = text.trim();
    if (!normalizedText) {
      setStatus(emptyCode);
      return;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      return;
    }

    try {
      await navigator.clipboard.writeText(normalizedText);
      setStatus(`${statusPrefix} (${normalizedText}).`);
    } catch {
      setStatus(failedCode);
    }
  }

  async function handleCopySendResultQuickCopy() {
    await copyToClipboard(
      lastSendQuickCopy,
      "Copied send-result quick copy to clipboard",
      "send_result_quick_copy_empty",
      "send_result_quick_copy_failed",
    );
  }

  function applyCurrentSessionUserAsReadFocusUser() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_focus_user_missing_for_quick_apply");
      return;
    }

    const focusStatus =
      readStatusFocusUserIdDraft.trim() === sessionUserId
        ? "Read focus user already matches current session user (focus_user_source=session_user)."
        : "Applied current session user as read focus user (focus_user_source=session_user).";

    setReadStatusFocusUserIdDraft(sessionUserId);
    setStatus(focusStatus);
  }

  function applyConversationMemberAsReadFocusUser(memberUserId: string) {
    const normalizedMemberUserId = memberUserId.trim();
    if (!normalizedMemberUserId) {
      setStatus("member_focus_user_missing");
      return;
    }

    const focusStatus =
      readStatusFocusUserIdDraft.trim() === normalizedMemberUserId
        ? "Read focus user already matches selected member (focus_user_source=member_row)."
        : "Applied selected member as read focus user (focus_user_source=member_row).";

    setReadStatusFocusUserIdDraft(normalizedMemberUserId);
    setStatus(focusStatus);
  }

  function applyConversationMemberAsReadCursorTargetUser(memberUserId: string) {
    const normalizedMemberUserId = memberUserId.trim();
    if (!normalizedMemberUserId) {
      setStatus("member_read_cursor_target_missing");
      return;
    }

    const targetStatus =
      readCursorTargetUserIdDraft.trim() === normalizedMemberUserId
        ? "Read-cursor target user already matches selected member (read_cursor_user_source=member_row)."
        : "Applied selected member as read-cursor target user (read_cursor_user_source=member_row).";

    setReadCursorTargetUserIdDraft(normalizedMemberUserId);
    setStatus(targetStatus);
  }

  function applyConversationMemberAsReadCursorTargetAndFocusUser(memberUserId: string) {
    const normalizedMemberUserId = memberUserId.trim();
    if (!normalizedMemberUserId) {
      setStatus("member_read_cursor_user_missing_for_quick_apply");
      return;
    }

    const currentTargetUserId = readCursorTargetUserIdDraft.trim();
    const currentFocusUserId = readStatusFocusUserIdDraft.trim();
    const alreadyMatched = currentTargetUserId === normalizedMemberUserId && currentFocusUserId === normalizedMemberUserId;

    setReadCursorTargetUserIdDraft(normalizedMemberUserId);
    setReadStatusFocusUserIdDraft(normalizedMemberUserId);
    setStatus(
      alreadyMatched
        ? "Read-cursor target + read focus already match selected member (read_cursor_user_source=member_row)."
        : "Applied selected member as read-cursor target + read focus (read_cursor_user_source=member_row).",
    );
  }

  function applyCurrentSessionUserForReadCursorAndFocus() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_read_cursor_user_missing_for_quick_apply");
      return;
    }

    setReadCursorTargetUserIdDraft(sessionUserId);
    setReadStatusFocusUserIdDraft(sessionUserId);

    const bothAlreadyMatch =
      readCursorTargetUserIdDraft.trim() === sessionUserId && readStatusFocusUserIdDraft.trim() === sessionUserId;

    setStatus(
      bothAlreadyMatch
        ? "Read-cursor target + read focus already match current session user (read_cursor_user_source=session_user)."
        : "Applied current session user as read-cursor target + read focus (read_cursor_user_source=session_user).",
    );
  }

  async function handleMarkLatestMessageAsReadForResolvedTargetUser() {
    if (!conversation) {
      setStatus("open_thread_first");
      return;
    }

    const targetUserId = resolvedReadCursorTargetUserId.trim();
    if (!targetUserId) {
      setStatus("read_cursor_target_user_required");
      return;
    }

    const latestMessageId = messages[messages.length - 1]?.id ?? "";
    if (!latestMessageId) {
      setStatus("read_cursor_target_message_required");
      return;
    }

    setIsUpdatingReadCursor(true);
    setStatus(`Updating read cursor for ${targetUserId} to latest message ${latestMessageId}...`);

    try {
      const updated = await updateConversationMemberReadCursor({
        conversationId: conversation.id,
        userId: targetUserId,
        lastReadMessageId: latestMessageId,
      });

      const nextMembers = conversationMembers.map((member) => (member.id === updated.id ? updated : member));
      setConversationMembers(nextMembers);

      const normalizedFocusUserId = resolvedReadCursorFocusUserId.trim();
      const normalizedAppliedMessageId = updated.last_read_message_id ?? "(none)";

      let appliedReadState = "unknown";
      if (normalizedFocusUserId && updated.last_read_message_id) {
        const isRead = nextMembers.some(
          (member) =>
            member.user_id === normalizedFocusUserId && member.last_read_message_id === updated.last_read_message_id,
        );
        appliedReadState = isRead ? "read" : "unread";
      }

      setLastReadCursorApplyQuickCopy(
        `target_user=${updated.user_id} | applied_message=${normalizedAppliedMessageId} | focus_user=${normalizedFocusUserId || "(none)"} | read_state=${appliedReadState}`,
      );

      setStatus(
        `Updated read cursor for ${updated.user_id} to ${updated.last_read_message_id ?? "(none)"} in thread ${conversation.id}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "conversation_member_read_cursor_update_failed");
    }

    setIsUpdatingReadCursor(false);
  }

  async function handleCopyReadCursorQuickCopy() {
    await copyToClipboard(
      lastReadCursorQuickCopy,
      "Copied read-cursor quick copy to clipboard",
      "read_cursor_quick_copy_empty",
      "read_cursor_quick_copy_failed",
    );
  }

  async function handleCopyReadCursorApplyQuickCopy() {
    await copyToClipboard(
      lastReadCursorApplyQuickCopy,
      "Copied read-cursor apply quick copy to clipboard",
      "read_cursor_apply_quick_copy_empty",
      "read_cursor_apply_quick_copy_failed",
    );
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
      <p>
        Quick copy send result: <code>{lastSendQuickCopy}</code>
      </p>
      <button type="button" onClick={() => void handleCopySendResultQuickCopy()}>
        Copy quick send result
      </button>
      <p>
        Quick copy read cursor: <code>{lastReadCursorQuickCopy}</code>
      </p>
      <button type="button" onClick={() => void handleCopyReadCursorQuickCopy()}>
        Copy quick read cursor
      </button>
      <p>
        Quick copy read-cursor apply result: <code>{lastReadCursorApplyQuickCopy}</code>
      </p>
      <button type="button" onClick={() => void handleCopyReadCursorApplyQuickCopy()}>
        Copy quick read-cursor apply result
      </button>

      <div>
        <label>
          Read-status focus user UUID (optional, defaults to User A/session user)
          <input
            value={readStatusFocusUserIdDraft}
            onChange={(event) => setReadStatusFocusUserIdDraft(event.target.value)}
            placeholder="focus user for read-state summary"
          />
        </label>
        <button
          type="button"
          onClick={() => applyCurrentSessionUserAsReadFocusUser()}
          disabled={currentSessionUserId.trim().length === 0}
        >
          Use current session user as read focus user
        </button>
      </div>

      <div>
        <label>
          Read-cursor target user UUID (optional, defaults to User A/session user)
          <input
            value={readCursorTargetUserIdDraft}
            onChange={(event) => setReadCursorTargetUserIdDraft(event.target.value)}
            placeholder="target user for read-cursor update"
          />
        </label>
        <button
          type="button"
          onClick={() => applyCurrentSessionUserForReadCursorAndFocus()}
          disabled={currentSessionUserId.trim().length === 0}
        >
          Use current session user for read-cursor target + read focus
        </button>
        <button
          type="button"
          onClick={() => void handleMarkLatestMessageAsReadForResolvedTargetUser()}
          disabled={isUpdatingReadCursor || !conversation || messages.length === 0}
        >
          {isUpdatingReadCursor ? "Marking latest as read..." : "Mark latest message as read (target user)"}
        </button>
      </div>

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

      <h2>Conversation members</h2>
      {conversationMembers.length === 0 ? (
        <p>No conversation members loaded yet.</p>
      ) : (
        <ul>
          {conversationMembers.map((member) => (
            <li key={member.id}>
              <strong>{member.user_id}</strong>
              {" · last_read_message_id: "}
              <code>{member.last_read_message_id ?? "(none)"}</code>
              {resolvedReadCursorTargetUserId === member.user_id ? <span>{" · read_cursor_target"}</span> : null}
              {resolvedReadCursorFocusUserId === member.user_id ? <span>{" · read_focus"}</span> : null}
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                <button type="button" onClick={() => applyConversationMemberAsReadFocusUser(member.user_id)}>
                  Use member as read focus user
                </button>
                <button type="button" onClick={() => applyConversationMemberAsReadCursorTargetUser(member.user_id)}>
                  Use member as read-cursor target user
                </button>
                <button type="button" onClick={() => applyConversationMemberAsReadCursorTargetAndFocusUser(member.user_id)}>
                  Use member as read-cursor target + read focus
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}

      <h2>Messages</h2>
      {messages.length === 0 ? (
        <p>No thread messages loaded yet.</p>
      ) : (
        <ul>
          {messages.map((message) => {
            const readCursorOwners = conversationMembers
              .filter((member) => member.last_read_message_id === message.id)
              .map((member) => member.user_id);

            return (
              <li key={message.id}>
                <strong>{message.payload_text}</strong>
                {" · sender: "}
                {message.sender_user_id}
                {" · id: "}
                <code>{message.id}</code>
                {readCursorOwners.length > 0 ? <span>{` · last_read_by: ${readCursorOwners.join(", ")}`}</span> : null}
                {resolvedReadCursorMessageId === message.id && resolvedReadCursorFocusUserId ? (
                  <span>{` · read_status(${resolvedReadCursorFocusUserId}): ${focusReadState}`}</span>
                ) : null}
              </li>
            );
          })}
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
