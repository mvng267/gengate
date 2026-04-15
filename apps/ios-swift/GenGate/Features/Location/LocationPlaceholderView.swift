import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LocationPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var ownerUserIDDraft: String = ""
    @State private var allowedUserIDDraft: String = ""
    @State private var shareIDDraft: String = ""
    @State private var audienceIDDraft: String = ""
    @State private var snapshotCount: Int?
    @State private var audienceCount: Int?
    @State private var totalShareCount: Int?
    @State private var createdShareID: String?
    @State private var createdAudienceID: String?
    @State private var fetchError: String?
    @State private var statusMessage: String?
    @State private var lastCopiedLocationStateSummary: String = ""
    @State private var quickLocationStateCopiedAt: Date?
    @State private var isLoading = false
    @State private var isCreatingShare = false
    @State private var isCreatingAudience = false
    @State private var isRemovingAudience = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Location",
                    summary: "iOS native location status shell now supports minimal share/audience mutations plus count reading via existing backend contracts.",
                    status: "Status: native location now supports create share + add audience + count checks; map rendering and permission flow stay out of scope.",
                    bullets: [
                        "Paste an owner UUID to read location snapshot/share counts.",
                        "Create a share via `POST /locations/shares`, then optionally add audience via `POST /locations/shares/{share_id}/audience`.",
                        "Use counts and IDs below to verify location-sharing state transitions without fake map UI."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Location status + mutation shell")
                        .font(.headline)

                    TextField("Owner user UUID", text: $ownerUserIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Allowed user UUID (optional)", text: $allowedUserIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Location share UUID (optional)", text: $shareIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Audience UUID (optional)", text: $audienceIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Use current session user as owner") {
                        fillFromCurrentSessionUser()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button {
                        Task {
                            await loadLocationStatus()
                        }
                    } label: {
                        Text(isLoading ? "Loading location status..." : "Load location status")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        Task {
                            await createLocationShare()
                        }
                    } label: {
                        Text(isCreatingShare ? "Creating location share..." : "Create location share")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        isCreatingShare ||
                        isLoading ||
                        ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    Button {
                        Task {
                            await addAudienceToShare()
                        }
                    } label: {
                        Text(isCreatingAudience ? "Adding audience..." : "Add audience to share")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        isCreatingAudience ||
                        isRemovingAudience ||
                        isLoading ||
                        effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        allowedUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    Button {
                        Task {
                            await removeAudienceFromShare()
                        }
                    } label: {
                        Text(isRemovingAudience ? "Removing audience..." : "Remove audience from share")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        isRemovingAudience ||
                        isCreatingAudience ||
                        isLoading ||
                        effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        effectiveAudienceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

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

                    Text("Quick location state summary: \(quickLocationStateSummaryLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Button("Copy quick location state summary") {
                        copyQuickLocationStateSummaryToClipboard()
                    }
                    .buttonStyle(.bordered)

                    if let quickLocationStateCopiedFeedbackText {
                        Text(quickLocationStateCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Current location shell status")
                        .font(.headline)

                    statusRow(label: "owner_user_id", value: ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(not set)" : ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                    statusRow(label: "allowed_user_id", value: allowedUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(optional/not set)" : allowedUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                    statusRow(label: "active_share_id", value: effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(not set)" : effectiveShareID)
                    statusRow(label: "active_audience_id", value: effectiveAudienceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(not set)" : effectiveAudienceID)
                    statusRow(label: "snapshot_count", value: snapshotCount.map(String.init) ?? "not loaded")
                    statusRow(label: "total_share_count", value: totalShareCount.map(String.init) ?? "not loaded")
                    statusRow(label: "audience_count", value: audienceCount.map(String.init) ?? (effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "share UUID not provided/created" : "not loaded"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Location")
        .onAppear {
            prefillFromCurrentSessionUserIfNeeded()
        }
    }

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
    }

    private var effectiveShareID: String {
        let trimmedManualShareID = shareIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedManualShareID.isEmpty {
            return trimmedManualShareID
        }

        return createdShareID ?? ""
    }

    private var effectiveAudienceID: String {
        let trimmedManualAudienceID = audienceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedManualAudienceID.isEmpty {
            return trimmedManualAudienceID
        }

        return createdAudienceID ?? ""
    }

    private var quickLocationStateSummaryLine: String {
        let normalizedOwner = ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedShareID = effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAudienceCount = audienceCount.map(String.init) ?? "(not_loaded)"
        let normalizedSnapshotCount = snapshotCount.map(String.init) ?? "(not_loaded)"
        let normalizedSharingMode = "custom_list"
        let normalizedIsActive = normalizedShareID.isEmpty ? "(unknown)" : "true"

        return "owner=\(normalizedOwner.isEmpty ? "(empty)" : normalizedOwner) / " +
            "share_id=\(normalizedShareID.isEmpty ? "(none)" : normalizedShareID) / " +
            "is_active=\(normalizedIsActive) / " +
            "sharing_mode=\(normalizedSharingMode) / " +
            "audience_count=\(normalizedAudienceCount) / " +
            "snapshot_count=\(normalizedSnapshotCount)"
    }

    private var quickLocationStateCopiedFeedbackText: String? {
        guard let quickLocationStateCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(quickLocationStateCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied location state summary (\(Int(elapsed))s ago): \(lastCopiedLocationStateSummary)"
    }

    private func copyQuickLocationStateSummaryToClipboard() {
        let summaryLine = quickLocationStateSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summaryLine.isEmpty else {
            statusMessage = nil
            fetchError = "quick_location_state_summary_empty"
            return
        }

#if canImport(UIKit)
        UIPasteboard.general.string = summaryLine
        lastCopiedLocationStateSummary = summaryLine
        quickLocationStateCopiedAt = Date()
        statusMessage = "Copied quick location state summary to clipboard."
        fetchError = nil
#else
        statusMessage = "quick_copy_clipboard_unavailable"
        fetchError = nil
#endif
    }

    private func prefillFromCurrentSessionUserIfNeeded() {
        guard ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        ownerUserIDDraft = currentSessionUserID
    }

    private func fillFromCurrentSessionUser() {
        guard let currentSessionUserID else {
            return
        }
        ownerUserIDDraft = currentSessionUserID
    }

    private func loadLocationStatus() async {
        let trimmedOwnerID = ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedShareID = effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOwnerID.isEmpty else {
            fetchError = "Owner UUID là bắt buộc để load location status."
            return
        }

        isLoading = true
        fetchError = nil

        do {
            let apiClient = LocationStatusAPIClient()
            async let snapshotCountResult = apiClient.fetchSnapshotCount(ownerUserID: trimmedOwnerID)
            async let totalShareCountResult = apiClient.fetchTotalShareCount()

            let loadedSnapshotCount = try await snapshotCountResult
            let loadedTotalShareCount = try await totalShareCountResult

            snapshotCount = loadedSnapshotCount
            totalShareCount = loadedTotalShareCount

            if trimmedShareID.isEmpty {
                audienceCount = nil
            } else {
                audienceCount = try await apiClient.fetchAudienceCount(shareID: trimmedShareID)
            }

            statusMessage = "Loaded location status counts successfully."
        } catch {
            snapshotCount = nil
            totalShareCount = nil
            audienceCount = nil
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func createLocationShare() async {
        let trimmedOwnerID = ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOwnerID.isEmpty else {
            fetchError = "Owner UUID là bắt buộc để tạo location share."
            return
        }

        isCreatingShare = true
        fetchError = nil

        do {
            let createdShare = try await LocationStatusAPIClient().createShare(ownerUserID: trimmedOwnerID)
            createdShareID = createdShare.id
            shareIDDraft = createdShare.id
            createdAudienceID = nil
            audienceIDDraft = ""
            statusMessage = "Created location share \(createdShare.id). Reloading status..."
            await loadLocationStatus()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingShare = false
    }

    private func addAudienceToShare() async {
        let trimmedShareID = effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAllowedUserID = allowedUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedShareID.isEmpty else {
            fetchError = "Cần share UUID để thêm audience."
            return
        }

        guard !trimmedAllowedUserID.isEmpty else {
            fetchError = "Allowed user UUID là bắt buộc để thêm audience."
            return
        }

        isCreatingAudience = true
        fetchError = nil

        do {
            let createdAudience = try await LocationStatusAPIClient().createShareAudience(shareID: trimmedShareID, allowedUserID: trimmedAllowedUserID)
            createdAudienceID = createdAudience.id
            audienceIDDraft = createdAudience.id
            statusMessage = "Added audience \(createdAudience.id) to share \(trimmedShareID). Reloading status..."
            await loadLocationStatus()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingAudience = false
    }

    private func removeAudienceFromShare() async {
        let trimmedShareID = effectiveShareID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAudienceID = effectiveAudienceID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedShareID.isEmpty else {
            fetchError = "Cần share UUID để xóa audience."
            return
        }

        guard !trimmedAudienceID.isEmpty else {
            fetchError = "Cần audience UUID để xóa khỏi share."
            return
        }

        isRemovingAudience = true
        fetchError = nil

        do {
            try await LocationStatusAPIClient().removeShareAudience(shareID: trimmedShareID, audienceID: trimmedAudienceID)
            if createdAudienceID == trimmedAudienceID {
                createdAudienceID = nil
            }
            if audienceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedAudienceID {
                audienceIDDraft = ""
            }
            statusMessage = "Removed audience \(trimmedAudienceID) from share \(trimmedShareID). Reloading status..."
            await loadLocationStatus()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isRemovingAudience = false
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.monospaced())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LocationShareCreateResult {
    let id: String
    let ownerUserID: String
    let isActive: Bool
    let sharingMode: String
}

private struct LocationShareAudienceCreateResult {
    let id: String
    let locationShareID: String
    let allowedUserID: String
}

private struct LocationStatusAPIClient {
    private struct CountResponse: Decodable {
        let count: Int
    }

    private struct ShareCreateRequest: Encodable {
        let owner_user_id: String
        let is_active: Bool
        let sharing_mode: String
    }

    private struct ShareResponse: Decodable {
        let id: String
        let owner_user_id: String
        let is_active: Bool
        let sharing_mode: String
    }

    private struct ShareAudienceCreateRequest: Encodable {
        let allowed_user_id: String
    }

    private struct ShareAudienceResponse: Decodable {
        let id: String
        let location_share_id: String
        let allowed_user_id: String
    }

    private struct ShareAudienceDeleteResponse: Decodable {
        let status: String
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
                return "Thiếu backend base URL hợp lệ cho location shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend location response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchSnapshotCount(ownerUserID: String) async throws -> Int {
        let url = try makeURL(path: "/locations/snapshots/\(ownerUserID)")
        return try await fetchCount(from: url, prefix: "Location snapshot count fetch failed")
    }

    func fetchTotalShareCount() async throws -> Int {
        let url = try makeURL(path: "/locations/shares")
        return try await fetchCount(from: url, prefix: "Location share count fetch failed")
    }

    func fetchAudienceCount(shareID: String) async throws -> Int {
        let url = try makeURL(path: "/locations/shares/\(shareID)/audience")
        return try await fetchCount(from: url, prefix: "Location audience count fetch failed")
    }

    func createShare(ownerUserID: String) async throws -> LocationShareCreateResult {
        var request = URLRequest(url: try makeURL(path: "/locations/shares"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ShareCreateRequest(
                owner_user_id: ownerUserID,
                is_active: true,
                sharing_mode: "custom_list"
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Location share create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ShareResponse.self, from: data)
            return LocationShareCreateResult(
                id: payload.id,
                ownerUserID: payload.owner_user_id,
                isActive: payload.is_active,
                sharingMode: payload.sharing_mode
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createShareAudience(shareID: String, allowedUserID: String) async throws -> LocationShareAudienceCreateResult {
        var request = URLRequest(url: try makeURL(path: "/locations/shares/\(shareID)/audience"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ShareAudienceCreateRequest(allowed_user_id: allowedUserID))

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Location share audience create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ShareAudienceResponse.self, from: data)
            return LocationShareAudienceCreateResult(
                id: payload.id,
                locationShareID: payload.location_share_id,
                allowedUserID: payload.allowed_user_id
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func removeShareAudience(shareID: String, audienceID: String) async throws {
        var request = URLRequest(url: try makeURL(path: "/locations/shares/\(shareID)/audience/\(audienceID)"))
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Location share audience remove failed"))
        }

        do {
            _ = try JSONDecoder().decode(ShareAudienceDeleteResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func fetchCount(from url: URL, prefix: String) async throws -> Int {
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: prefix))
        }

        do {
            let payload = try JSONDecoder().decode(CountResponse.self, from: data)
            return payload.count
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        return baseURL.appendingPathComponent(path)
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
