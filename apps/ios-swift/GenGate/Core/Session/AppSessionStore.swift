import Foundation
import Observation

@MainActor
@Observable
final class AppSessionStore {
    enum AuthState: Equatable {
        case signedOut
        case signingIn
        case authenticated(UserSession)
    }

    struct UserSession: Equatable {
        let userID: String
        let displayName: String
        let email: String

        static let preview = UserSession(
            userID: "batch30-user",
            displayName: "GenGate Tester",
            email: "batch30@example.com"
        )
    }

    var authState: AuthState = .signedOut
    var selectedTab: AppTab = .session
    var emailDraft: String = ""
    var passwordDraft: String = ""

    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    func signInPlaceholder() {
        authState = .signingIn
        let normalizedEmail = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = normalizedEmail.isEmpty ? "GenGate Tester" : normalizedEmail
        authState = .authenticated(
            UserSession(userID: "batch30-user", displayName: displayName, email: normalizedEmail)
        )
        selectedTab = .feed
    }

    func signOut() {
        authState = .signedOut
        passwordDraft = ""
        selectedTab = .session
    }
}

enum AppTab: Hashable {
    case session
    case feed
    case inbox
    case location
    case profile
}
