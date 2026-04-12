import SwiftUI

@main
struct GenGateApp: App {
    @State private var sessionStore = AppSessionStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(sessionStore)
                .task {
                    await sessionStore.restorePersistedSession()
                }
        }
    }
}
