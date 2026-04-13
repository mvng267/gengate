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
        let backendDetail: String?

        var displayName: String {
            email.isEmpty ? "GenGate Tester" : email
        }

        var statusSummary: String {
            "\(sessionStatus) · expires in \(expiresInSeconds)s"
        }
    }

    private struct RegisterResponse: Decodable {
        let id: String
        let email: String
        let username: String?
        let status: String
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
        let local_clear_recommended: Bool
        let backend_detail: String?
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
        let local_clear_recommended: Bool
        let backend_detail: String?
    }

    private struct LogoutOutcome {
        let sessionStatus: String?
        let detail: String?
        let localClearRecommended: Bool
    }

    private struct StoredSession: Codable {
        let userSession: UserSession
    }

    private enum SessionError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case unauthorized(detail: String?)
        case loginRejected(detail: String?)
        case network(String)

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Thiếu backend base URL hợp lệ cho auth shell."
            case .invalidResponse:
                return "Backend auth/session response thiếu field cần thiết."
            case let .unauthorized(detail):
                if let detail, !detail.isEmpty {
                    return "Session đã hết hạn hoặc bị revoke (\(detail)). Local session đã được xóa; hãy đăng nhập lại."
                }
                return "Session đã hết hạn hoặc bị revoke. Local session đã được xóa; hãy đăng nhập lại."
            case let .loginRejected(detail):
                if let detail, !detail.isEmpty {
                    return "Backend từ chối login với detail \(detail)."
                }
                return "Backend từ chối login vì user không tồn tại hoặc auth shell chưa sẵn sàng."
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
    var loginOutcomeSummary: String?
    var localClearOutcomeSummary: String?
    var logoutOutcomeSummary: String?
    var refreshOutcomeSummary: String?
    var restoreOutcomeSummary: String?
    var isRefreshingSession: Bool = false
    var isRegistering: Bool = false

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

    var persistedSessionSnapshot: String? {
        guard let persisted = loadPersistedSession() else {
            return nil
        }

        return [
            "refresh_token: \(persisted.refreshToken)",
            "user_id: \(persisted.userID)",
            "email: \(persisted.email)",
            "session_id: \(persisted.sessionID)",
            "device_id: \(persisted.deviceID)",
            "token_type: \(persisted.tokenType)",
            "session_status: \(persisted.sessionStatus)",
            "expires_in_seconds: \(persisted.expiresInSeconds)"
        ].joined(separator: "\n")
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
        await restoreSessionSnapshot(navigateToPendingDestination: true)
    }

    func refreshPersistedSession(navigateToPendingDestination: Bool = false) async {
        guard let persisted = loadPersistedSession() else {
            authState = .signedOut
            statusMessage = "Chưa có persisted session local để refresh."
            localClearOutcomeSummary = nil
            logoutOutcomeSummary = nil
            refreshOutcomeSummary = nil
            return
        }

        if navigateToPendingDestination {
            authState = .restoring
        } else {
            isRefreshingSession = true
        }
        refreshOutcomeSummary = nil

        do {
            let response = try await requestRefreshSession(refreshToken: persisted.refreshToken)
            let refreshed = UserSession(
                userID: response.user_id,
                email: response.email,
                deviceID: response.device_id,
                sessionID: response.session_id,
                refreshToken: response.refresh_token,
                expiresAt: response.expires_at,
                expiresInSeconds: response.expires_in_seconds,
                tokenType: response.token_type,
                sessionStatus: response.session_status,
                backendDetail: response.backend_detail
            )
            persist(session: refreshed)
            authState = .authenticated(refreshed)
            if navigateToPendingDestination {
                let destination = pendingProtectedTab ?? .feed
                selectedTab = destination
                pendingProtectedTab = nil
                statusMessage = "Đã refresh session với backend auth shell, rotate refresh token, và mở tab \(destination.displayName)."
                refreshOutcomeSummary = [
                    "refresh_result: rotated_local_updated",
                    "backend_detail: \(response.backend_detail ?? response.session_status)",
                    "local_clear_recommended: \(response.local_clear_recommended ? "true" : "false")",
                    "message: Đã refresh session với backend auth shell, rotate refresh token, và mở tab \(destination.displayName)."
                ].joined(separator: "\n")
            } else {
                statusMessage = "Đã refresh session thật với backend auth shell và rotate refresh token local."
                refreshOutcomeSummary = [
                    "refresh_result: rotated_local_updated",
                    "backend_detail: \(response.backend_detail ?? response.session_status)",
                    "local_clear_recommended: \(response.local_clear_recommended ? "true" : "false")",
                    "message: Đã refresh session thật với backend auth shell và rotate refresh token local."
                ].joined(separator: "\n")
            }
        } catch {
            clearPersistedSession()
            authState = .signedOut
            selectedTab = .session
            if let sessionError = error as? SessionError,
               case let .unauthorized(detail) = sessionError {
                if let detail, !detail.isEmpty {
                    statusMessage = "Session đã hết hạn hoặc bị revoke (\(detail)). Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    refreshOutcomeSummary = [
                        "refresh_result: failed_local_cleared",
                        "backend_detail: \(detail)",
                        "message: Session đã hết hạn hoặc bị revoke (\(detail)). Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    ].joined(separator: "\n")
                } else {
                    statusMessage = "Session đã hết hạn hoặc bị revoke. Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    refreshOutcomeSummary = [
                        "refresh_result: failed_local_cleared",
                        "backend_detail: none",
                        "message: Session đã hết hạn hoặc bị revoke. Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    ].joined(separator: "\n")
                }
            } else {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                statusMessage = message
                refreshOutcomeSummary = [
                    "refresh_result: failed_local_cleared",
                    "backend_detail: none",
                    "message: \(message)"
                ].joined(separator: "\n")
            }
        }

        isRefreshingSession = false
    }

    private func restoreSessionSnapshot(navigateToPendingDestination: Bool) async {
        guard let persisted = loadPersistedSession() else {
            authState = .signedOut
            statusMessage = "Chưa có persisted session local để restore."
            restoreOutcomeSummary = nil
            return
        }

        authState = .restoring
        restoreOutcomeSummary = nil

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
                sessionStatus: snapshot.session_status,
                backendDetail: snapshot.backend_detail
            )
            persist(session: restored)
            authState = .authenticated(restored)
            if navigateToPendingDestination {
                let destination = pendingProtectedTab ?? .feed
                selectedTab = destination
                pendingProtectedTab = nil
                statusMessage = "Đã restore session từ backend auth shell và mở tab \(destination.displayName)."
                restoreOutcomeSummary = [
                    "restore_result: local_restored_valid",
                    "backend_detail: \(snapshot.backend_detail ?? snapshot.session_status)",
                    "message: Đã restore session từ backend auth shell và mở tab \(destination.displayName)."
                ].joined(separator: "\n")
            } else {
                statusMessage = "Đã restore persisted session với backend auth shell."
                restoreOutcomeSummary = [
                    "restore_result: local_restored_valid",
                    "backend_detail: \(snapshot.backend_detail ?? snapshot.session_status)",
                    "message: Đã restore persisted session với backend auth shell."
                ].joined(separator: "\n")
            }
        } catch {
            clearPersistedSession()
            authState = .signedOut
            selectedTab = .session
            if let sessionError = error as? SessionError,
               case let .unauthorized(detail) = sessionError {
                if let detail, !detail.isEmpty {
                    statusMessage = "Session đã hết hạn hoặc bị revoke (\(detail)). Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    restoreOutcomeSummary = [
                        "restore_result: failed_local_cleared",
                        "backend_detail: \(detail)",
                        "message: Session đã hết hạn hoặc bị revoke (\(detail)). Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    ].joined(separator: "\n")
                } else {
                    statusMessage = "Session đã hết hạn hoặc bị revoke. Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    restoreOutcomeSummary = [
                        "restore_result: failed_local_cleared",
                        "backend_detail: none",
                        "message: Session đã hết hạn hoặc bị revoke. Local session đã được xóa; hãy đăng nhập lại để tạo session mới."
                    ].joined(separator: "\n")
                }
            } else {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                statusMessage = message
                restoreOutcomeSummary = [
                    "restore_result: failed_local_cleared",
                    "backend_detail: none",
                    "message: \(message)"
                ].joined(separator: "\n")
            }
        }
    }

    func signIn() async {
        authState = .signingIn
        statusMessage = nil
        loginOutcomeSummary = nil
        localClearOutcomeSummary = nil
        logoutOutcomeSummary = nil
        refreshOutcomeSummary = nil
        restoreOutcomeSummary = nil

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
                sessionStatus: response.session_status,
                backendDetail: response.backend_detail
            )
            persist(session: session)
            passwordDraft = ""
            authState = .authenticated(session)
            let destination = pendingProtectedTab ?? .feed
            selectedTab = destination
            pendingProtectedTab = nil
            let loginMessage = "Đăng nhập shell thành công, đã lưu session local, và mở tab \(destination.displayName)."
            statusMessage = loginMessage
            loginOutcomeSummary = [
                "login_result: success_persisted",
                "backend_detail: \(response.backend_detail ?? response.session_status)",
                "local_clear_recommended: \(response.local_clear_recommended ? "true" : "false")",
                "message: \(loginMessage)"
            ].joined(separator: "\n")
        } catch {
            authState = .signedOut
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let backendDetail: String?
            let loginResult: String
            if let sessionError = error as? SessionError,
               case let .loginRejected(detail) = sessionError {
                backendDetail = detail
                loginResult = "failed_login_rejected"
            } else {
                backendDetail = nil
                loginResult = "failed"
            }
            statusMessage = message
            loginOutcomeSummary = [
                "login_result: \(loginResult)",
                "backend_detail: \(backendDetail ?? "none")",
                "message: \(message)"
            ].joined(separator: "\n")
        }
    }

    func registerAndSignIn() async {
        let normalizedEmail = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            statusMessage = "Email là bắt buộc để tạo account shell."
            return
        }

        isRegistering = true
        statusMessage = nil
        loginOutcomeSummary = nil
        localClearOutcomeSummary = nil
        logoutOutcomeSummary = nil
        refreshOutcomeSummary = nil
        restoreOutcomeSummary = nil

        do {
            _ = try await requestRegister(email: normalizedEmail)
            emailDraft = normalizedEmail
            isRegistering = false
            await signIn()
            if case let .authenticated(session) = authState {
                let loginMessage = "Tạo account shell + đăng nhập thành công; persisted session local đã sẵn sàng."
                statusMessage = loginMessage
                loginOutcomeSummary = [
                    "login_result: register_then_sign_in_success",
                    "backend_detail: \(session.backendDetail ?? session.sessionStatus)",
                    "local_clear_recommended: false",
                    "message: \(loginMessage)"
                ].joined(separator: "\n")
            }
        } catch {
            isRegistering = false
            authState = .signedOut
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            statusMessage = message
            loginOutcomeSummary = [
                "login_result: register_then_sign_in_failed",
                "backend_detail: none",
                "message: \(message)"
            ].joined(separator: "\n")
        }
    }

    func signOut() async {
        let persistedRefreshToken = loadPersistedSession()?.refreshToken
        var logoutOutcome: LogoutOutcome?

        loginOutcomeSummary = nil
        localClearOutcomeSummary = nil
        logoutOutcomeSummary = nil
        refreshOutcomeSummary = nil
        restoreOutcomeSummary = nil

        if let persistedRefreshToken {
            logoutOutcome = try? await requestLogout(refreshToken: persistedRefreshToken)
        }

        clearPersistedSession()
        authState = .signedOut
        passwordDraft = ""

        if let logoutOutcome {
            let backendDetail = logoutOutcome.detail ?? logoutOutcome.sessionStatus
            let localClearLine = "local_clear_recommended: \(logoutOutcome.localClearRecommended ? "true" : "false")"

            if let detail = backendDetail, !detail.isEmpty {
                let detailMessage: String
                if logoutOutcome.sessionStatus != nil {
                    detailMessage = "Đã logout, backend trả detail \(detail), và xóa session local trên iOS shell."
                } else {
                    detailMessage = "Backend báo session logout không còn hợp lệ (\(detail)); local session vẫn đã được xóa trên iOS shell."
                }
                let recommendedSuffix = logoutOutcome.localClearRecommended
                    ? " Backend cũng báo nên clear local session để shell state sạch và dễ verify hơn."
                    : ""
                statusMessage = detailMessage + recommendedSuffix
                logoutOutcomeSummary = [
                    "logout_result: local_cleared",
                    "backend_detail: \(detail)",
                    localClearLine,
                    "message: \(detailMessage + recommendedSuffix)"
                ].joined(separator: "\n")
            } else {
                let message = "Đã logout, revoke session hiện tại, và xóa session local trên iOS shell."
                statusMessage = message
                logoutOutcomeSummary = [
                    "logout_result: local_cleared",
                    "backend_detail: none",
                    localClearLine,
                    "message: \(message)"
                ].joined(separator: "\n")
            }
        } else {
            statusMessage = "Đã logout, revoke session hiện tại, và xóa session local trên iOS shell."
            logoutOutcomeSummary = [
                "logout_result: local_cleared",
                "backend_detail: none",
                "local_clear_recommended: false",
                "message: Đã logout, revoke session hiện tại, và xóa session local trên iOS shell."
            ].joined(separator: "\n")
        }

        pendingProtectedTab = nil
        selectedTab = .session
    }

    func clearLocalSession() {
        clearPersistedSession()
        authState = .signedOut
        selectedTab = .session
        pendingProtectedTab = nil
        passwordDraft = ""
        statusMessage = "Đã xóa session local trên iOS shell."
        loginOutcomeSummary = nil
        localClearOutcomeSummary = [
            "local_clear_result: local_session_cleared",
            "backend_detail: none",
            "message: Đã xóa session local trên iOS shell."
        ].joined(separator: "\n")
        logoutOutcomeSummary = nil
        refreshOutcomeSummary = nil
        restoreOutcomeSummary = nil
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
        loginOutcomeSummary = nil
        localClearOutcomeSummary = nil
        logoutOutcomeSummary = nil
        refreshOutcomeSummary = nil
        restoreOutcomeSummary = nil
    }

    private func requestRegister(email: String) async throws -> RegisterResponse {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            throw SessionError.network("Email là bắt buộc để gọi register shell.")
        }

        let usernameSeed = normalizedEmail.split(separator: "@").first.map(String.init) ?? "gengate_user"
        let url = try makeURL(path: "/auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": normalizedEmail,
            "username": usernameSeed
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionError.invalidResponse
        }

        if httpResponse.statusCode == 409 {
            throw SessionError.network("Email này đã tồn tại. Hãy đăng nhập bằng account shell hiện có.")
        }

        guard httpResponse.statusCode == 201 else {
            throw SessionError.network("Register request failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(RegisterResponse.self, from: data)
        } catch {
            throw SessionError.invalidResponse
        }
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
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
            throw SessionError.loginRejected(detail: readErrorDetail(from: data))
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

    private func readErrorDetail(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detail = object["detail"] as? String,
              !detail.isEmpty else {
            return nil
        }
        return detail
    }

    private func requestRefreshSession(refreshToken: String) async throws -> LoginResponse {
        let url = try makeURL(path: "/auth/refresh")
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
            throw SessionError.unauthorized(detail: readErrorDetail(from: data))
        }

        guard httpResponse.statusCode == 200 else {
            throw SessionError.network("Session refresh failed with status \(httpResponse.statusCode).")
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
            throw SessionError.unauthorized(detail: readErrorDetail(from: data))
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

    private func requestLogout(refreshToken: String) async throws -> LogoutOutcome {
        let url = try makeURL(path: "/auth/logout")
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

        if httpResponse.statusCode == 200 {
            let snapshot = try JSONDecoder().decode(SessionSnapshotResponse.self, from: data)
            return LogoutOutcome(
                sessionStatus: snapshot.session_status,
                detail: snapshot.backend_detail,
                localClearRecommended: snapshot.local_clear_recommended
            )
        }

        if httpResponse.statusCode == 401 {
            return LogoutOutcome(
                sessionStatus: nil,
                detail: readErrorDetail(from: data),
                localClearRecommended: true
            )
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
