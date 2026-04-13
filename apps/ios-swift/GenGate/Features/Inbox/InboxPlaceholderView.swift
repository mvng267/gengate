import SwiftUI

struct InboxPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userAIDDraft: String = ""
    @State private var userBIDDraft: String = ""
    @State private var conversationSummary: DirectConversationSummary?
    @State private var conversationMembers: [InboxConversationMemberRow] = []
    @State private var messageRows: [InboxMessageRow] = []
    @State private var attachmentMap: [String: [InboxAttachmentRow]] = [:]
    @State private var deviceKeyMap: [String: [InboxDeviceKeyRow]] = [:]
    @State private var messageDraft: String = ""
    @State private var attachmentTargetMessageIDDraft: String = ""
    @State private var deviceKeyTargetMessageIDDraft: String = ""
    @State private var readCursorTargetUserIDDraft: String = ""
    @State private var readCursorTargetMessageIDDraft: String = ""
    @State private var readStatusFocusUserIDDraft: String = ""
    @State private var recipientUserIDDraft: String = ""
    @State private var recipientDeviceIDDraft: String = ""
    @State private var recipientDeviceOptions: [InboxDeviceOptionRow] = []
    @State private var isLoadingRecipientDevices = false
    @State private var wrappedMessageKeyBlobDraft: String = "ios-demo-wrapped-message-key"
    @State private var messageToDeleteIDDraft: String = ""
    @State private var attachmentTypeDraft: String = "image"
    @State private var attachmentStorageKeyDraft: String = "attachments/ios-demo-image.enc"
    @State private var attachmentBlobDraft: String = "ios-demo-attachment-blob"
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isSendingMessage = false
    @State private var isCreatingAttachment = false
    @State private var isCreatingDeviceKey = false
    @State private var isUpdatingReadCursor = false
    @State private var isDeletingMessage = false
    @State private var autoRefreshEnabled = false
    @State private var lastCursorFormSyncSummary: String?
    @State private var lastCursorFormSyncAt: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Inbox",
                    summary: "iOS native inbox shell. Use two real user UUIDs to resolve a direct conversation, send text, create attachment/device-key metadata, auto-load recipient devices, and inspect read-cursor/member summary state via the same backend contracts as web.",
                    status: "Status: native inbox now supports text send + attachment create/list + device-key create/list + recipient-device fetch + read-cursor updates + focused read/unread indicator + member cursor summary + quick latest-read action + read-cursor presets + cursor ordering hints + first-unread jump action + row-tap cursor form picker + member-cursor message target picker + cursor-form sync hint with user/message/focus/delete stale-target guards; realtime delivery remains pending.",
                    bullets: [
                        "Enter two distinct backend user UUIDs that already participate in a direct conversation or can be resolved into one.",
                        "This shell calls `/conversations/direct`, `/conversations/{id}/members`, `/messages?conversation_id=<uuid>`, `/messages/{id}/attachments`, `/messages/{id}/device-keys`, and `/auth/devices/{user_id}`.",
                        "You can now call `PATCH /conversations/{id}/members/{user_id}/read-cursor` directly from iOS to move read cursor and observe `last_read_by` + focused `read_status(user)` + member cursor summary in-shell.",
                        "Quick action `Mark latest message as read (focus user)` helps testers advance read cursor to newest loaded row with one tap.",
                        "Quick preset buttons now let testers pick member/message targets without copy-pasting UUIDs manually.",
                        "Member summary now shows cursor ordering hint + unread count behind cursor to spot lagging read state quickly.",
                        "Quick action `Jump focus user to first unread candidate` advances cursor to the earliest unread loaded message for the focus user.",
                        "In member summary, tapping a user row now sets `Read-status focus user UUID` and `Member user UUID` together (no manual paste).",
                        "Each member card now has quick action to copy its `last_read_message_id` into `Last-read message UUID` target.",
                        "Member row tap now applies full read-cursor form context (`Read-status focus user UUID` + `Member user UUID` + optional `Last-read message UUID`).",
                        "Read-cursor form now shows a brief sync hint after row tap so testers can verify which member/context was just applied.",
                        "After thread reload, sync hint refreshes to current read-cursor form values to avoid stale context text.",
                        "When direct-thread identity inputs (User A/User B) change, sync hint is cleared immediately to avoid carry-over across threads.",
                        "If thread load fails and conversation state resets, sync hint is also cleared to keep form context truthful.",
                        "If direct conversation member list comes back empty, sync hint is cleared to avoid implying usable read-cursor context.",
                        "Manual read-cursor target message UUID is now auto-cleared when it no longer exists in loaded message rows (stale target guard).",
                        "Manual read-cursor target user UUID is now auto-cleared when it no longer belongs to current conversation members.",
                        "Manual read-status focus user UUID is now auto-cleared when it no longer belongs to current conversation members.",
                        "Manual delete-target message UUID is now auto-cleared when it no longer exists in loaded message rows."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Direct thread reader")
                        .font(.headline)

                    TextField("User A UUID", text: $userAIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: userAIDDraft) {
                            clearCursorFormSyncHintIfIdentityChanged()
                        }

                    TextField("User B UUID", text: $userBIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: userBIDDraft) {
                            clearCursorFormSyncHintIfIdentityChanged()
                        }

                    Button("Use current session user for User A") {
                        fillUserAFromCurrentSession()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button {
                        Task {
                            await loadInboxThread()
                        }
                    } label: {
                        Text(isLoading ? "Loading inbox thread..." : "Load inbox thread")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Send text message as User A")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Message text", text: $messageDraft)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await sendMessage()
                            }
                        } label: {
                            Text(isSendingMessage ? "Sending message..." : "Send message")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            conversationSummary == nil ||
                            userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create attachment metadata")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Target message UUID (optional, defaults to newest loaded)", text: $attachmentTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Attachment type", text: $attachmentTypeDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Storage key (optional)", text: $attachmentStorageKeyDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Encrypted blob placeholder", text: $attachmentBlobDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await createAttachment()
                            }
                        } label: {
                            Text(isCreatingAttachment ? "Creating attachment..." : "Create attachment")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isDeletingMessage ||
                            isCreatingAttachment ||
                            conversationSummary == nil ||
                            (resolvedAttachmentTargetMessageID?.isEmpty ?? true) ||
                            attachmentTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            attachmentBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create message device key")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Target message UUID (optional, defaults to newest loaded)", text: $deviceKeyTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Recipient user UUID", text: $recipientUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if isLoadingRecipientDevices {
                            Text("Recipient devices: loading...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else if recipientDeviceOptions.isEmpty {
                            Text("Recipient devices: chưa load (nhập Recipient user UUID để fetch `/auth/devices/{user_id}`)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Recipient device", selection: $recipientDeviceIDDraft) {
                                Text("Select recipient device UUID").tag("")
                                ForEach(recipientDeviceOptions) { option in
                                    Text("\(option.deviceName) · \(option.platform) · \(option.deviceTrustState) · \(option.id)")
                                        .tag(option.id)
                                }
                            }
#if os(iOS)
                            .pickerStyle(.menu)
#endif
                        }

                        TextField("Recipient device UUID", text: $recipientDeviceIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Wrapped message key blob", text: $wrappedMessageKeyBlobDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await loadRecipientDevices()
                            }
                        } label: {
                            Text("Reload recipient devices")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button {
                            Task {
                                await createMessageDeviceKey()
                            }
                        } label: {
                            Text(isCreatingDeviceKey ? "Creating device key..." : "Create device key")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isDeletingMessage ||
                            isCreatingDeviceKey ||
                            conversationSummary == nil ||
                            (resolvedDeviceKeyTargetMessageID?.isEmpty ?? true) ||
                            recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            wrappedMessageKeyBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Update read cursor")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if !conversationMembers.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick member presets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(conversationMembers) { member in
                                    Button {
                                        readCursorTargetUserIDDraft = member.userID
                                    } label: {
                                        HStack {
                                            Text(member.userID)
                                                .font(.caption.monospaced())
                                                .lineLimit(1)
                                            Spacer()
                                            if member.userID == resolvedReadCursorTargetUserID {
                                                Text("selected")
                                                    .font(.caption2)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        TextField("Member user UUID (defaults to User A)", text: $readCursorTargetUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !messageRows.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick message presets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(messageRows.suffix(3).reversed()) { message in
                                    Button {
                                        readCursorTargetMessageIDDraft = message.id
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(message.id)
                                                .font(.caption.monospaced())
                                                .lineLimit(1)
                                            Text(message.payloadText)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        TextField("Last-read message UUID (optional, defaults to newest loaded)", text: $readCursorTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Read-status focus user UUID (optional, defaults to User A)", text: $readStatusFocusUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let cursorFormSyncHintText {
                            Text(cursorFormSyncHintText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.blue)
                        }

                        Button {
                            Task {
                                await updateReadCursor()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Updating read cursor..." : "Update read cursor")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadCursorTargetUserID?.isEmpty ?? true) ||
                            (resolvedReadCursorTargetMessageID?.isEmpty ?? true)
                        )

                        Button {
                            Task {
                                await markLatestMessageAsReadForFocusUser()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Marking latest as read..." : "Mark latest message as read (focus user)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadStatusFocusUserID?.isEmpty ?? true) ||
                            (latestLoadedMessageID?.isEmpty ?? true)
                        )

                        Button {
                            Task {
                                await jumpToFirstUnreadCandidateForFocusUser()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Jumping to first unread..." : "Jump focus user to first unread candidate")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (firstUnreadMessageIDForFocusUser?.isEmpty ?? true) ||
                            (resolvedReadStatusFocusUserID?.isEmpty ?? true)
                        )

                        if let firstUnreadMessageIDForFocusUser {
                            Text("first_unread_candidate_message_id: \(firstUnreadMessageIDForFocusUser)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delete message (soft-delete)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Message UUID to delete (optional, defaults to newest loaded)", text: $messageToDeleteIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await deleteMessage()
                            }
                        } label: {
                            Text(isDeletingMessage ? "Deleting message..." : "Delete message")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isUpdatingReadCursor ||
                            isDeletingMessage ||
                            conversationSummary == nil ||
                            (resolvedMessageToDeleteID?.isEmpty ?? true)
                        )
                    }

                    if let currentSessionUserID {
                        Text("Current session user_id: \(currentSessionUserID)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if let conversationSummary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conversation resolved")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("conversation_id: \(conversationSummary.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text("type: \(conversationSummary.conversationType) · members: \(conversationSummary.memberUserIDs.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Loaded messages: \(messageRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Attachment target message_id: \(resolvedAttachmentTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Device-key target message_id: \(resolvedDeviceKeyTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-cursor target user_id: \(resolvedReadCursorTargetUserID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-cursor target message_id: \(resolvedReadCursorTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-status focus user_id: \(resolvedReadStatusFocusUserID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Delete target message_id: \(resolvedMessageToDeleteID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Toggle(isOn: $autoRefreshEnabled) {
                        Text("Auto refresh every 3s")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .toggleStyle(.switch)
                    .disabled(conversationSummary == nil || isLoading)

                    if autoRefreshEnabled {
                        Text("Auto refresh đang bật: inbox sẽ tự reload mỗi 3 giây khi idle.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Member read-cursor summary")
                        .font(.headline)

                    if conversationMembers.isEmpty {
                        Text("No conversation members loaded yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(conversationMembers) { member in
                            let cursorMessageID = member.lastReadMessageID
                            let cursorMessage = messageRows.first(where: { $0.id == cursorMessageID })
                            let isFocusUser = member.userID == resolvedReadStatusFocusUserID
                            let isAtLatest = cursorMessageID != nil && cursorMessageID == latestLoadedMessageID
                            let unreadBehindCount = unreadMessageCountBehindCursor(lastReadMessageID: cursorMessageID)
                            let cursorOrderHint = cursorOrderHintText(lastReadMessageID: cursorMessageID)

                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    readStatusFocusUserIDDraft = member.userID
                                    readCursorTargetUserIDDraft = member.userID

                                    if let cursorMessageID {
                                        readCursorTargetMessageIDDraft = cursorMessageID
                                    }

                                    if let cursorMessageID {
                                        lastCursorFormSyncSummary = "cursor_form_sync: user=\(member.userID) message=\(cursorMessageID)"
                                    } else {
                                        lastCursorFormSyncSummary = "cursor_form_sync: user=\(member.userID) message=(none)"
                                    }
                                    lastCursorFormSyncAt = Date()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("user_id: \(member.userID)")
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)

                                        Spacer()

                                        Text(isFocusUser ? "focus+cursor_form" : "set_focus+cursor_form")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(isFocusUser ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Text("last_read_message_id: \(cursorMessageID ?? "(none)")")
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)

                                if let cursorMessageID {
                                    Button {
                                        readCursorTargetMessageIDDraft = cursorMessageID
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text("Use cursor as message target")
                                                .font(.caption)

                                            Spacer()

                                            Text(resolvedReadCursorTargetMessageID == cursorMessageID ? "message_target_selected" : "set_message_target")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(resolvedReadCursorTargetMessageID == cursorMessageID ? .green : .secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Text("cursor_message_target: unavailable")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }

                                if let cursorMessage {
                                    Text("cursor_payload: \(cursorMessage.payloadText)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Text("cursor_state: \(isAtLatest ? "at_latest" : "behind_or_unknown")")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(isAtLatest ? .green : .orange)

                                Text("cursor_order_hint: \(cursorOrderHint)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)

                                Text("unread_behind_cursor: \(unreadBehindCount)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(unreadBehindCount == 0 ? .green : .orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Messages")
                        .font(.headline)

                    if messageRows.isEmpty {
                        Text("No messages loaded for this direct thread yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(messageRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("sender_user_id: \(row.senderUserID)")
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(row.payloadText)
                                    .font(.footnote)

                                let attachments = attachmentMap[row.id] ?? []
                                Text("attachment_count: \(attachments.count)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let firstAttachment = attachments.first {
                                    Text("first_attachment: \(firstAttachment.attachmentType) · \(firstAttachment.storageKey ?? "(no storage key)")")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                let deviceKeys = deviceKeyMap[row.id] ?? []
                                Text("device_key_count: \(deviceKeys.count)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let firstDeviceKey = deviceKeys.first {
                                    Text("first_device_key: recipient_user=\(firstDeviceKey.recipientUserID) · recipient_device=\(firstDeviceKey.recipientDeviceID)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                let readCursorOwners = conversationMembers
                                    .filter { $0.lastReadMessageID == row.id }
                                    .map(\.userID)

                                if !readCursorOwners.isEmpty {
                                    Text("last_read_by: \(readCursorOwners.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                if row.id == resolvedReadStatusMessageID,
                                   let focusUserID = resolvedReadStatusFocusUserID {
                                    let focusReadState = readCursorOwners.contains(focusUserID) ? "read" : "unread"
                                    let focusReadColor: Color = focusReadState == "read" ? .green : .orange

                                    Text("read_status(\(focusUserID)): \(focusReadState)")
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(focusReadColor)
                                }

                                Text("message_id: \(row.id)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Inbox")
        .onAppear {
            prefillUserAFromCurrentSessionIfNeeded()
        }
        .task(id: autoRefreshEnabled) {
            guard autoRefreshEnabled else {
                return
            }

            while autoRefreshEnabled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)

                if !autoRefreshEnabled {
                    break
                }

                if conversationSummary == nil || isLoading || isMutatingInbox {
                    continue
                }

                await loadInboxThread(silent: true)
            }
        }
    }

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
    }

    private var resolvedAttachmentTargetMessageID: String? {
        let manualMessageID = attachmentTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedDeviceKeyTargetMessageID: String? {
        let manualMessageID = deviceKeyTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedReadCursorTargetUserID: String? {
        let manualUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualUserID.isEmpty {
            return manualUserID
        }

        let fallbackUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallbackUserA.isEmpty {
            return fallbackUserA
        }

        return nil
    }

    private var resolvedReadCursorTargetMessageID: String? {
        let manualMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedMessageToDeleteID: String? {
        let manualMessageID = messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedReadStatusFocusUserID: String? {
        let manualUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualUserID.isEmpty {
            return manualUserID
        }

        let fallbackUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallbackUserA.isEmpty {
            return fallbackUserA
        }

        return nil
    }

    private var resolvedReadStatusMessageID: String? {
        if let targetMessageID = resolvedReadCursorTargetMessageID,
           !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return targetMessageID
        }

        return messageRows.last?.id
    }

    private var latestLoadedMessageID: String? {
        messageRows.last?.id
    }

    private var firstUnreadMessageIDForFocusUser: String? {
        guard let focusUserID = resolvedReadStatusFocusUserID,
              !focusUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let focusMember = conversationMembers.first(where: { $0.userID == focusUserID })
        let cursorMessageID = focusMember?.lastReadMessageID

        guard !messageRows.isEmpty else {
            return nil
        }

        guard let cursorMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == cursorMessageID }) else {
            return messageRows.first?.id
        }

        let unreadIndex = cursorIndex + 1
        guard unreadIndex < messageRows.count else {
            return nil
        }

        return messageRows[unreadIndex].id
    }

    private func unreadMessageCountBehindCursor(lastReadMessageID: String?) -> Int {
        guard let lastReadMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == lastReadMessageID }) else {
            return messageRows.count
        }

        let trailingCount = messageRows.count - cursorIndex - 1
        return max(trailingCount, 0)
    }

    private func cursorOrderHintText(lastReadMessageID: String?) -> String {
        guard let lastReadMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == lastReadMessageID }) else {
            return "unknown"
        }

        return "index \(cursorIndex + 1)/\(messageRows.count)"
    }

    private var isMutatingInbox: Bool {
        isSendingMessage ||
        isCreatingAttachment ||
        isCreatingDeviceKey ||
        isUpdatingReadCursor ||
        isDeletingMessage ||
        isLoadingRecipientDevices
    }

    private var cursorFormSyncHintText: String? {
        guard let lastCursorFormSyncSummary else {
            return nil
        }

        guard let lastCursorFormSyncAt else {
            return lastCursorFormSyncSummary
        }

        let elapsed = Date().timeIntervalSince(lastCursorFormSyncAt)
        guard elapsed <= 15 else {
            return nil
        }

        return "\(lastCursorFormSyncSummary) · \(Int(elapsed))s ago"
    }

    private func prefillUserAFromCurrentSessionIfNeeded() {
        guard userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        userAIDDraft = currentSessionUserID
    }

    private func fillUserAFromCurrentSession() {
        guard let currentSessionUserID else {
            return
        }
        userAIDDraft = currentSessionUserID
    }

    private func clearCursorFormSyncHintIfIdentityChanged() {
        lastCursorFormSyncSummary = nil
        lastCursorFormSyncAt = nil
    }

    private func loadInboxThread(silent: Bool = false) async {
        let trimmedUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserB = userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserA.isEmpty, !trimmedUserB.isEmpty else {
            if !silent {
                fetchError = "Cần đủ hai user UUID để load direct thread."
            }
            return
        }

        isLoading = true
        if !silent {
            fetchError = nil
        }

        do {
            let apiClient = InboxAPIClient()
            let directConversation = try await apiClient.resolveDirectConversation(userAID: trimmedUserA, userBID: trimmedUserB)
            let members = try await apiClient.fetchConversationMembers(conversationID: directConversation.id)
            let messages = try await apiClient.fetchMessages(conversationID: directConversation.id)
            var nextAttachmentMap: [String: [InboxAttachmentRow]] = [:]
            var nextDeviceKeyMap: [String: [InboxDeviceKeyRow]] = [:]
            for message in messages {
                nextAttachmentMap[message.id] = try await apiClient.fetchAttachments(messageID: message.id)
                nextDeviceKeyMap[message.id] = try await apiClient.fetchMessageDeviceKeys(messageID: message.id)
            }
            conversationSummary = directConversation
            conversationMembers = members
            messageRows = messages
            attachmentMap = nextAttachmentMap
            deviceKeyMap = nextDeviceKeyMap

            let manualReadCursorMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadCursorMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualReadCursorMessageID }) {
                readCursorTargetMessageIDDraft = ""
            }

            let manualDeleteMessageID = messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualDeleteMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualDeleteMessageID }) {
                messageToDeleteIDDraft = ""
            }

            let manualReadCursorUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadCursorUserID.isEmpty,
               !members.contains(where: { $0.userID == manualReadCursorUserID }) {
                readCursorTargetUserIDDraft = ""
            }

            let manualReadStatusFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadStatusFocusUserID.isEmpty,
               !members.contains(where: { $0.userID == manualReadStatusFocusUserID }) {
                readStatusFocusUserIDDraft = ""
            }

            if members.isEmpty {
                clearCursorFormSyncHintIfIdentityChanged()
            }

            if let lastCursorFormSyncAt {
                let elapsed = Date().timeIntervalSince(lastCursorFormSyncAt)
                if elapsed > 15 {
                    lastCursorFormSyncSummary = nil
                    self.lastCursorFormSyncAt = nil
                }
            }

            let syncUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            let syncMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !syncUserID.isEmpty, !members.isEmpty {
                if syncMessageID.isEmpty {
                    lastCursorFormSyncSummary = "cursor_form_sync: user=\(syncUserID) message=(auto_or_empty)"
                } else {
                    lastCursorFormSyncSummary = "cursor_form_sync: user=\(syncUserID) message=\(syncMessageID)"
                }
                self.lastCursorFormSyncAt = Date()
            }

            let resolvedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !resolvedRecipientUserID.isEmpty {
                await loadRecipientDevices(silent: true)
            }
        } catch {
            if !silent {
                conversationSummary = nil
                conversationMembers = []
                messageRows = []
                attachmentMap = [:]
                deviceKeyMap = [:]
                recipientDeviceOptions = []
                clearCursorFormSyncHintIfIdentityChanged()
                fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }

        isLoading = false
    }

    private func sendMessage() async {
        let trimmedUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayload = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let conversationID = conversationSummary?.id else {
            fetchError = "Load direct thread trước khi gửi message."
            return
        }

        guard !trimmedUserA.isEmpty else {
            fetchError = "User A UUID là bắt buộc để gửi message."
            return
        }

        guard !trimmedPayload.isEmpty else {
            fetchError = "Message text không được để trống."
            return
        }

        isSendingMessage = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().createMessage(
                conversationID: conversationID,
                senderUserID: trimmedUserA,
                payloadText: trimmedPayload
            )
            messageDraft = ""
            messageToDeleteIDDraft = ""
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSendingMessage = false
    }

    private func createAttachment() async {
        guard let targetMessageID = resolvedAttachmentTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để tạo attachment."
            return
        }

        let trimmedType = attachmentTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStorageKey = attachmentStorageKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBlob = attachmentBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedType.isEmpty else {
            fetchError = "Attachment type là bắt buộc."
            return
        }

        guard !trimmedBlob.isEmpty else {
            fetchError = "Encrypted blob placeholder là bắt buộc."
            return
        }

        isCreatingAttachment = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().createAttachment(
                messageID: targetMessageID,
                attachmentType: trimmedType,
                encryptedAttachmentBlob: trimmedBlob,
                storageKey: trimmedStorageKey.isEmpty ? nil : trimmedStorageKey
            )
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingAttachment = false
    }

    private func createMessageDeviceKey() async {
        guard let targetMessageID = resolvedDeviceKeyTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để tạo device key."
            return
        }

        let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWrappedBlob = wrappedMessageKeyBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientUserID.isEmpty else {
            fetchError = "Recipient user UUID là bắt buộc."
            return
        }

        guard !trimmedRecipientDeviceID.isEmpty else {
            fetchError = "Recipient device UUID là bắt buộc."
            return
        }

        guard !trimmedWrappedBlob.isEmpty else {
            fetchError = "Wrapped message key blob là bắt buộc."
            return
        }

        isCreatingDeviceKey = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().createMessageDeviceKey(
                messageID: targetMessageID,
                recipientUserID: trimmedRecipientUserID,
                recipientDeviceID: trimmedRecipientDeviceID,
                wrappedMessageKeyBlob: trimmedWrappedBlob
            )
            wrappedMessageKeyBlobDraft = "ios-demo-wrapped-message-key"
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingDeviceKey = false
    }

    private func loadRecipientDevices(silent: Bool = false) async {
        let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientUserID.isEmpty else {
            recipientDeviceOptions = []
            recipientDeviceIDDraft = ""
            return
        }

        isLoadingRecipientDevices = true

        defer {
            isLoadingRecipientDevices = false
        }

        do {
            let options = try await InboxAPIClient().fetchDevices(userID: trimmedRecipientUserID)
            recipientDeviceOptions = options
            if options.contains(where: { $0.id == recipientDeviceIDDraft }) == false {
                recipientDeviceIDDraft = options.first?.id ?? ""
            }
        } catch {
            recipientDeviceOptions = []
            recipientDeviceIDDraft = ""
            if !silent {
                fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func updateReadCursor() async {
        guard let targetUserID = resolvedReadCursorTargetUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần member user UUID hợp lệ để cập nhật read cursor."
            return
        }

        guard let targetMessageID = resolvedReadCursorTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để cập nhật read cursor."
            return
        }

        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func markLatestMessageAsReadForFocusUser() async {
        guard let targetUserID = resolvedReadStatusFocusUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần focus user UUID hợp lệ để mark latest message as read."
            return
        }

        guard let targetMessageID = latestLoadedMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Không có message nào để mark as read."
            return
        }

        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func jumpToFirstUnreadCandidateForFocusUser() async {
        guard let targetUserID = resolvedReadStatusFocusUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần focus user UUID hợp lệ để jump first unread."
            return
        }

        guard let targetMessageID = firstUnreadMessageIDForFocusUser,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Không có first unread candidate cho focus user."
            return
        }

        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func performReadCursorUpdate(targetUserID: String, targetMessageID: String) async {
        guard let conversationID = conversationSummary?.id else {
            fetchError = "Load direct thread trước khi cập nhật read cursor."
            return
        }

        isUpdatingReadCursor = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().updateConversationReadCursor(
                conversationID: conversationID,
                userID: targetUserID,
                lastReadMessageID: targetMessageID
            )
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isUpdatingReadCursor = false
    }

    private func deleteMessage() async {
        guard let targetMessageID = resolvedMessageToDeleteID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để delete."
            return
        }

        isDeletingMessage = true
        fetchError = nil

        do {
            try await InboxAPIClient().deleteMessage(messageID: targetMessageID)
            if attachmentTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                attachmentTargetMessageIDDraft = ""
            }
            if deviceKeyTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                deviceKeyTargetMessageIDDraft = ""
            }
            if readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                readCursorTargetMessageIDDraft = ""
            }
            if messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                messageToDeleteIDDraft = ""
            }
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isDeletingMessage = false
    }
}

private struct DirectConversationSummary {
    let id: String
    let conversationType: String
    let memberUserIDs: [String]
}

private struct InboxMessageRow: Identifiable {
    let id: String
    let senderUserID: String
    let payloadText: String
}

private struct InboxConversationMemberRow: Identifiable {
    let id: String
    let conversationID: String
    let userID: String
    let lastReadMessageID: String?
}

private struct InboxAttachmentRow: Identifiable {
    let id: String
    let attachmentType: String
    let storageKey: String?
}

private struct InboxDeviceKeyRow: Identifiable {
    let id: String
    let messageID: String
    let recipientUserID: String
    let recipientDeviceID: String
}

private struct InboxDeviceOptionRow: Identifiable {
    let id: String
    let platform: String
    let deviceName: String
    let deviceTrustState: String
}

private struct InboxAPIClient {
    private struct DirectConversationResponse: Decodable {
        let id: String
        let conversation_type: String
        let member_user_ids: [String]
    }

    private struct ConversationMemberListResponse: Decodable {
        let count: Int
        let items: [ConversationMemberResponse]
    }

    private struct ConversationMemberResponse: Decodable {
        let id: String
        let conversation_id: String
        let user_id: String
        let last_read_message_id: String?
    }

    private struct MessageListResponse: Decodable {
        let count: Int
        let items: [MessageResponse]
    }

    private struct MessageResponse: Decodable {
        let id: String
        let conversation_id: String
        let sender_user_id: String
        let payload_text: String
    }

    private struct MessageCreateRequest: Encodable {
        let sender_user_id: String
        let payload_text: String
        let conversation_id: String
    }

    private struct AttachmentListResponse: Decodable {
        let count: Int
        let items: [AttachmentResponse]
    }

    private struct AttachmentResponse: Decodable {
        let id: String
        let message_id: String
        let attachment_type: String
        let encrypted_attachment_blob: String
        let storage_key: String?
    }

    private struct AttachmentCreateRequest: Encodable {
        let attachment_type: String
        let encrypted_attachment_blob: String
        let storage_key: String?
    }

    private struct MessageDeviceKeyListResponse: Decodable {
        let count: Int
        let items: [MessageDeviceKeyResponse]
    }

    private struct MessageDeviceKeyResponse: Decodable {
        let id: String
        let message_id: String
        let recipient_user_id: String
        let recipient_device_id: String
        let wrapped_message_key_blob: String
    }

    private struct MessageDeviceKeyCreateRequest: Encodable {
        let recipient_user_id: String
        let recipient_device_id: String
        let wrapped_message_key_blob: String
    }

    private struct ConversationReadCursorUpdateRequest: Encodable {
        let last_read_message_id: String
    }

    private struct DeviceListResponse: Decodable {
        let count: Int
        let items: [DeviceResponse]
    }

    private struct DeviceResponse: Decodable {
        let id: String
        let user_id: String
        let platform: String
        let device_name: String
        let device_trust_state: String
    }

    private struct BackendErrorPayload: Decodable {
        let detail: String?
    }

    private enum APIError: LocalizedError {
        case invalidBaseURL
        case requestFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Thiếu backend base URL hợp lệ cho inbox shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend inbox response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func resolveDirectConversation(userAID: String, userBID: String) async throws -> DirectConversationSummary {
        let url = try makeURL(path: "/conversations/direct")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_a_id": userAID,
            "user_b_id": userBID,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Direct conversation resolve failed"))
        }

        do {
            let payload = try JSONDecoder().decode(DirectConversationResponse.self, from: data)
            return DirectConversationSummary(
                id: payload.id,
                conversationType: payload.conversation_type,
                memberUserIDs: payload.member_user_ids
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchConversationMembers(conversationID: String) async throws -> [InboxConversationMemberRow] {
        let url = try makeURL(path: "/conversations/\(conversationID)/members")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Conversation members fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ConversationMemberListResponse.self, from: data)
            return payload.items.map {
                InboxConversationMemberRow(
                    id: $0.id,
                    conversationID: $0.conversation_id,
                    userID: $0.user_id,
                    lastReadMessageID: $0.last_read_message_id
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchMessages(conversationID: String) async throws -> [InboxMessageRow] {
        let url = try makeURL(path: "/messages", queryItems: [URLQueryItem(name: "conversation_id", value: conversationID)])
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageListResponse.self, from: data)
            return payload.items.map {
                InboxMessageRow(
                    id: $0.id,
                    senderUserID: $0.sender_user_id,
                    payloadText: $0.payload_text
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createMessage(conversationID: String, senderUserID: String, payloadText: String) async throws -> InboxMessageRow {
        let url = try makeURL(path: "/messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MessageCreateRequest(
                sender_user_id: senderUserID,
                payload_text: payloadText,
                conversation_id: conversationID
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageResponse.self, from: data)
            return InboxMessageRow(
                id: payload.id,
                senderUserID: payload.sender_user_id,
                payloadText: payload.payload_text
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchAttachments(messageID: String) async throws -> [InboxAttachmentRow] {
        let url = try makeURL(path: "/messages/\(messageID)/attachments")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Attachment list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(AttachmentListResponse.self, from: data)
            return payload.items.map {
                InboxAttachmentRow(
                    id: $0.id,
                    attachmentType: $0.attachment_type,
                    storageKey: $0.storage_key
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchMessageDeviceKeys(messageID: String) async throws -> [InboxDeviceKeyRow] {
        let url = try makeURL(path: "/messages/\(messageID)/device-keys")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message device-key list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageDeviceKeyListResponse.self, from: data)
            return payload.items.map {
                InboxDeviceKeyRow(
                    id: $0.id,
                    messageID: $0.message_id,
                    recipientUserID: $0.recipient_user_id,
                    recipientDeviceID: $0.recipient_device_id
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createMessageDeviceKey(
        messageID: String,
        recipientUserID: String,
        recipientDeviceID: String,
        wrappedMessageKeyBlob: String
    ) async throws -> InboxDeviceKeyRow {
        let url = try makeURL(path: "/messages/\(messageID)/device-keys")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MessageDeviceKeyCreateRequest(
                recipient_user_id: recipientUserID,
                recipient_device_id: recipientDeviceID,
                wrapped_message_key_blob: wrappedMessageKeyBlob
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message device-key create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageDeviceKeyResponse.self, from: data)
            return InboxDeviceKeyRow(
                id: payload.id,
                messageID: payload.message_id,
                recipientUserID: payload.recipient_user_id,
                recipientDeviceID: payload.recipient_device_id
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func updateConversationReadCursor(
        conversationID: String,
        userID: String,
        lastReadMessageID: String
    ) async throws -> InboxConversationMemberRow {
        let url = try makeURL(path: "/conversations/\(conversationID)/members/\(userID)/read-cursor")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ConversationReadCursorUpdateRequest(last_read_message_id: lastReadMessageID)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Read cursor update failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ConversationMemberResponse.self, from: data)
            return InboxConversationMemberRow(
                id: payload.id,
                conversationID: payload.conversation_id,
                userID: payload.user_id,
                lastReadMessageID: payload.last_read_message_id
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchDevices(userID: String) async throws -> [InboxDeviceOptionRow] {
        let url = try makeURL(path: "/auth/devices/\(userID)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Recipient devices fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(DeviceListResponse.self, from: data)
            return payload.items.map {
                InboxDeviceOptionRow(
                    id: $0.id,
                    platform: $0.platform,
                    deviceName: $0.device_name,
                    deviceTrustState: $0.device_trust_state
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func deleteMessage(messageID: String) async throws {
        let url = try makeURL(path: "/messages/\(messageID)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message delete failed"))
        }
    }

    func createAttachment(
        messageID: String,
        attachmentType: String,
        encryptedAttachmentBlob: String,
        storageKey: String?
    ) async throws -> InboxAttachmentRow {
        let url = try makeURL(path: "/messages/\(messageID)/attachments")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AttachmentCreateRequest(
                attachment_type: attachmentType,
                encrypted_attachment_blob: encryptedAttachmentBlob,
                storage_key: storageKey
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Attachment create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(AttachmentResponse.self, from: data)
            return InboxAttachmentRow(
                id: payload.id,
                attachmentType: payload.attachment_type,
                storageKey: payload.storage_key
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw APIError.invalidBaseURL
        }

        return url
    }

    private func requireHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        return httpResponse
    }

    private func readErrorMessage(from data: Data, statusCode: Int, prefix: String) -> String {
        if let payload = try? JSONDecoder().decode(BackendErrorPayload.self, from: data),
           let detail = payload.detail,
           !detail.isEmpty {
            return "\(prefix): \(statusCode) (\(detail))"
        }

        return "\(prefix): \(statusCode)"
    }
}
