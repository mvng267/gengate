import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(summary)
                .foregroundStyle(.secondary)

            Text("Status: MVP foundation placeholder only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
    }
}
