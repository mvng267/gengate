import SwiftUI

struct ProfilePlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userIDDraft: String = ""
    @State private var receiverUserIDDraft: String = ""
    @State private var pendingRequestCount: Int?
    @State private var friendshipCount: Int?
    @State private var pendingRequestRows: [FriendRequestRow] = []
    @State private var friendshipRows: [FriendshipRow] = []
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isCreatingRequest = false
    @State private var busyAcceptRequestID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Profile",
                    summary: "iOS native friend graph reader. Use a real user UUID to inspect pending requests and accepted friendships through the same backend contracts already used by web.",
                    status: "Status: native friend graph shell now supports create/accept friend-request actions; profile editing and broader iOS domain clients are still pending.",
                    bullets: [
                        "Use the Session tab first to create or restore a session if you want the protected iOS shell context.",
                        "Paste a backend user UUID below, then fetch pending requests and friendships for that user.",
                        "You can now create friend requests via `/friends/requests` and accept pending inbound requests via `/friends/requests/{id}/accept` directly from this tab."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Friend graph reader")
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
                            await loadFriendGraph()
                        }
                    } label: {
                        Text(isLoading ? "Loading friend graph..." : "Load friend graph")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create friend request")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Receiver user UUID", text: $receiverUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await createFriendRequest()
                            }
                        } label: {
                            Text(isCreatingRequest ? "Sending friend request..." : "Send friend request")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isCreatingRequest ||
                            isLoading ||
                            userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    Text("Session indicator: \(sessionStore.sessionIndicatorLabel)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

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

                    if let pendingRequestCount, let friendshipCount {
                        seamRow(
                            title: "Snapshot summary",
                            state: "Pending requests: \(pendingRequestCount) · Accepted friendships: \(friendshipCount)",
                            detail: "Requested user: \(userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines))"
                        )
                    } else {
                        Text("No friend graph snapshot loaded yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pending friend requests")
                        .font(.headline)

                    if pendingRequestRows.isEmpty {
                        Text("No pending friend requests loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pendingRequestRows) { row in
                            VStack(alignment: .leading, spacing: 8) {
                                seamRow(
                                    title: "\(row.requesterLabel) → \(row.receiverLabel)",
                                    state: "status: \(row.status)",
                                    detail: "request_id: \(row.id)"
                                )

                                if row.canAccept {
                                    Button {
                                        Task {
                                            await acceptFriendRequest(requestID: row.id)
                                        }
                                    } label: {
                                        Text(busyAcceptRequestID == row.id ? "Accepting..." : "Accept request")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isLoading || busyAcceptRequestID == row.id)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Accepted friendships")
                        .font(.headline)

                    if friendshipRows.isEmpty {
                        Text("No accepted friendships loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friendshipRows) { row in
                            seamRow(
                                title: "\(row.userALabel) ↔ \(row.userBLabel)",
                                state: "state: \(row.state)",
                                detail: "friendship_id: \(row.id)"
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Profile")
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

    private func loadFriendGraph(statusMessage: String? = nil) async {
        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để load friend graph."
            return
        }

        isLoading = true
        if let statusMessage {
            fetchError = statusMessage
        } else {
            fetchError = nil
        }

        do {
            let snapshot = try await FriendGraphAPIClient().fetchSnapshot(userID: trimmedUserID)
            pendingRequestCount = snapshot.requestCount
            friendshipCount = snapshot.friendshipCount
            pendingRequestRows = snapshot.pendingRequests
            friendshipRows = snapshot.friendships
            if statusMessage != nil {
                fetchError = nil
            }
        } catch {
            pendingRequestCount = nil
            friendshipCount = nil
            pendingRequestRows = []
            friendshipRows = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func createFriendRequest() async {
        let requesterUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverUserID = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !requesterUserID.isEmpty, !receiverUserID.isEmpty else {
            fetchError = "Cần requester và receiver UUID để tạo friend request."
            return
        }

        isCreatingRequest = true
        fetchError = nil

        do {
            try await FriendGraphAPIClient().createFriendRequest(
                requesterUserID: requesterUserID,
                receiverUserID: receiverUserID
            )
            receiverUserIDDraft = ""
            await loadFriendGraph(statusMessage: "Friend request created. Reloading friend graph...")
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingRequest = false
    }

    private func acceptFriendRequest(requestID: String) async {
        guard !requestID.isEmpty else {
            fetchError = "Friend request id không hợp lệ."
            return
        }

        busyAcceptRequestID = requestID
        fetchError = nil

        do {
            try await FriendGraphAPIClient().acceptFriendRequest(requestID: requestID)
            await loadFriendGraph(statusMessage: "Friend request accepted. Reloading friend graph...")
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        busyAcceptRequestID = nil
    }

    private func seamRow(title: String, state: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(state)
                .font(.footnote)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct FriendGraphSnapshot {
    let requestCount: Int
    let friendshipCount: Int
    let pendingRequests: [FriendRequestRow]
    let friendships: [FriendshipRow]
}

private struct FriendRequestRow: Identifiable {
    let id: String
    let status: String
    let requesterLabel: String
    let receiverLabel: String
    let canAccept: Bool
}

private struct FriendshipRow: Identifiable {
    let id: String
    let state: String
    let userALabel: String
    let userBLabel: String
}

private struct FriendGraphAPIClient {
    private struct FriendRequestListResponse: Decodable {
        let count: Int
        let items: [FriendRequestItem]
    }

    private struct FriendshipListResponse: Decodable {
        let count: Int
        let items: [FriendshipItem]
    }

    private struct FriendRequestCreateRequest: Encodable {
        let requester_user_id: String
        let receiver_user_id: String
    }

    private struct FriendRequestCreateResponse: Decodable {
        let id: String
        let requester_user_id: String
        let receiver_user_id: String
        let status: String
    }

    private struct FriendshipResponse: Decodable {
        let id: String
        let user_a_id: String
        let user_b_id: String
        let state: String
    }

    private struct FriendRequestItem: Decodable {
        let id: String
        let status: String
        let requester: FriendUserSummary
        let receiver: FriendUserSummary
    }

    private struct FriendshipItem: Decodable {
        let id: String
        let state: String
        let user_a: FriendUserSummary
        let user_b: FriendUserSummary
    }

    private struct FriendUserSummary: Decodable {
        let id: String
        let email: String
        let username: String?
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
                return "Thiếu backend base URL hợp lệ cho friend graph shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend friend graph response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchSnapshot(userID: String) async throws -> FriendGraphSnapshot {
        let requestsResponse = try await fetchFriendRequests(userID: userID)
        let friendshipsResponse = try await fetchFriendships(userID: userID)

        return FriendGraphSnapshot(
            requestCount: requestsResponse.count,
            friendshipCount: friendshipsResponse.count,
            pendingRequests: requestsResponse.items.map {
                FriendRequestRow(
                    id: $0.id,
                    status: $0.status,
                    requesterLabel: $0.requester.username ?? $0.requester.email,
                    receiverLabel: $0.receiver.username ?? $0.receiver.email,
                    canAccept: $0.status == "pending" && $0.receiver.id == userID
                )
            },
            friendships: friendshipsResponse.items.map {
                FriendshipRow(
                    id: $0.id,
                    state: $0.state,
                    userALabel: $0.user_a.username ?? $0.user_a.email,
                    userBLabel: $0.user_b.username ?? $0.user_b.email
                )
            }
        )
    }

    func createFriendRequest(requesterUserID: String, receiverUserID: String) async throws {
        var request = URLRequest(url: try makeURL(path: "/friends/requests"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            FriendRequestCreateRequest(
                requester_user_id: requesterUserID,
                receiver_user_id: receiverUserID
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend request create failed"))
        }

        do {
            _ = try JSONDecoder().decode(FriendRequestCreateResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func acceptFriendRequest(requestID: String) async throws {
        var request = URLRequest(url: try makeURL(path: "/friends/requests/\(requestID)/accept"))
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend request accept failed"))
        }

        do {
            _ = try JSONDecoder().decode(FriendshipResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func fetchFriendRequests(userID: String) async throws -> FriendRequestListResponse {
        let url = try makeURL(path: "/friends/requests", userID: userID)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend requests fetch failed"))
        }

        do {
            return try JSONDecoder().decode(FriendRequestListResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func fetchFriendships(userID: String) async throws -> FriendshipListResponse {
        let url = try makeURL(path: "/friends", userID: userID)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friendships fetch failed"))
        }

        do {
            return try JSONDecoder().decode(FriendshipListResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String, userID: String) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "user_id", value: userID)]

        guard let url = components?.url else {
            throw APIError.invalidBaseURL
        }

        return url
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
