import SwiftUI

struct FeedPlaceholderView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Feed",
            summary: "Private friend moments feed shell. Media cards, reactions, and data loading are stubbed."
        )
        .navigationTitle("Feed")
    }
}
