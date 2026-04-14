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
    @State private var reactionTargetMomentIDDraft: String = ""
    @State private var reactionUserIDDraft: String = ""
    @State private var reactionTypeDraft: String = "heart"
    private let quickReactionPresets: [String] = ["heart", "fire", "smile", "wow", "clap"]
    @State private var momentRows: [PrivateFeedMomentRow] = []
    @State private var authoredMomentRows: [PrivateFeedMomentRow] = []
    @State private var reactionRows: [MomentReactionRow] = []
    @State private var statusMessage: String?
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isLoadingAuthoredMoments = false
    @State private var isCreatingMoment = false
    @State private var isLoadingReactions = false
    @State private var isCreatingReaction = false
    @State private var quickReactionMomentIDInFlight: String?
    @State private var quickReactionPreferMomentAuthor = false
    @State private var quickReactionRefreshMode: QuickReactionRefreshMode = .both

    private enum QuickReactionRefreshMode: String, CaseIterable, Identifiable {
        case none
        case privateFeed
        case authored
        case both

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none:
                return "No list refresh"
            case .privateFeed:
                return "Refresh private feed"
            case .authored:
                return "Refresh authored"
            case .both:
                return "Refresh both lists"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Feed",
                    summary: "iOS native private feed shell now supports minimal moment posting (caption + image metadata), feed reading, and moment reactions through the same backend contracts as web.",
                    status: "Status: native feed now supports create + read + reactions shell for moments; full media rendering remains pending.",
                    bullets: [
                        "Paste a viewer UUID to load `/moments/feed?viewer_user_id=<uuid>`.",
                        "Paste an author UUID to create moments via `POST /moments` + `POST /moments/{id}/media` directly from iOS.",
                        "Use reaction controls below to create/list `POST /moments/{id}/reactions` + `GET /moments/{id}/reactions` for loaded moments."
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

                    Text("Loaded private-feed moments: \(momentRows.count) · authored moments: \(authoredMomentRows.count) · reactions: \(reactionRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Moment reactions")
                        .font(.headline)

                    TextField("Reaction target moment UUID", text: $reactionTargetMomentIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if !reactionTargetMomentPresets.isEmpty {
                        Text("Quick moment presets from loaded rows")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(reactionTargetMomentPresets, id: \.self) { preset in
                                    let isSelected = normalizedReactionTargetMomentIDDraft == preset
                                    Button {
                                        reactionTargetMomentIDDraft = preset
                                    } label: {
                                        Text(shortIdentifier(preset))
                                            .font(.caption.monospaced())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .foregroundStyle(isSelected ? .primary : .secondary)
                                            .background(
                                                isSelected
                                                    ? Color.accentColor.opacity(0.22)
                                                    : Color.secondary.opacity(0.12)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    TextField("Reaction user UUID", text: $reactionUserIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if !reactionUserPresets.isEmpty {
                        Text("Quick user presets from session + loaded rows")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(reactionUserPresets, id: \.self) { preset in
                                    let isSelected = normalizedReactionUserIDDraft == preset
                                    Button {
                                        reactionUserIDDraft = preset
                                    } label: {
                                        Text(shortIdentifier(preset))
                                            .font(.caption.monospaced())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .foregroundStyle(isSelected ? .primary : .secondary)
                                            .background(
                                                isSelected
                                                    ? Color.accentColor.opacity(0.22)
                                                    : Color.secondary.opacity(0.12)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    TextField("Reaction type (heart, fire, smile...)", text: $reactionTypeDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickReactionPresets, id: \.self) { preset in
                                let isSelected = normalizedReactionTypeDraft == preset
                                Button {
                                    reactionTypeDraft = preset
                                } label: {
                                    Text(preset)
                                        .font(.footnote.monospaced())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(isSelected ? .primary : .secondary)
                                        .background(
                                            isSelected
                                                ? Color.accentColor.opacity(0.22)
                                                : Color.secondary.opacity(0.12)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Toggle(isOn: $quickReactionPreferMomentAuthor) {
                        Text("Quick react uses selected moment author as user")
                            .font(.footnote)
                    }
                    .toggleStyle(.switch)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quick react list refresh mode")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Picker("Quick react list refresh mode", selection: $quickReactionRefreshMode) {
                            ForEach(QuickReactionRefreshMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: 10) {
                        Button {
                            fillReactionFromLatestMoment()
                        } label: {
                            Text("Use latest loaded moment")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(momentRows.isEmpty && authoredMomentRows.isEmpty)

                        Button {
                            fillReactionUserFromSession()
                        } label: {
                            Text("Use session user for reaction")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(currentSessionUserID == nil)
                    }

                    Button {
                        fillReactionUserFromSelectedMomentAuthor()
                    } label: {
                        if let selectedReactionTargetMomentAuthorID {
                            Text("Use selected moment author (\(shortIdentifier(selectedReactionTargetMomentAuthorID)))")
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Use selected moment author for reaction user")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedReactionTargetMomentAuthorID == nil)

                    if let selectedReactionTargetMomentAuthorID {
                        Text("Selected moment author: \(selectedReactionTargetMomentAuthorID)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            await createMomentReaction()
                        }
                    } label: {
                        Text(isCreatingReaction ? "Creating reaction..." : "Create reaction")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        isCreatingReaction ||
                        isLoadingReactions ||
                        reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        reactionUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        reactionTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    Button {
                        Task {
                            await loadMomentReactions()
                        }
                    } label: {
                        Text(isLoadingReactions ? "Loading reactions..." : "Load reactions")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        isLoadingReactions ||
                        isCreatingReaction ||
                        reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    if reactionRows.isEmpty {
                        Text("No reactions loaded for this moment yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(reactionRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(row.reactionType) · \(row.userID)")
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                                Text("reaction_id: \(row.id)")
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
        let isReactionTargetSelected = normalizedReactionTargetMomentIDDraft == row.id
        let resolvedRowQuickReactionUserID = resolvedQuickReactionUserID(for: row)

        VStack(alignment: .leading, spacing: 8) {
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

            HStack(spacing: 8) {
                Button {
                    useMomentAsReactionTarget(row)
                } label: {
                    Text(isReactionTargetSelected ? "Reaction target selected" : "Use as reaction target")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    Task {
                        await loadReactionsForMoment(row)
                    }
                } label: {
                    Text(isLoadingReactions && isReactionTargetSelected ? "Loading reactions..." : "Load reactions for this moment")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingReactions || isCreatingReaction)
            }

            Button {
                Task {
                    await createQuickReactionForMoment(row)
                }
            } label: {
                Text(
                    quickReactionMomentIDInFlight == row.id
                        ? "Creating quick reaction..."
                        : (quickReactionPreferMomentAuthor
                            ? "Quick react from row (author mode)"
                            : "Quick react from row (current user mode)")
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                isCreatingReaction ||
                isLoadingReactions ||
                quickReactionMomentIDInFlight != nil ||
                resolvedRowQuickReactionUserID == nil ||
                normalizedReactionTypeDraft.isEmpty
            )

            Text("Refresh after quick react: \(quickReactionRefreshMode.label)")
                .font(.caption)
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

    private var latestLoadedMomentID: String? {
        momentRows.first?.id ?? authoredMomentRows.first?.id
    }

    private var normalizedReactionTypeDraft: String {
        reactionTypeDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var normalizedReactionTargetMomentIDDraft: String {
        reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedReactionUserIDDraft: String {
        reactionUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var reactionTargetMomentPresets: [String] {
        uniquePreservingOrder(momentRows.map(\.id) + authoredMomentRows.map(\.id)).prefix(6).map { $0 }
    }

    private var reactionUserPresets: [String] {
        var candidates: [String] = []

        if let currentSessionUserID {
            candidates.append(currentSessionUserID)
        }

        candidates.append(contentsOf: uniquePreservingOrder(momentRows.map(\.authorID) + authoredMomentRows.map(\.authorID)))

        return uniquePreservingOrder(candidates).prefix(6).map { $0 }
    }

    private var selectedReactionTargetMomentAuthorID: String? {
        let targetMomentID = normalizedReactionTargetMomentIDDraft
        guard !targetMomentID.isEmpty else {
            return nil
        }

        return (momentRows + authoredMomentRows)
            .first(where: { $0.id == targetMomentID })?
            .authorID
    }

    private var resolvedQuickReactionUserID: String? {
        if let currentSessionUserID {
            return currentSessionUserID
        }

        let trimmedReactionUserID = normalizedReactionUserIDDraft
        return trimmedReactionUserID.isEmpty ? nil : trimmedReactionUserID
    }

    private func resolvedQuickReactionUserID(for row: PrivateFeedMomentRow) -> String? {
        if quickReactionPreferMomentAuthor {
            let trimmedAuthorID = row.authorID.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedAuthorID.isEmpty ? nil : trimmedAuthorID
        }

        return resolvedQuickReactionUserID
    }

    private func uniquePreservingOrder(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for item in items {
            if seen.insert(item).inserted {
                ordered.append(item)
            }
        }

        return ordered
    }

    private func shortIdentifier(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 12 {
            return trimmed
        }

        let prefixPart = trimmed.prefix(6)
        let suffixPart = trimmed.suffix(4)
        return "\(prefixPart)…\(suffixPart)"
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

        if reactionUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reactionUserIDDraft = currentSessionUserID
        }
    }

    private func fillFromCurrentSessionUser() {
        guard let currentSessionUserID else {
            return
        }
        viewerUserIDDraft = currentSessionUserID
        authorUserIDDraft = currentSessionUserID
        reactionUserIDDraft = currentSessionUserID
    }

    private func fillReactionFromLatestMoment() {
        guard let latestLoadedMomentID else {
            return
        }
        reactionTargetMomentIDDraft = latestLoadedMomentID
    }

    private func fillReactionUserFromSession() {
        guard let currentSessionUserID else {
            return
        }
        reactionUserIDDraft = currentSessionUserID
    }

    private func fillReactionUserFromSelectedMomentAuthor() {
        guard let selectedReactionTargetMomentAuthorID else {
            return
        }

        reactionUserIDDraft = selectedReactionTargetMomentAuthorID
    }

    private func useMomentAsReactionTarget(_ row: PrivateFeedMomentRow) {
        reactionTargetMomentIDDraft = row.id
    }

    private func loadReactionsForMoment(_ row: PrivateFeedMomentRow) async {
        reactionTargetMomentIDDraft = row.id
        await loadMomentReactions()
    }

    private func createQuickReactionForMoment(_ row: PrivateFeedMomentRow) async {
        let trimmedReactionType = normalizedReactionTypeDraft
        guard !trimmedReactionType.isEmpty else {
            fetchError = "Reaction type là bắt buộc để quick react từ moment row."
            return
        }

        let quickReactionUserID = resolvedQuickReactionUserID(for: row)

        guard let quickReactionUserID else {
            fetchError = quickReactionPreferMomentAuthor
                ? "Author user UUID của moment là bắt buộc khi bật quick react prefer author."
                : "Reaction user UUID hoặc session user là bắt buộc để quick react từ moment row."
            return
        }

        quickReactionMomentIDInFlight = row.id
        reactionTargetMomentIDDraft = row.id
        reactionUserIDDraft = quickReactionUserID
        fetchError = nil

        do {
            _ = try await PrivateFeedAPIClient().createReaction(
                momentID: row.id,
                userID: quickReactionUserID,
                reactionType: trimmedReactionType
            )

            statusMessage = "Quick reacted moment \(row.id). Reloading reactions..."
            await loadMomentReactions()

            var refreshedTargets: [String] = []

            switch quickReactionRefreshMode {
            case .none:
                break
            case .privateFeed:
                if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("private feed")
                    await loadPrivateFeed()
                }
            case .authored:
                if !authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("authored")
                    await loadAuthoredMoments()
                }
            case .both:
                if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("private feed")
                    await loadPrivateFeed()
                }

                if !authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("authored")
                    await loadAuthoredMoments()
                }
            }

            if fetchError == nil {
                let refreshedSummary = refreshedTargets.isEmpty
                    ? "none"
                    : refreshedTargets.joined(separator: ", ")
                statusMessage = "Quick reacted moment \(row.id). Refresh mode: \(quickReactionRefreshMode.label). Refreshed \(refreshedTargets.count) list(s): \(refreshedSummary)."
            }
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        quickReactionMomentIDInFlight = nil
    }

    private func synchronizeReactionTargetWithLoadedMoments() {
        guard let latestLoadedMomentID else {
            reactionRows = []
            return
        }

        let trimmedReactionTargetMomentID = reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let loadedMomentIDs = momentRows.map(\.id) + authoredMomentRows.map(\.id)

        if trimmedReactionTargetMomentID.isEmpty || !loadedMomentIDs.contains(trimmedReactionTargetMomentID) {
            reactionTargetMomentIDDraft = latestLoadedMomentID
            reactionRows = []
        }
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
            synchronizeReactionTargetWithLoadedMoments()
            statusMessage = "Loaded \(momentRows.count) private feed moment(s)."
        } catch {
            momentRows = []
            synchronizeReactionTargetWithLoadedMoments()
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
            synchronizeReactionTargetWithLoadedMoments()
            statusMessage = "Loaded \(authoredMomentRows.count) authored moment(s)."
        } catch {
            authoredMomentRows = []
            synchronizeReactionTargetWithLoadedMoments()
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
            reactionTargetMomentIDDraft = createdMomentID
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

    private func loadMomentReactions() async {
        let trimmedMomentID = reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMomentID.isEmpty else {
            fetchError = "Reaction target moment UUID là bắt buộc để load reactions."
            return
        }

        isLoadingReactions = true
        fetchError = nil

        do {
            reactionRows = try await PrivateFeedAPIClient().fetchReactions(momentID: trimmedMomentID)
            statusMessage = "Loaded \(reactionRows.count) reaction(s) for moment \(trimmedMomentID)."
        } catch {
            reactionRows = []
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoadingReactions = false
    }

    private func createMomentReaction() async {
        let trimmedMomentID = reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReactionUserID = reactionUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReactionType = reactionTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMomentID.isEmpty else {
            fetchError = "Reaction target moment UUID là bắt buộc để create reaction."
            return
        }

        guard !trimmedReactionUserID.isEmpty else {
            fetchError = "Reaction user UUID là bắt buộc để create reaction."
            return
        }

        guard !trimmedReactionType.isEmpty else {
            fetchError = "Reaction type là bắt buộc để create reaction."
            return
        }

        isCreatingReaction = true
        fetchError = nil

        do {
            _ = try await PrivateFeedAPIClient().createReaction(
                momentID: trimmedMomentID,
                userID: trimmedReactionUserID,
                reactionType: trimmedReactionType
            )
            statusMessage = "Created reaction on moment \(trimmedMomentID). Reloading reactions..."
            await loadMomentReactions()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingReaction = false
    }
}

private struct PrivateFeedMomentRow: Identifiable {
    let id: String
    let authorID: String
    let authorLabel: String
    let caption: String
    let visibilityScope: String
    let mediaCount: Int
    let firstMediaKey: String?
}

private struct MomentReactionRow: Identifiable {
    let id: String
    let userID: String
    let reactionType: String
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

    private struct MomentReactionCreateRequest: Encodable {
        let user_id: String
        let reaction_type: String
    }

    private struct MomentReactionListResponse: Decodable {
        let count: Int
        let items: [MomentReactionItem]
    }

    private struct MomentReactionItem: Decodable {
        let id: String
        let user_id: String
        let reaction_type: String
    }

    private struct MomentReactionResponse: Decodable {
        let id: String
        let user_id: String
        let reaction_type: String
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

    func fetchReactions(momentID: String) async throws -> [MomentReactionRow] {
        let url = try makeURL(path: "/moments/\(momentID)/reactions")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Moment reactions fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MomentReactionListResponse.self, from: data)
            return payload.items.map {
                MomentReactionRow(id: $0.id, userID: $0.user_id, reactionType: $0.reaction_type)
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createReaction(momentID: String, userID: String, reactionType: String) async throws -> MomentReactionRow {
        var request = URLRequest(url: try makeURL(path: "/moments/\(momentID)/reactions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MomentReactionCreateRequest(user_id: userID, reaction_type: reactionType)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Moment reaction create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MomentReactionResponse.self, from: data)
            return MomentReactionRow(id: payload.id, userID: payload.user_id, reactionType: payload.reaction_type)
        } catch {
            throw APIError.invalidResponse
        }
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
                    authorID: $0.author.id,
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
