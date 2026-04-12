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
                FeedPlaceholderView()
            }
            .tabItem {
                Label("Feed", systemImage: "house")
            }
            .tag(AppTab.feed)
            .disabled(!sessionStore.isAuthenticated)

            NavigationStack {
                InboxPlaceholderView()
            }
            .tabItem {
                Label("Inbox", systemImage: "message")
            }
            .tag(AppTab.inbox)
            .disabled(!sessionStore.isAuthenticated)

            NavigationStack {
                LocationPlaceholderView()
            }
            .tabItem {
                Label("Location", systemImage: "location")
            }
            .tag(AppTab.location)
            .disabled(!sessionStore.isAuthenticated)

            NavigationStack {
                ProfilePlaceholderView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(AppTab.profile)
            .disabled(!sessionStore.isAuthenticated)
        }
    }

    private var currentTabBinding: Binding<AppTab> {
        Binding(
            get: { sessionStore.selectedTab },
            set: { newValue in
                if sessionStore.isAuthenticated || newValue == .session {
                    sessionStore.selectedTab = newValue
                } else {
                    sessionStore.selectedTab = .session
                }
            }
        )
    }
}
