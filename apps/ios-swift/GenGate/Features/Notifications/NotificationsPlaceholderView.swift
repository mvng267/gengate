import SwiftUI

struct NotificationsPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userIDDraft: String = ""
    @State private var createTypeDraft: String = "ios_shell_notice"
    @State private var createPayloadDraft: String = "hello from ios notifications shell"
    @State private var notificationRows: [NotificationRow] = []
    @State private var listMeta: NotificationListMeta?
    @State private var mutatingNotificationIDs: Set<String> = []
    @State private var fetchError: String?
    @State private var statusMessage: String?
    @State private var isLoading = false
    @State private var isCreatingNotification = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Notifications",
                    summary: "iOS native notification center shell now supports create + read/unread mutation so notification flow can be exercised end-to-end from native UI.",
                    status: "Status: native notification center now supports create + read/unread toggles; delete remains intentionally out of scope for this slice.",
                    bullets: [
                        "Paste a backend user UUID to create and load notifications for that user.",
                        "This shell can create via `POST /notifications`, then read `/notifications/{user_id}` and toggle each row via `/notifications/{id}/read` + `/notifications/{id}/unread`.",
                        "Use this tab to run minimal notification lifecycle checks from iOS without relying on web seeding first."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification center reader")
                        .font(.headline)

                    TextField("User UUID", text: $userIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Use current session user") {
                        fillFromCurrentSessionUser()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button {
                        Task {
                            await loadNotifications()
                        }
                    } label: {
                        Text(isLoading ? "Loading notifications..." : "Load notifications")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || isCreatingNotification || userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create notification")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Notification type", text: $createTypeDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Payload message", text: $createPayloadDraft)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await createNotification()
                            }
                        } label: {
                            Text(isCreatingNotification ? "Creating notification..." : "Create notification")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isCreatingNotification ||
                            userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            createTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    if let currentSessionUserID {
                        Text("Current session user_id: \(currentSessionUserID)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text("Loaded notifications: \(notificationRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    if let listMeta {
                        Text("Page count: \(listMeta.count) · Page unread: \(listMeta.unreadCount) · Total unread: \(listMeta.totalUnreadCount)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.headline)

                    if notificationRows.isEmpty {
                        Text("No notifications loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(notificationRows) { row in
                            let isMutating = mutatingNotificationIDs.contains(row.id)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(row.notificationType)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                HStack(spacing: 10) {
                                    Text("read_state: \(row.readState)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: row.isRead ? "checkmark.circle.fill" : "circle")
                                        .font(.footnote)
                                        .foregroundStyle(row.isRead ? .green : .secondary)
                                }

                                Button {
                                    Task {
                                        await toggleReadState(for: row)
                                    }
                                } label: {
                                    Text(isMutating ? "Updating..." : (row.isRead ? "Mark unread" : "Mark read"))
                                }
                                .buttonStyle(.bordered)
                                .disabled(isMutating || isLoading)

                                Text("payload: \(row.payloadSummary)")
                                    .font(.footnote)
                                Text("notification_id: \(row.id)")
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
        .navigationTitle("Notifications")
        .onAppear {
            prefillFromCurrentSessionUserIfNeeded()
        }
    }

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
    }

    private func prefillFromCurrentSessionUserIfNeeded() {
        guard userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        userIDDraft = currentSessionUserID
    }

    private func fillFromCurrentSessionUser() {
        guard let currentSessionUserID else {
            return
        }
        userIDDraft = currentSessionUserID
    }

    private func loadNotifications() async {
        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để load notifications."
            return
        }

        isLoading = true
        fetchError = nil

        do {
            let payload = try await NotificationsAPIClient().fetchNotifications(userID: trimmedUserID)
            notificationRows = payload.items
            listMeta = NotificationListMeta(
                count: payload.count,
                unreadCount: payload.unreadCount,
                totalUnreadCount: payload.totalUnreadCount
            )
            mutatingNotificationIDs = []
            statusMessage = "Loaded \(payload.count) notification(s). Page unread: \(payload.unreadCount). Total unread: \(payload.totalUnreadCount)."
        } catch {
            notificationRows = []
            listMeta = nil
            mutatingNotificationIDs = []
            statusMessage = nil
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func createNotification() async {
        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedType = createTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayload = createPayloadDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để tạo notification."
            return
        }

        guard !trimmedType.isEmpty else {
            fetchError = "Notification type là bắt buộc."
            return
        }

        isCreatingNotification = true
        fetchError = nil

        do {
            let createdRow = try await NotificationsAPIClient().createNotification(
                userID: trimmedUserID,
                notificationType: trimmedType,
                payloadMessage: trimmedPayload.isEmpty ? "sent from ios notifications shell" : trimmedPayload
            )
            statusMessage = "Created notification \(createdRow.id). Reloading list..."
            await loadNotifications()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingNotification = false
    }

    private func toggleReadState(for row: NotificationRow) async {
        guard !mutatingNotificationIDs.contains(row.id) else {
            return
        }

        mutatingNotificationIDs.insert(row.id)
        defer {
            mutatingNotificationIDs.remove(row.id)
        }

        fetchError = nil

        do {
            let updated = try await NotificationsAPIClient().setNotificationReadState(notificationID: row.id, read: !row.isRead)
            if let index = notificationRows.firstIndex(where: { $0.id == updated.id }) {
                notificationRows[index] = updated
            }
            statusMessage = updated.isRead
                ? "Marked notification \(updated.id) as read."
                : "Marked notification \(updated.id) as unread."
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct NotificationRow: Identifiable {
    let id: String
    let notificationType: String
    let payloadSummary: String
    let isRead: Bool

    var readState: String {
        isRead ? "read" : "unread"
    }
}

private struct NotificationListMeta {
    let count: Int
    let unreadCount: Int
    let totalUnreadCount: Int
}

private struct NotificationListPayload {
    let count: Int
    let unreadCount: Int
    let totalUnreadCount: Int
    let items: [NotificationRow]
}

private struct NotificationsAPIClient {
    private struct NotificationListResponse: Decodable {
        let count: Int
        let unread_count: Int?
        let total_unread_count: Int?
        let items: [NotificationResponse]
    }

    private struct NotificationResponse: Decodable {
        let id: String
        let user_id: String
        let notification_type: String
        let payload_json: [String: StringOrIntOrBool]
        let read_at: String?
    }

    private struct NotificationCreateRequest: Encodable {
        let user_id: String
        let notification_type: String
        let payload_json: [String: String]
    }

    private enum StringOrIntOrBool: Decodable, CustomStringConvertible {
        case string(String)
        case int(Int)
        case bool(Bool)
        case double(Double)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else {
                throw DecodingError.typeMismatch(
                    StringOrIntOrBool.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Unsupported payload value type")
                )
            }
        }

        var description: String {
            switch self {
            case let .string(value): return value
            case let .int(value): return String(value)
            case let .bool(value): return value ? "true" : "false"
            case let .double(value): return String(value)
            }
        }
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
                return "Thiếu backend base URL hợp lệ cho notifications shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend notifications response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchNotifications(userID: String) async throws -> NotificationListPayload {
        let url = try makeURL(path: "/notifications/\(userID)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notifications fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationListResponse.self, from: data)
            let mappedRows = payload.items.map(mapNotification)
            let fallbackUnreadCount = mappedRows.filter { !$0.isRead }.count
            let unreadCount = payload.unread_count ?? fallbackUnreadCount

            return NotificationListPayload(
                count: payload.count,
                unreadCount: unreadCount,
                totalUnreadCount: payload.total_unread_count ?? unreadCount,
                items: mappedRows
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createNotification(userID: String, notificationType: String, payloadMessage: String) async throws -> NotificationRow {
        var request = URLRequest(url: try makeURL(path: "/notifications"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            NotificationCreateRequest(
                user_id: userID,
                notification_type: notificationType,
                payload_json: [
                    "source": "ios_notifications_shell",
                    "message": payloadMessage,
                ]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notification create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationResponse.self, from: data)
            return mapNotification(payload)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func setNotificationReadState(notificationID: String, read: Bool) async throws -> NotificationRow {
        let path = read ? "/notifications/\(notificationID)/read" : "/notifications/\(notificationID)/unread"
        var request = URLRequest(url: try makeURL(path: path))
        request.httpMethod = "PATCH"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notification mutation failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationResponse.self, from: data)
            return mapNotification(payload)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func mapNotification(_ payload: NotificationResponse) -> NotificationRow {
        NotificationRow(
            id: payload.id,
            notificationType: payload.notification_type,
            payloadSummary: payload.payload_json
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value.description)" }
                .joined(separator: ", "),
            isRead: payload.read_at != nil
        )
    }

    private func makeURL(path: String) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        return baseURL.appendingPathComponent(path)
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
