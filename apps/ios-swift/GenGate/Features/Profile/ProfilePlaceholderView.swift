import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Profile",
            summary: "User profile shell. Avatar, bio edit, privacy settings, and recent moments are stubbed."
        )
        .navigationTitle("Profile")
    }
}
