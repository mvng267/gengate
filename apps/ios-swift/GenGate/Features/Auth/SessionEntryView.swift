import SwiftUI

struct SessionEntryView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    var body: some View {
        @Bindable var sessionStore = sessionStore

        VStack(alignment: .leading, spacing: 20) {
            Text("Batch 41 · iOS auth state inspector")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)

            switch sessionStore.authState {
            case .signedOut, .signingIn, .restoring:
                VStack(alignment: .leading, spacing: 16) {
                    Text("Register + auth state shell")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Batch 41 ưu tiên thêm persisted-session inspector để nhìn rõ local state trước và sau login, restore, manual refresh, logout, hoặc clear ngay trên màn Session.")
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
                        Text(sessionStore.isRefreshingSession ? "Refreshing session..." : "Manual refresh persisted session")
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

                        if statusMessage.contains("session_expired") || statusMessage.contains("session_revoked") || statusMessage.contains("hết hạn") || statusMessage.contains("revoke") || statusMessage.contains("logout") {
                            Text("Local persisted session cũ đã được xóa để tránh restore lặp lại state không còn hợp lệ; revoke/detail thật từ backend cũng được surface ngay trên màn này.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Persisted session snapshot")
                            .font(.footnote)
                            .fontWeight(.semibold)

                        if let persistedSessionSnapshot = sessionStore.persistedSessionSnapshot {
                            Text(persistedSessionSnapshot)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Text("Chưa có persisted session trong local storage.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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

                    Text("Tabs Feed / Inbox / Location / Profile đã được mở khóa ở mức shell; màn này giờ còn có persisted-session inspector để nhìn rõ state thật trước/sau restore, refresh, và logout.")
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

                        if statusMessage.contains("session_expired") || statusMessage.contains("session_revoked") || statusMessage.contains("hết hạn") || statusMessage.contains("revoke") || statusMessage.contains("logout") {
                            Text("Local persisted session cũ đã được xóa để tránh restore lặp lại state không còn hợp lệ; revoke/detail thật từ backend cũng được surface ngay trên màn này.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Persisted session snapshot")
                            .font(.footnote)
                            .fontWeight(.semibold)

                        if let persistedSessionSnapshot = sessionStore.persistedSessionSnapshot {
                            Text(persistedSessionSnapshot)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Text("Chưa có persisted session trong local storage.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task {
                            await sessionStore.refreshPersistedSession()
                        }
                    } label: {
                        Text(sessionStore.isRefreshingSession ? "Refreshing session..." : "Manual refresh persisted session")
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
