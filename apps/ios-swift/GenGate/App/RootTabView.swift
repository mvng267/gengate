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
                    summary: "Friends-only feed now supports minimal moment create + read shell; reactions and richer media UX remain pending."
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
                    summary: "Direct thread + text send shell is live; device-key and realtime delivery flows remain pending."
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
                    summary: "Location share state shell now supports create share + audience add + count/status checks; map UI remains pending."
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
                    title: "Notifications",
                    summary: "Notification shell now supports create + list + read/unread toggles; delete and richer grouping remain pending."
                ) {
                    NotificationsPlaceholderView()
                }
            }
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            .tag(AppTab.notifications)

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
