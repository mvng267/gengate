import SwiftUI

struct LocationPlaceholderView: View {
    @State private var ownerUserIDDraft: String = ""
    @State private var shareIDDraft: String = ""
    @State private var snapshotCount: Int?
    @State private var audienceCount: Int?
    @State private var totalShareCount: Int?
    @State private var fetchError: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Location",
                    summary: "iOS native location status reader. Use an owner UUID to inspect snapshot counts and optionally a share UUID to inspect audience counts via the backend contracts already available.",
                    status: "Status: native location surface is live as a read-only status shell. Map rendering, permission flow, and share mutation stay out of scope for this slice.",
                    bullets: [
                        "Paste an owner UUID to read that owner's location snapshot count.",
                        "Optionally paste a location share UUID if one was already created via web/backend to inspect audience count.",
                        "This shell stays honest to the current backend contract: count/status only, no fake map or detailed snapshot list."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Location status reader")
                        .font(.headline)

                    TextField("Owner user UUID", text: $ownerUserIDDraft)
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
                    statusRow(label: "snapshot_count", value: snapshotCount.map(String.init) ?? "not loaded")
                    statusRow(label: "total_share_count", value: totalShareCount.map(String.init) ?? "not loaded")
                    statusRow(label: "audience_count", value: audienceCount.map(String.init) ?? (shareIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "optional share UUID not provided" : "not loaded"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Location")
    }

    private func loadLocationStatus() async {
        let trimmedOwnerID = ownerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedShareID = shareIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

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
        } catch {
            snapshotCount = nil
            totalShareCount = nil
            audienceCount = nil
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
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

private struct LocationStatusAPIClient {
    private struct CountResponse: Decodable {
        let count: Int
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

    private let baseURL = URL(string: "http://127.0.0.1:8000")

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
