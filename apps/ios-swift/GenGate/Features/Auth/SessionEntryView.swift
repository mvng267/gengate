import SwiftUI

struct SessionEntryView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    var body: some View {
        @Bindable var sessionStore = sessionStore

        VStack(alignment: .leading, spacing: 20) {
            Text("Batch 30 · iOS auth shell")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)

            switch sessionStore.authState {
            case .signedOut, .signingIn:
                VStack(alignment: .leading, spacing: 16) {
                    Text("Login placeholder")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Flow này chỉ dựng session/login shell an toàn. Khi backend auth contract chốt, màn này sẽ map sang API thật.")
                        .foregroundStyle(.secondary)

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
                        sessionStore.signInPlaceholder()
                    } label: {
                        Text(sessionStore.authState == .signingIn ? "Signing in..." : "Enter app shell")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

            case let .authenticated(userSession):
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session ready")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Signed in as \(userSession.displayName)")
                    Text(userSession.email)
                        .foregroundStyle(.secondary)

                    Text("Tabs Feed / Inbox / Location / Profile đã được mở khóa ở mức shell để nối với backend auth/session sau.")
                        .foregroundStyle(.secondary)

                    Button("Sign out") {
                        sessionStore.signOut()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle("Session")
    }
}
