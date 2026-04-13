import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let summary: String
    var status: String = "Status: MVP foundation placeholder only."
    var bullets: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(summary)
                .foregroundStyle(.secondary)

            Text(status)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(bullet)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
    }
}
