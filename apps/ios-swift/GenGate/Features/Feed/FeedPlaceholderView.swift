import SwiftUI

struct FeedPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var viewerUserIDDraft: String = ""
    @State private var authorUserIDDraft: String = ""
    @State private var captionDraft: String = ""
    @State private var imageStorageKeyDraft: String = "moments/demo-image.jpg"
    @State private var imageMimeTypeDraft: String = "image/jpeg"
    @State private var imageWidthDraft: String = "1080"
    @State private var imageHeightDraft: String = "1350"
    @State private var momentRows: [PrivateFeedMomentRow] = []
    @State private var authoredMomentRows: [PrivateFeedMomentRow] = []
    @State private var statusMessage: String?
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isLoadingAuthoredMoments = false
    @State private var isCreatingMoment = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Feed",
                    summary: "iOS native private feed shell now supports minimal moment posting (caption + image metadata) and feed reading through the same backend contracts as web.",
                    status: "Status: native feed now supports create + read shell for moments; reactions and full media rendering remain pending.",
                    bullets: [
                        "Paste a viewer UUID to load `/moments/feed?viewer_user_id=<uuid>`.",
                        "Paste an author UUID to create moments via `POST /moments` + `POST /moments/{id}/media` directly from iOS.",
                        "Use authored list below to verify create flow even when private feed visibility does not include the same author account."
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

                    Button("Use current session user for viewer + author") {
                        fillFromCurrentSessionUser()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create moment + image")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Author user UUID", text: $authorUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Caption", text: $captionDraft)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Image storage key", text: $imageStorageKeyDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Image MIME type", text: $imageMimeTypeDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 8) {
                            TextField("Width", text: $imageWidthDraft)
#if os(iOS)
                                .keyboardType(.numberPad)
#endif
                                .padding(12)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            TextField("Height", text: $imageHeightDraft)
#if os(iOS)
                                .keyboardType(.numberPad)
#endif
                                .padding(12)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            Task {
                                await createMomentWithImage()
                            }
                        } label: {
                            Text(isCreatingMoment ? "Creating moment..." : "Create moment + image")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isCreatingMoment ||
                            isLoading ||
                            authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            imageStorageKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            imageMimeTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button {
                            Task {
                                await loadAuthoredMoments()
                            }
                        } label: {
                            Text(isLoadingAuthoredMoments ? "Loading authored moments..." : "Load authored moments")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoadingAuthoredMoments ||
                            isCreatingMoment ||
                            authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    if let currentSessionUserID {
                        Text("Current session user_id: \(currentSessionUserID)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text("Loaded private-feed moments: \(momentRows.count) · authored moments: \(authoredMomentRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Friend-only feed moments")
                        .font(.headline)

                    if momentRows.isEmpty {
                        Text("No feed moments loaded for this viewer yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(momentRows) { row in
                            momentRow(row)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Authored moments (create verification)")
                        .font(.headline)

                    if authoredMomentRows.isEmpty {
                        Text("No authored moments loaded for this author yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(authoredMomentRows) { row in
                            momentRow(row)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Feed")
        .onAppear {
            prefillFromCurrentSessionUserIfNeeded()
        }
    }

    @ViewBuilder
    private func momentRow(_ row: PrivateFeedMomentRow) -> some View {
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

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
    }

    private func prefillFromCurrentSessionUserIfNeeded() {
        guard let currentSessionUserID else {
            return
        }

        if viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewerUserIDDraft = currentSessionUserID
        }

        if authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authorUserIDDraft = currentSessionUserID
        }
    }

    private func fillFromCurrentSessionUser() {
        guard let currentSessionUserID else {
            return
        }
        viewerUserIDDraft = currentSessionUserID
        authorUserIDDraft = currentSessionUserID
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
            statusMessage = "Loaded \(momentRows.count) private feed moment(s)."
        } catch {
            momentRows = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func loadAuthoredMoments() async {
        let trimmedAuthorID = authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAuthorID.isEmpty else {
            fetchError = "Author UUID là bắt buộc để load authored moments."
            return
        }

        isLoadingAuthoredMoments = true
        fetchError = nil

        do {
            authoredMomentRows = try await PrivateFeedAPIClient().fetchAuthoredMoments(authorUserID: trimmedAuthorID)
            statusMessage = "Loaded \(authoredMomentRows.count) authored moment(s)."
        } catch {
            authoredMomentRows = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoadingAuthoredMoments = false
    }

    private func createMomentWithImage() async {
        let trimmedAuthorID = authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = captionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStorageKey = imageStorageKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMimeType = imageMimeTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedWidth = Int(imageWidthDraft.trimmingCharacters(in: .whitespacesAndNewlines))
        let parsedHeight = Int(imageHeightDraft.trimmingCharacters(in: .whitespacesAndNewlines))

        guard !trimmedAuthorID.isEmpty else {
            fetchError = "Author UUID là bắt buộc để create moment."
            return
        }

        guard !trimmedStorageKey.isEmpty else {
            fetchError = "Image storage key là bắt buộc để create moment media."
            return
        }

        guard !trimmedMimeType.isEmpty else {
            fetchError = "Image MIME type là bắt buộc để create moment media."
            return
        }

        isCreatingMoment = true
        fetchError = nil

        do {
            let createdMomentID = try await PrivateFeedAPIClient().createMomentWithImage(
                authorUserID: trimmedAuthorID,
                captionText: trimmedCaption.isEmpty ? nil : trimmedCaption,
                imageStorageKey: trimmedStorageKey,
                imageMimeType: trimmedMimeType,
                imageWidth: parsedWidth,
                imageHeight: parsedHeight
            )

            captionDraft = ""
            statusMessage = "Created moment \(createdMomentID). Reloading authored list..."
            await loadAuthoredMoments()

            if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadPrivateFeed()
            }
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingMoment = false
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

    private struct MomentCreateRequest: Encodable {
        let author_user_id: String
        let caption_text: String?
    }

    private struct MomentCreateResponse: Decodable {
        let id: String
    }

    private struct MomentMediaCreateRequest: Encodable {
        let media_type: String
        let storage_key: String
        let mime_type: String
        let width: Int?
        let height: Int?
    }

    private struct MomentMediaResponse: Decodable {
        let id: String
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

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchFeed(viewerUserID: String) async throws -> [PrivateFeedMomentRow] {
        let url = try makeURL(path: "/moments/feed", queryItems: [URLQueryItem(name: "viewer_user_id", value: viewerUserID)])
        return try await fetchMomentRows(from: url, prefix: "Private feed fetch failed")
    }

    func fetchAuthoredMoments(authorUserID: String) async throws -> [PrivateFeedMomentRow] {
        let url = try makeURL(path: "/moments", queryItems: [URLQueryItem(name: "author_user_id", value: authorUserID)])
        return try await fetchMomentRows(from: url, prefix: "Authored moments fetch failed")
    }

    func createMomentWithImage(
        authorUserID: String,
        captionText: String?,
        imageStorageKey: String,
        imageMimeType: String,
        imageWidth: Int?,
        imageHeight: Int?
    ) async throws -> String {
        let createdMoment = try await createMoment(authorUserID: authorUserID, captionText: captionText)
        _ = try await createMomentMedia(
            momentID: createdMoment.id,
            storageKey: imageStorageKey,
            mimeType: imageMimeType,
            width: imageWidth,
            height: imageHeight
        )
        return createdMoment.id
    }

    private func fetchMomentRows(from url: URL, prefix: String) async throws -> [PrivateFeedMomentRow] {
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: prefix))
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

    private func createMoment(authorUserID: String, captionText: String?) async throws -> MomentCreateResponse {
        var request = URLRequest(url: try makeURL(path: "/moments"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MomentCreateRequest(author_user_id: authorUserID, caption_text: captionText)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Moment create failed"))
        }

        do {
            return try JSONDecoder().decode(MomentCreateResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func createMomentMedia(
        momentID: String,
        storageKey: String,
        mimeType: String,
        width: Int?,
        height: Int?
    ) async throws -> MomentMediaResponse {
        var request = URLRequest(url: try makeURL(path: "/moments/\(momentID)/media"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MomentMediaCreateRequest(
                media_type: "image",
                storage_key: storageKey,
                mime_type: mimeType,
                width: width,
                height: height
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Moment media create failed"))
        }

        do {
            return try JSONDecoder().decode(MomentMediaResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

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
