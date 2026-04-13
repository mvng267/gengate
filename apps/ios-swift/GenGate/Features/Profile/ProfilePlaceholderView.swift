import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Profile",
                    summary: "iOS MVP readiness hub. Use this tab to understand which product seams are already testable across backend/web and what iOS still exposes as shell-only.",
                    status: "Status: iOS shell is ready for guided MVP testing context, but domain-native API consumption beyond auth is still pending.",
                    bullets: [
                        "Backend + web already expose friend graph, moments/feed, inbox, notifications, and location seams.",
                        "Use the Session tab first to create or restore a session before exploring protected tabs.",
                        "Feed / Inbox / Location tabs in iOS remain shell placeholders, but now sit inside a clearer MVP readiness flow.",
                        "For full end-to-end MVP smoke today, use web as the primary execution surface and iOS as the native shell readiness surface."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Current MVP seam map")
                        .font(.headline)

                    Group {
                        seamRow(title: "Friend graph", state: "Backend + web testable", detail: "Use web Profile launcher with a real user UUID.")
                        seamRow(title: "Moment posting + private feed", state: "Backend + web testable", detail: "Use web Feed shell with author/viewer UUIDs.")
                        seamRow(title: "Direct messaging", state: "Backend + web testable", detail: "Use web Inbox shell to open or reuse a 1:1 thread.")
                        seamRow(title: "Notifications", state: "Backend + web testable", detail: "Use web Notifications shell to create/list/toggle items.")
                        seamRow(title: "Location sharing state", state: "Backend + web testable", detail: "Use web Location shell to create/toggle share state and snapshots.")
                        seamRow(title: "iOS native consumption", state: "Session-ready shell", detail: "Auth/session path is live; deeper domain clients remain pending.")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested tester path")
                        .font(.headline)

                    Group {
                        Text("1. In iOS, use Session to verify auth shell state and persisted session behavior.")
                        Text("2. In web, open the MVP hub and walk Profile → Feed → Inbox → Notifications → Location.")
                        Text("3. Return to iOS tabs to confirm shell framing and readiness copy match the current MVP truth.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Profile")
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
