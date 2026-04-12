import Foundation
import Observation

@MainActor
@Observable
final class AppSessionStore {
    enum AuthState: Equatable {
        case signedOut
        case restoring
        case signingIn
        case authenticated(UserSession)
    }

    struct UserSession: Codable, Equatable {
        let userID: String
        let email: String
        let deviceID: String
        let sessionID: String
        let refreshToken: String
        let expiresAt: String
        let expiresInSeconds: Int
        let tokenType: String
        let sessionStatus: String

        var displayName: String {
            email.isEmpty ? "GenGate Tester" : email
        }

        var statusSummary: String {
            "\(sessionStatus) · expires in \(expiresInSeconds)s"
        }
    }

    private struct LoginResponse: Decodable {
        let user_id: String
        let email: String
        let device_id: String
        let session_id: String
        let refresh_token: String
        let expires_at: String
        let expires_in_seconds: Int
        let token_type: String
        let bootstrap_mode: String
        let session_status: String
    }

    private struct SessionSnapshotResponse: Decodable {
        let user_id: String
        let email: String
        let device_id: String
        let session_id: String
        let expires_at: String
        let expires_in_seconds: Int
        let token_type: String
        let session_status: String
    }

    private struct StoredSession: Codable {
        let userSession: UserSession
    }

    private enum SessionError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case unauthorized
        case network(String)

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Thiếu backend base URL hợp lệ cho auth shell."
            case .invalidResponse:
                return "Backend auth/session response thiếu field cần thiết."
            case .unauthorized:
                return "Session đã lưu không còn hợp lệ."
            case let .network(message):
                return message
            }
        }
    }

    private let sessionDefaultsKey = "gengate.app.session"
    private let backendBaseURL: URL?
    private let sessionStore: UserDefaults

    var authState: AuthState = .signedOut
    var selectedTab: AppTab = .session
    var pendingProtectedTab: AppTab?
    var emailDraft: String = ""
    var passwordDraft: String = ""
    var statusMessage: String?
    var isRefreshingSession: Bool = false

    var sessionIndicatorLabel: String {
        switch authState {
        case .signedOut:
            return "Guest"
        case .restoring:
            return "Restoring…"
        case .signingIn:
            return "Signing in…"
        case let .authenticated(userSession):
            return userSession.email
        }
    }

    var sessionStatusSummary: String {
        switch authState {
        case .signedOut:
            return "No active persisted session"
        case .restoring:
            return "Checking persisted session…"
        case .signingIn:
            return "Creating session…"
        case let .authenticated(userSession):
            return userSession.statusSummary
        }
    }

    var authGateMessage: String {
        let pendingSuffix: String
        if let pendingProtectedTab {
            pendingSuffix = " Tab đích đang chờ: \(pendingProtectedTab.displayName)."
        } else {
            pendingSuffix = ""
        }

        switch authState {
        case .signedOut:
            return "Chưa có persisted session hợp lệ.\(pendingSuffix)"
        case .restoring:
            return "Đang kiểm tra persisted session với backend auth shell.\(pendingSuffix)"
        case .signingIn:
            return "Đang gọi backend auth shell để tạo session.\(pendingSuffix)"
        case .authenticated:
            return "Persisted session hợp lệ. Route shell iOS đã có thể mở."
        }
    }

    init(
        backendBaseURL: URL? = URL(string: "http://127.0.0.1:8000"),
        sessionStore: UserDefaults = .standard
    ) {
        self.backendBaseURL = backendBaseURL
        self.sessionStore = sessionStore
    }

    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    func restorePersistedSession() async {
        await refreshPersistedSession(navigateToPendingDestination: true)
    }

    func refreshPersistedSession(navigateToPendingDestination: Bool = false) async {
        guard let persisted = loadPersistedSession() else {
            authState = .signedOut
            statusMessage = "Chưa có persisted session local để refresh."
            return
        }

        if navigateToPendingDestination {
            authState = .restoring
        } else {
            isRefreshingSession = true
        }

        do {
            let snapshot = try await requestSessionSnapshot(refreshToken: persisted.refreshToken)
            let restored = UserSession(
                userID: snapshot.user_id,
                email: snapshot.email,
                deviceID: snapshot.device_id,
                sessionID: snapshot.session_id,
                refreshToken: persisted.refreshToken,
                expiresAt: snapshot.expires_at,
                expiresInSeconds: snapshot.expires_in_seconds,
                tokenType: snapshot.token_type,
                sessionStatus: snapshot.session_status
            )
            persist(session: restored)
            authState = .authenticated(restored)
            if navigateToPendingDestination {
                let destination = pendingProtectedTab ?? .feed
                selectedTab = destination
                pendingProtectedTab = nil
                statusMessage = "Đã restore session từ backend auth shell và mở tab \(destination.displayName)."
            } else {
                statusMessage = "Đã refresh lại persisted session với backend auth shell."
            }
        } catch {
            clearPersistedSession()
            authState = .signedOut
            selectedTab = .session
            statusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isRefreshingSession = false
    }

    func signIn() async {
        authState = .signingIn
        statusMessage = nil

        do {
            let response = try await requestLogin(email: emailDraft)
            let session = UserSession(
                userID: response.user_id,
                email: response.email,
                deviceID: response.device_id,
                sessionID: response.session_id,
                refreshToken: response.refresh_token,
                expiresAt: response.expires_at,
                expiresInSeconds: response.expires_in_seconds,
                tokenType: response.token_type,
                sessionStatus: response.session_status
            )
            persist(session: session)
            passwordDraft = ""
            authState = .authenticated(session)
            let destination = pendingProtectedTab ?? .feed
            selectedTab = destination
            pendingProtectedTab = nil
            statusMessage = "Đăng nhập shell thành công, đã lưu session local, và mở tab \(destination.displayName)."
        } catch {
            authState = .signedOut
            statusMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() async {
        let persistedRefreshToken = loadPersistedSession()?.refreshToken

        if let persistedRefreshToken {
            _ = try? await requestLogout(refreshToken: persistedRefreshToken)
        }

        clearPersistedSession()
        authState = .signedOut
        passwordDraft = ""
        statusMessage = "Đã revoke session hiện tại và xóa session local trên iOS shell."
        pendingProtectedTab = nil
        selectedTab = .session
    }

    func requestProtectedTab(_ tab: AppTab) {
        guard tab != .session else {
            selectedTab = .session
            return
        }

        if isAuthenticated {
            selectedTab = tab
            pendingProtectedTab = nil
            return
        }

        pendingProtectedTab = tab
        selectedTab = .session
        statusMessage = "Cần đăng nhập hoặc restore session để mở tab \(tab.displayName)."
    }

    private func requestLogin(email: String) async throws -> LoginResponse {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            throw SessionError.network("Email là bắt buộc để gọi auth shell.")
        }

        let url = try makeURL(path: "/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": normalizedEmail,
            "platform": "ios",
            "device_name": "GenGate iOS Shell"
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw SessionError.network("Login request failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(LoginResponse.self, from: data)
        } catch {
            throw SessionError.invalidResponse
        }
    }

    private func requestSessionSnapshot(refreshToken: String) async throws -> SessionSnapshotResponse {
        let url = try makeURL(path: "/auth/session")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "refresh_token": refreshToken
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw SessionError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            throw SessionError.network("Session restore failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(SessionSnapshotResponse.self, from: data)
        } catch {
            throw SessionError.invalidResponse
        }
    }

    private func requestLogout(refreshToken: String) async throws {
        let url = try makeURL(path: "/auth/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "refresh_token": refreshToken
        ])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 200 {
            return
        }

        throw SessionError.network("Logout request failed with status \(httpResponse.statusCode).")
    }

    private func makeURL(path: String) throws -> URL {
        guard let backendBaseURL, let url = URL(string: path, relativeTo: backendBaseURL) else {
            throw SessionError.invalidBaseURL
        }
        return url
    }

    private func persist(session: UserSession) {
        let container = StoredSession(userSession: session)
        guard let data = try? JSONEncoder().encode(container) else {
            return
        }
        sessionStore.set(data, forKey: sessionDefaultsKey)
    }

    private func loadPersistedSession() -> UserSession? {
        guard let data = sessionStore.data(forKey: sessionDefaultsKey),
              let container = try? JSONDecoder().decode(StoredSession.self, from: data) else {
            return nil
        }
        return container.userSession
    }

    private func clearPersistedSession() {
        sessionStore.removeObject(forKey: sessionDefaultsKey)
    }
}

enum AppTab: Hashable {
    case session
    case feed
    case inbox
    case location
    case profile

    var displayName: String {
        switch self {
        case .session:
            return "Session"
        case .feed:
            return "Feed"
        case .inbox:
            return "Inbox"
        case .location:
            return "Location"
        case .profile:
            return "Profile"
        }
    }
}
