import SwiftUI

struct SessionEntryView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    var body: some View {
        @Bindable var sessionStore = sessionStore

        VStack(alignment: .leading, spacing: 20) {
            Text("Batch 34 · iOS manual refresh shell")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)

            switch sessionStore.authState {
            case .signedOut, .signingIn, .restoring:
                VStack(alignment: .leading, spacing: 16) {
                    Text("Login + restore shell")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Flow này gọi backend auth shell thật ở mức tối thiểu: login sẽ lưu refresh token local, app mở lại sẽ thử restore bằng /auth/session.")
                        .foregroundStyle(.secondary)

                    if let pendingProtectedTab = sessionStore.pendingProtectedTab {
                        Text("Tab đích đang chờ mở: \(pendingProtectedTab.displayName)")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }

                    TextField("Email", text: $sessionStore.emailDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password / OTP placeholder", text: $sessionStore.passwordDraft)
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task {
                            await sessionStore.signIn()
                        }
                    } label: {
                        Text(primaryActionTitle(for: sessionStore.authState))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sessionStore.authState == .signingIn || sessionStore.authState == .restoring)

                    Button {
                        Task {
                            await sessionStore.refreshPersistedSession()
                        }
                    } label: {
                        Text(sessionStore.isRefreshingSession ? "Refreshing session..." : "Refresh persisted session")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(sessionStore.authState == .signingIn || sessionStore.authState == .restoring || sessionStore.isRefreshingSession)

                    Text("Session indicator: \(sessionStore.sessionIndicatorLabel)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Status: \(sessionStore.sessionStatusSummary)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text(sessionStore.authGateMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let statusMessage = sessionStore.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

            case let .authenticated(userSession):
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session ready")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Signed in as \(userSession.displayName)")
                    Text(userSession.email)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("session_id: \(userSession.sessionID)")
                        Text("device_id: \(userSession.deviceID)")
                        Text("session_status: \(userSession.sessionStatus)")
                        Text("expires_in_seconds: \(userSession.expiresInSeconds)")
                    }
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)

                    Text("Tabs Feed / Inbox / Location / Profile đã được mở khóa ở mức shell để nối với backend auth/session sau.")
                        .foregroundStyle(.secondary)

                    if let pendingProtectedTab = sessionStore.pendingProtectedTab {
                        Text("Tab chờ trước đó: \(pendingProtectedTab.displayName)")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }

                    Text("Session indicator: \(sessionStore.sessionIndicatorLabel)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Status: \(sessionStore.sessionStatusSummary)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text(sessionStore.authGateMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let statusMessage = sessionStore.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            await sessionStore.refreshPersistedSession()
                        }
                    } label: {
                        Text(sessionStore.isRefreshingSession ? "Refreshing session..." : "Refresh persisted session")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sessionStore.isRefreshingSession)

                    Button("Sign out") {
                        Task {
                            await sessionStore.signOut()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle("Session")
    }

    private func primaryActionTitle(for authState: AppSessionStore.AuthState) -> String {
        switch authState {
        case .restoring:
            return "Restoring session..."
        case .signingIn:
            return "Signing in..."
        case .signedOut, .authenticated:
            return "Login + persist session"
        }
    }
}
