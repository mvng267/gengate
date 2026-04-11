import SwiftUI

struct InboxPlaceholderView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Inbox",
            summary: "Direct messaging shell only. Conversation list, chat thread, and realtime sync are stubbed."
        )
        .navigationTitle("Inbox")
    }
}
