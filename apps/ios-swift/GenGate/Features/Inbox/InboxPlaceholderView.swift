import SwiftUI

struct InboxPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userAIDDraft: String = ""
    @State private var userBIDDraft: String = ""
    @State private var conversationSummary: DirectConversationSummary?
    @State private var messageRows: [InboxMessageRow] = []
    @State private var attachmentMap: [String: [InboxAttachmentRow]] = [:]
    @State private var messageDraft: String = ""
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isSendingMessage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Inbox",
                    summary: "iOS native inbox reader. Use two real user UUIDs to resolve a direct conversation and inspect its message list through the same backend contracts already wired for web.",
                    status: "Status: native inbox now supports minimal text sending plus message/attachment reading; device keys and realtime remain pending.",
                    bullets: [
                        "Enter two distinct backend user UUIDs that already participate in a direct conversation or can be resolved into one.",
                        "This shell first calls `/conversations/direct`, then reads `/messages?conversation_id=<uuid>` and per-message `/messages/{id}/attachments`.",
                        "You can now send text messages as User A via `POST /messages` (with resolved conversation id) directly from iOS; attachment upload still relies on web/backend tools."
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

                    TextField("User B UUID", text: $userBIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

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
    }

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
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

    private func loadInboxThread() async {
        let trimmedUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserB = userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserA.isEmpty, !trimmedUserB.isEmpty else {
            fetchError = "Cần đủ hai user UUID để load direct thread."
            return
        }

        isLoading = true
        fetchError = nil

        do {
            let apiClient = InboxAPIClient()
            let directConversation = try await apiClient.resolveDirectConversation(userAID: trimmedUserA, userBID: trimmedUserB)
            let messages = try await apiClient.fetchMessages(conversationID: directConversation.id)
            var nextAttachmentMap: [String: [InboxAttachmentRow]] = [:]
            for message in messages {
                nextAttachmentMap[message.id] = try await apiClient.fetchAttachments(messageID: message.id)
            }
            conversationSummary = directConversation
            messageRows = messages
            attachmentMap = nextAttachmentMap
        } catch {
            conversationSummary = nil
            messageRows = []
            attachmentMap = [:]
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSendingMessage = false
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

private struct InboxAttachmentRow: Identifiable {
    let id: String
    let attachmentType: String
    let storageKey: String?
}

private struct InboxAPIClient {
    private struct DirectConversationResponse: Decodable {
        let id: String
        let conversation_type: String
        let member_user_ids: [String]
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

    private let baseURL = URL(string: "http://127.0.0.1:8000")

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
