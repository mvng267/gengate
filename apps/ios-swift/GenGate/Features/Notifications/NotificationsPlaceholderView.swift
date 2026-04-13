import SwiftUI

struct NotificationsPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userIDDraft: String = ""
    @State private var notificationRows: [NotificationRow] = []
    @State private var mutatingNotificationIDs: Set<String> = []
    @State private var fetchError: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Notifications",
                    summary: "iOS native notification center reader. Use a real user UUID to inspect the current notification list through the same backend contract already exposed on web/backend.",
                    status: "Status: native notification center now supports read/unread mutation for each row; delete remains intentionally out of scope for this slice.",
                    bullets: [
                        "Paste a backend user UUID that already has seeded notifications.",
                        "This shell reads `/notifications/{user_id}` then allows toggling each item via `/notifications/{id}/read` and `/notifications/{id}/unread`.",
                        "Use backend or web tools when you need to create new notifications; use this iOS tab to consume and toggle read state natively."
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
                    .disabled(isLoading || userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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

                    Text("Loaded notifications: \(notificationRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
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
            notificationRows = try await NotificationsAPIClient().fetchNotifications(userID: trimmedUserID)
            mutatingNotificationIDs = []
        } catch {
            notificationRows = []
            mutatingNotificationIDs = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
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

private struct NotificationsAPIClient {
    private struct NotificationListResponse: Decodable {
        let count: Int
        let items: [NotificationResponse]
    }

    private struct NotificationResponse: Decodable {
        let id: String
        let user_id: String
        let notification_type: String
        let payload_json: [String: StringOrIntOrBool]
        let read_at: String?
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

    private let baseURL = URL(string: "http://127.0.0.1:8000")

    func fetchNotifications(userID: String) async throws -> [NotificationRow] {
        let url = try makeURL(path: "/notifications/\(userID)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notifications fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationListResponse.self, from: data)
            return payload.items.map(mapNotification)
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
