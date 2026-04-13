import SwiftUI

struct FeedPlaceholderView: View {
    @State private var viewerUserIDDraft: String = ""
    @State private var momentRows: [PrivateFeedMomentRow] = []
    @State private var fetchError: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Feed",
                    summary: "iOS native private feed reader. Use a real viewer user UUID to inspect the friend-only moment feed via the same backend contract already used by web.",
                    status: "Status: native private feed is live as a read-only shell; compose, reactions, and media rendering remain pending.",
                    bullets: [
                        "Paste a viewer UUID that already has accepted friendships and friend-authored moments in backend data.",
                        "This shell reads only `/moments/feed?viewer_user_id=<uuid>` and surfaces caption/media metadata.",
                        "Use web when you need to create moments; use this iOS tab to consume the resulting private feed natively."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Private feed reader")
                        .font(.headline)

                    TextField("Viewer user UUID", text: $viewerUserIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task {
                            await loadPrivateFeed()
                        }
                    } label: {
                        Text(isLoading ? "Loading private feed..." : "Load private feed")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text("Loaded moments: \(momentRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Friend-only moments")
                        .font(.headline)

                    if momentRows.isEmpty {
                        Text("No feed moments loaded for this viewer yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(momentRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.authorLabel)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(row.caption)
                                    .font(.footnote)
                                Text("visibility: \(row.visibilityScope) · media_count: \(row.mediaCount)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                if let firstMediaKey = row.firstMediaKey {
                                    Text("first_media: \(firstMediaKey)")
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Text("moment_id: \(row.id)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Feed")
    }

    private func loadPrivateFeed() async {
        let trimmedViewerID = viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedViewerID.isEmpty else {
            fetchError = "Viewer UUID là bắt buộc để load private feed."
            return
        }

        isLoading = true
        fetchError = nil

        do {
            momentRows = try await PrivateFeedAPIClient().fetchFeed(viewerUserID: trimmedViewerID)
        } catch {
            momentRows = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}

private struct PrivateFeedMomentRow: Identifiable {
    let id: String
    let authorLabel: String
    let caption: String
    let visibilityScope: String
    let mediaCount: Int
    let firstMediaKey: String?
}

private struct PrivateFeedAPIClient {
    private struct MomentListResponse: Decodable {
        let count: Int
        let items: [MomentListItem]
    }

    private struct MomentListItem: Decodable {
        let id: String
        let caption_text: String?
        let visibility_scope: String
        let author: MomentAuthorSummary
        let media_items: [MomentMediaItem]
    }

    private struct MomentAuthorSummary: Decodable {
        let id: String
        let email: String
        let username: String?
    }

    private struct MomentMediaItem: Decodable {
        let id: String
        let media_type: String
        let storage_key: String
        let mime_type: String
        let width: Int?
        let height: Int?
    }

    private struct BackendErrorPayload: Decodable {
        let detail: String?
    }

    private enum APIError: LocalizedError {
        case invalidBaseURL
        case requestFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Thiếu backend base URL hợp lệ cho private feed shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend private feed response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = URL(string: "http://127.0.0.1:8000")

    func fetchFeed(viewerUserID: String) async throws -> [PrivateFeedMomentRow] {
        let url = try makeURL(path: "/moments/feed", viewerUserID: viewerUserID)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Private feed fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MomentListResponse.self, from: data)
            return payload.items.map {
                PrivateFeedMomentRow(
                    id: $0.id,
                    authorLabel: $0.author.username ?? $0.author.email,
                    caption: $0.caption_text ?? "(no caption)",
                    visibilityScope: $0.visibility_scope,
                    mediaCount: $0.media_items.count,
                    firstMediaKey: $0.media_items.first?.storage_key
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String, viewerUserID: String) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "viewer_user_id", value: viewerUserID)]

        guard let url = components?.url else {
            throw APIError.invalidBaseURL
        }

        return url
    }

    private func requireHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        return httpResponse
    }

    private func readErrorMessage(from data: Data, statusCode: Int, prefix: String) -> String {
        if let payload = try? JSONDecoder().decode(BackendErrorPayload.self, from: data),
           let detail = payload.detail,
           !detail.isEmpty {
            return "\(prefix): \(statusCode) (\(detail))"
        }

        return "\(prefix): \(statusCode)"
    }
}
