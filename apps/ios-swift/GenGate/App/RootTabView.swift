import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LoginPlaceholderView()
            }
            .tabItem {
                Label("Login", systemImage: "person.badge.key")
            }

            NavigationStack {
                FeedPlaceholderView()
            }
            .tabItem {
                Label("Feed", systemImage: "house")
            }

            NavigationStack {
                InboxPlaceholderView()
            }
            .tabItem {
                Label("Inbox", systemImage: "message")
            }

            NavigationStack {
                LocationPlaceholderView()
            }
            .tabItem {
                Label("Location", systemImage: "location")
            }

            NavigationStack {
                ProfilePlaceholderView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}
