import SwiftUI

struct AuthGatePlaceholderView: View {
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(summary)
                .foregroundStyle(.secondary)

            Text("Access locked")
                .font(.headline)

            Text("Hãy hoàn tất login hoặc để app restore persisted session từ tab Session trước khi mở route shell này.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .navigationTitle(title)
    }
}
