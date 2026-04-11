import SwiftUI

struct LocationPlaceholderView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Location",
            summary: "Location sharing state shell. Permission flow, map provider integration, and privacy controls are stubbed."
        )
        .navigationTitle("Location")
    }
}
