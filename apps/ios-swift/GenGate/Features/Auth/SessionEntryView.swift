import SwiftUI

struct SessionEntryView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    var body: some View {
        @Bindable var sessionStore = sessionStore

        VStack(alignment: .leading, spacing: 20) {
            Text("Batch 37 · iOS self-serve register shell")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)

            switch sessionStore.authState {
            case .signedOut, .signingIn, .restoring:
                VStack(alignment: .leading, spacing: 16) {
                    Text("Register + login shell")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Flow này gọi backend auth shell thật ở mức tối thiểu: user mới có thể tự register bằng /auth/register, sau đó login để lưu persisted session local; app mở lại vẫn restore bằng /auth/session, còn manual refresh gọi /auth/refresh để rotate token thật.")
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
                    .disabled(sessionStore.authState == .signingIn || sessionStore.authState == .restoring || sessionStore.isRegistering)

                    Button {
                        Task {
                            await sessionStore.registerAndSignIn()
                        }
                    } label: {
                        Text(sessionStore.isRegistering ? "Creating account..." : "Create account + sign in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(sessionStore.authState == .signingIn || sessionStore.authState == .restoring || sessionStore.isRegistering)

                    Button {
                        Task {
                            await sessionStore.refreshPersistedSession()
                        }
                    } label: {
                        Text(sessionStore.isRefreshingSession ? "Refreshing session..." : "Refresh persisted session")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(sessionStore.authState == .signingIn || sessionStore.authState == .restoring || sessionStore.isRefreshingSession || sessionStore.isRegistering)

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
                            .foregroundStyle(statusMessage.contains("đăng nhập lại") ? .orange : .secondary)

                        if statusMessage.contains("hết hạn") || statusMessage.contains("revoke") {
                            Text("Local persisted session cũ đã được xóa để tránh restore lặp lại state không còn hợp lệ.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
                            .foregroundStyle(statusMessage.contains("đăng nhập lại") ? .orange : .secondary)

                        if statusMessage.contains("hết hạn") || statusMessage.contains("revoke") {
                            Text("Local persisted session cũ đã được xóa để tránh restore lặp lại state không còn hợp lệ.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
