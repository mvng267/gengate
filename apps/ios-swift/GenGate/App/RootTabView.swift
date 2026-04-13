import SwiftUI

struct RootTabView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    var body: some View {
        TabView(selection: currentTabBinding) {
            NavigationStack {
                SessionEntryView()
            }
            .tabItem {
                Label(sessionStore.isAuthenticated ? "Session" : "Login", systemImage: sessionStore.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.badge.key")
            }
            .tag(AppTab.session)

            NavigationStack {
                protectedTabContent(
                    title: "Feed",
                    summary: "Friends-only moment feed UI and data loading are pending."
                ) {
                    FeedPlaceholderView()
                }
            }
            .tabItem {
                Label("Feed", systemImage: "house")
            }
            .tag(AppTab.feed)

            NavigationStack {
                protectedTabContent(
                    title: "Inbox",
                    summary: "1:1 encrypted messaging thread list and composer are pending."
                ) {
                    InboxPlaceholderView()
                }
            }
            .tabItem {
                Label("Inbox", systemImage: "message")
            }
            .tag(AppTab.inbox)

            NavigationStack {
                protectedTabContent(
                    title: "Location",
                    summary: "Snapshot sharing controls and viewer permissions UI are pending."
                ) {
                    LocationPlaceholderView()
                }
            }
            .tabItem {
                Label("Location", systemImage: "location")
            }
            .tag(AppTab.location)

            NavigationStack {
                protectedTabContent(
                    title: "Profile",
                    summary: "MVP readiness hub for iOS shell. Profile editing is still pending, but this tab now explains current seam coverage and recommended test flow."
                ) {
                    ProfilePlaceholderView()
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(AppTab.profile)
        }
        .overlay(alignment: .top) {
            sessionStatusBanner
        }
    }

    private var currentTabBinding: Binding<AppTab> {
        Binding(
            get: { sessionStore.selectedTab },
            set: { newValue in
                if newValue == .session {
                    sessionStore.selectedTab = .session
                } else {
                    sessionStore.requestProtectedTab(newValue)
                }
            }
        )
    }

    @ViewBuilder
    private func protectedTabContent<Content: View>(
        title: String,
        summary: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if sessionStore.isAuthenticated {
            content()
        } else {
            AuthGatePlaceholderView(title: title, summary: summary)
        }
    }

    private var sessionStatusBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Session: \(sessionStore.sessionIndicatorLabel)")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Status: \(sessionStore.sessionStatusSummary)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(sessionStore.authGateMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}
