import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FeedPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var viewerUserIDDraft: String = ""
    @State private var authorUserIDDraft: String = ""
    @State private var captionDraft: String = ""
    @State private var imageStorageKeyDraft: String = "moments/demo-image.jpg"
    @State private var imageMimeTypeDraft: String = "image/jpeg"
    @State private var imageWidthDraft: String = "1080"
    @State private var imageHeightDraft: String = "1350"
    @State private var deleteMomentIDDraft: String = ""
    @State private var reactionTargetMomentIDDraft: String = ""
    @State private var reactionUserIDDraft: String = ""
    @State private var reactionTypeDraft: String = "heart"
    private let quickReactionPresets: [String] = ["heart", "fire", "smile", "wow", "clap"]
    @State private var momentRows: [PrivateFeedMomentRow] = []
    @State private var authoredMomentRows: [PrivateFeedMomentRow] = []
    @State private var reactionRows: [MomentReactionRow] = []
    @State private var statusMessage: String?
    @State private var fetchError: String?
    @State private var latestQuickReactionLog: String?
    @State private var lastCreateFeedVisibilityDeltaLine: String?
    @State private var lastCreateFeedGateSummaryLine: String?
    @State private var lastDeletedMomentSummaryLine: String?
    @State private var feedVisibilityGateSnapshotSource: String = "reload_flow"
    @State private var lastCreateFeedVisibilityDeltaCopiedAt: Date?
    @State private var lastCreateFeedVisibilityDeltaCopiedText: String = ""
    @State private var lastCreateFeedGateBundleCopiedText: String = ""
    @State private var lastCreateFeedGateBundleCopiedAt: Date?
    @State private var lastCreateFeedGateSnapshotBundleCopiedText: String = ""
    @State private var lastCreateFeedGateSnapshotBundleCopiedAt: Date?
    @State private var lastDeleteSummaryCopiedAt: Date?
    @State private var lastDeleteSummaryCopiedText: String = ""
    @State private var lastDeleteFeedGateBundleCopiedAt: Date?
    @State private var lastDeleteFeedGateBundleCopiedText: String = ""
    @State private var deleteSnapshotSource: String = "manual_input"
    @State private var deleteCopyAuditSourceDraft: String = "quick_delete_parity"
    @State private var lastDeleteCopyAuditLine: String?
    @State private var lastDeleteCopyAuditFirstReadySourceLine: String?
    @State private var lastDeleteCopyAuditSourceStateSnapshotLine: String?
    @State private var lastDeleteCopyAuditSourceStateSnapshotSourceLine: String?
    @State private var isLoading = false
    @State private var isLoadingAuthoredMoments = false
    @State private var isCreatingMoment = false
    @State private var isDeletingMoment = false
    @State private var isLoadingReactions = false
    @State private var isCreatingReaction = false
    @State private var quickReactionMomentIDInFlight: String?
    @State private var deleteMomentIDInFlight: String?
    @State private var requireDeleteConfirmation = true
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

        var shortLabel: String {
            switch self {
            case .none:
                return "none"
            case .privateFeed:
                return "private"
            case .authored:
                return "authored"
            case .both:
                return "both"
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

                    Button("Use current session user as create author") {
                        applyCurrentSessionUserAsCreateAuthor()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isCreatingMoment)

                    Button("Use current session user as author + create moment + reload feed") {
                        Task {
                            await applyCurrentSessionUserAsAuthorCreateAndReloadFeed()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isCreatingMoment || isLoading || isDeletingMoment)

                    Button("Use current session user as viewer + author + create moment + reload feed") {
                        Task {
                            await applyCurrentSessionUserAsViewerAuthorCreateAndReloadFeed()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isCreatingMoment || isLoading || isDeletingMoment)

                    Button("Use current session user as viewer + keep author + load private feed") {
                        Task {
                            await applyCurrentSessionUserAsViewerKeepAuthorAndLoadPrivateFeed()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isCreatingMoment || isLoading || isDeletingMoment)

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

                        TextField("Moment ID to delete", text: $deleteMomentIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .onChange(of: deleteMomentIDDraft, initial: false) { _, newValue in
                                let normalizedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if deleteSnapshotSource == "preset_row",
                                   normalizedValue == normalizedDeleteMomentIDDraft,
                                   !normalizedValue.isEmpty {
                                    return
                                }

                                deleteSnapshotSource = "manual_input"
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !deleteMomentPresets.isEmpty {
                            Text("Quick delete presets from loaded rows")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(deleteMomentPresets, id: \.self) { preset in
                                        let isSelected = normalizedDeleteMomentIDDraft == preset
                                        Button {
                                            deleteMomentIDDraft = preset
                                            deleteSnapshotSource = "preset_row"
                                            statusMessage = "Delete target set from loaded moment."
                                            fetchError = nil
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

                        Toggle(isOn: $requireDeleteConfirmation) {
                            Text("Require confirmation for row delete")
                                .font(.footnote)
                        }
                        .toggleStyle(.switch)
                        .onChange(of: requireDeleteConfirmation, initial: false) { _, isLocked in
                            statusMessage = isLocked
                                ? "Row delete lock is on again."
                                : "Row delete unlocked. You can tap `Delete this moment` on a row now."
                            fetchError = nil
                        }

                        Text(
                            requireDeleteConfirmation
                                ? "One-tap row delete đang khóa. Tắt toggle để mở `Delete this moment` ở từng row."
                                : "One-tap row delete đã mở khoá. Có thể dùng `Delete this moment` trực tiếp từ row."
                        )
                        .font(.caption)
                        .foregroundStyle(requireDeleteConfirmation ? .orange : .green)

                        Button {
                            Task {
                                await deleteMoment()
                            }
                        } label: {
                            Text(isDeletingMoment ? "Deleting moment..." : "Delete moment")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isDeletingMoment ||
                            isCreatingMoment ||
                            deleteMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    if let momentCreateQuickCopySummary {
                        Text("Quick copy payload: \(momentCreateQuickCopySummary)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    if let privateFeedQuickCopySummary {
                        Text("Quick copy feed: \(privateFeedQuickCopySummary)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Text("Quick feed visibility gate summary: \(quickFeedVisibilityGateSummaryLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Text("Quick create + feed-gate bundle: \(quickCreateFeedGateBundleLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick feed visibility delta") {
                            copyQuickFeedVisibilityDeltaSummary()
                        }
                        .buttonStyle(.bordered)

                        Button("Copy quick feed visibility gate summary") {
                            copyQuickFeedVisibilityGateSummary()
                        }
                        .buttonStyle(.bordered)

                        Button("Copy quick create + feed-gate bundle") {
                            copyQuickCreateFeedGateBundleLine()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let lastCreateFeedVisibilityDeltaLine {
                        Text("Last create feed visibility delta: \(lastCreateFeedVisibilityDeltaLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy last create feed visibility delta") {
                            copyLastCreateFeedVisibilityDeltaLine()
                        }
                        .buttonStyle(.bordered)

                        if let lastCreateFeedGateBundleLine {
                            Text("Last create + feed-gate bundle: \(lastCreateFeedGateBundleLine)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)

                            Button("Copy last create + feed-gate bundle") {
                                copyLastCreateFeedGateBundleLine()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let lastCreateFeedVisibilityDeltaCopiedFeedbackText {
                        Text(lastCreateFeedVisibilityDeltaCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let lastCreateFeedGateBundleCopiedFeedbackText {
                        Text(lastCreateFeedGateBundleCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let lastCreateFeedGateSnapshotBundleCopiedFeedbackText {
                        Text(lastCreateFeedGateSnapshotBundleCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("Quick delete parity summary: \(quickDeleteParitySummaryLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Button("Copy quick delete parity summary") {
                        copyQuickDeleteParitySummaryLine()
                    }
                    .buttonStyle(.bordered)

                    if let lastDeletedMomentSummaryLine {
                        Text("Last delete result summary: \(lastDeletedMomentSummaryLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy last delete result summary") {
                            copyLastDeleteResultSummaryLine()
                        }
                        .buttonStyle(.bordered)

                        if let lastDeleteFeedGateBundleLine {
                            Text("Last delete + feed-gate bundle: \(lastDeleteFeedGateBundleLine)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)

                            Button("Copy last delete + feed-gate bundle") {
                                copyLastDeleteFeedGateBundleLine()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let lastDeleteSummaryCopiedFeedbackText {
                        Text(lastDeleteSummaryCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button("Copy copied delete summary feedback") {
                            copyLastDeleteSummaryCopiedFeedbackText()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let lastDeleteFeedGateBundleCopiedFeedbackText {
                        Text(lastDeleteFeedGateBundleCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("Delete copy audit source-state: \(deleteCopyAuditSourceStateLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text("Delete copy audit first-ready source: \(lastDeleteCopyAuditFirstReadySourceLine ?? "delete_copy_audit_first_ready_source=(not_run)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text("Last source-state snapshot: \(lastDeleteCopyAuditSourceStateSnapshotLine ?? "last_source_state_snapshot=(not_run)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text("Last source-state snapshot source: \(lastDeleteCopyAuditSourceStateSnapshotSourceLine ?? "last_source_state_snapshot_source=(not_run)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Button("Copy delete copy audit source-state line") {
                        copyDeleteCopyAuditSourceStateLine()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy delete copy audit source-state snapshot line") {
                        copyDeleteCopyAuditSourceStateSnapshotLine()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy last source-state snapshot line") {
                        copyLastDeleteCopyAuditSourceStateSnapshotLine()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy last source-state snapshot source line") {
                        copyLastDeleteCopyAuditSourceStateSnapshotSourceLine()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy delete copy audit first-ready source line") {
                        copyDeleteCopyAuditFirstReadySourceLine()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy delete copy audit for first ready source") {
                        copyDeleteCopyAuditForFirstReadySource()
                    }
                    .buttonStyle(.bordered)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delete copy audit source")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(deleteCopyAuditSourceOptions, id: \.self) { source in
                                    let isSelected = deleteCopyAuditSourceDraft == source
                                    Button {
                                        copyDeleteCopyAuditLineForSource(source)
                                    } label: {
                                        Text(source)
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

                    if let lastDeleteCopyAuditLine {
                        Text("Delete copy audit: \(lastDeleteCopyAuditLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy delete copy audit line") {
                            copyDeleteCopyAuditLine()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)

                        if let feedErrorHint {
                            Text("Hint: \(feedErrorHint)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if latestQuickReactionLog != nil {
                        HStack(spacing: 8) {
                            Button {
                                copyLatestQuickReactionLogToClipboard()
                            } label: {
                                Text("Copy latest quick-react log")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                clearLatestQuickReactionLog()
                            } label: {
                                Text("Clear quick-react log")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
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
                    useMomentAuthorAsCreateAuthor(row)
                } label: {
                    Text(normalizedAuthorUserIDDraft == row.authorID ? "Author selected" : "Use author for create")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isCreatingMoment || normalizedAuthorUserIDDraft == row.authorID)

                Button {
                    useMomentIDForDelete(row)
                } label: {
                    Text(normalizedDeleteMomentIDDraft == row.id ? "Delete id selected" : "Use row id for delete")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isDeletingMoment || normalizedDeleteMomentIDDraft == row.id)

                Button {
                    Task {
                        await deleteMomentFromRow(row)
                    }
                } label: {
                    Text(
                        deleteMomentIDInFlight == row.id
                            ? "Deleting this moment..."
                            : (requireDeleteConfirmation
                                ? "🔒 Unlock to delete"
                                : "Delete this moment")
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(
                    isDeletingMoment ||
                    deleteMomentIDInFlight != nil ||
                    isCreatingMoment ||
                    isCreatingReaction ||
                    isLoadingReactions ||
                    requireDeleteConfirmation
                )

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

            HStack(spacing: 8) {
                Text(requireDeleteConfirmation ? "Lock ON" : "Lock OFF")
                    .font(.caption2.monospaced())
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(requireDeleteConfirmation ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .foregroundStyle(requireDeleteConfirmation ? .orange : .green)
                    .clipShape(Capsule())

                Text(
                    requireDeleteConfirmation
                        ? "Row delete lock is on. Turn off `Require confirmation for row delete` to unlock."
                        : "Row delete unlocked. You can tap `Delete this moment` on this row now."
                )
                .font(.caption)
                .foregroundStyle(requireDeleteConfirmation ? .orange : .green)
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

    private var normalizedAuthorUserIDDraft: String {
        authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedViewerUserIDDraft: String {
        viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedDeleteMomentIDDraft: String {
        deleteMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var deleteMomentPresets: [String] {
        reactionTargetMomentPresets
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

    private var momentCreateQuickCopySummary: String? {
        let author = normalizedAuthorUserIDDraft
        let imageURL = imageStorageKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = captionDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !author.isEmpty || !imageURL.isEmpty || !caption.isEmpty else {
            return nil
        }

        let normalizedAuthor = author.isEmpty ? "(empty)" : author
        let normalizedImageURL = imageURL.isEmpty ? "(empty)" : imageURL
        let normalizedCaption = caption.isEmpty ? "(empty)" : caption

        return "author=\(normalizedAuthor) | image_url=\(normalizedImageURL) | caption=\(normalizedCaption)"
    }

    private var privateFeedQuickCopySummary: String? {
        let viewer = viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedViewer = viewer.isEmpty ? "(empty)" : viewer
        let feedCount = momentRows.count
        let firstMomentID = momentRows.first?.id ?? "(none)"

        return "viewer=\(normalizedViewer) | feed_count=\(feedCount) | first_moment_id=\(firstMomentID)"
    }

    private var quickFeedVisibilityDeltaSummaryLine: String {
        let viewer = viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedViewer = viewer.isEmpty ? "(empty)" : viewer
        let feedCount = momentRows.count
        let firstMomentID = momentRows.first?.id ?? "(none)"

        return "viewer=\(normalizedViewer) / feed_count=\(feedCount) / first_moment_id=\(firstMomentID)"
    }

    private func buildFeedVisibilityGateSummary(viewerRawID: String, rows: [PrivateFeedMomentRow], snapshotSource: String) -> (viewerAccess: String, viewerAccessReason: String, visibleCount: Int, firstMomentID: String, summaryLine: String) {
        let normalizedViewerID = viewerRawID.trimmingCharacters(in: .whitespacesAndNewlines)
        let viewerAccessReason: String

        if normalizedViewerID.isEmpty {
            viewerAccessReason = "viewer_missing"
        } else if !rows.isEmpty {
            viewerAccessReason = "granted"
        } else {
            viewerAccessReason = "empty_or_blocked"
        }

        let viewerAccess = viewerAccessReason == "granted" ? "granted" : "not_granted"
        let visibleCount = rows.count
        let firstMomentID = rows.first?.id ?? "(none)"
        let summaryLine = "viewer_access=\(viewerAccess) / viewer_access_reason=\(viewerAccessReason) / gate_snapshot_source=\(snapshotSource) / visible_count=\(visibleCount) / first_moment_id=\(firstMomentID)"

        return (viewerAccess, viewerAccessReason, visibleCount, firstMomentID, summaryLine)
    }

    private var quickFeedVisibilityGateSummaryLine: String {
        buildFeedVisibilityGateSummary(
            viewerRawID: viewerUserIDDraft,
            rows: momentRows,
            snapshotSource: feedVisibilityGateSnapshotSource
        ).summaryLine
    }

    private var quickCreateFeedGateBundleLine: String {
        let payloadSummary = momentCreateQuickCopySummary ?? "author=(empty) | image_url=(empty) | caption=(empty)"
        return "moment_create_marker={\(payloadSummary)} | feed_gate_summary={\(quickFeedVisibilityGateSummaryLine)}"
    }

    private var lastCreateFeedGateBundleLine: String? {
        guard
            let lastCreateFeedVisibilityDeltaLine,
            !lastCreateFeedVisibilityDeltaLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let lastCreateFeedGateSummaryLine,
            !lastCreateFeedGateSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return "last_create_feed_visibility_delta={\(lastCreateFeedVisibilityDeltaLine)} | feed_gate_summary={\(lastCreateFeedGateSummaryLine)}"
    }

    private var lastDeleteFeedGateBundleLine: String? {
        guard
            let lastDeletedMomentSummaryLine,
            !lastDeletedMomentSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let gateSummaryLine = quickFeedVisibilityGateSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gateSummaryLine.isEmpty else {
            return nil
        }

        return "last_delete_result={\(lastDeletedMomentSummaryLine)} | feed_gate_summary={\(gateSummaryLine)}"
    }

    private var quickDeleteParitySummaryLine: String {
        let normalizedDeleteMomentID = normalizedDeleteMomentIDDraft.isEmpty ? "(empty)" : normalizedDeleteMomentIDDraft
        return "delete_moment_id=\(normalizedDeleteMomentID) / authored_count=\(authoredMomentRows.count) / feed_count=\(momentRows.count) / gate_snapshot_source=\(feedVisibilityGateSnapshotSource) / delete_snapshot_source=\(deleteSnapshotSource)"
    }

    private var deleteCopyAuditSourceOptions: [String] {
        ["quick_delete_parity", "last_delete_result", "copied_feedback"]
    }

    private var deleteCopyAuditSourceStateLine: String {
        let readiness = deleteCopyAuditSourceOptions.map { source -> (source: String, hasValue: Bool) in
            let hasValue = !deleteCopyAuditSourceValue(for: source)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            return (source: source, hasValue: hasValue)
        }
        let segments = readiness.map { entry in
            "\(entry.source):\(entry.hasValue ? "ready" : "missing")"
        }
        let readyCount = readiness.filter(\.hasValue).count
        return "delete_copy_audit_source_state=\(segments.joined(separator: "/"))/ready_count=\(readyCount)/total=\(deleteCopyAuditSourceOptions.count)"
    }

    private func deleteCopyAuditSourceValue(for source: String) -> String {
        switch source {
        case "quick_delete_parity":
            return quickDeleteParitySummaryLine
        case "last_delete_result":
            return lastDeletedMomentSummaryLine ?? ""
        case "copied_feedback":
            return lastDeleteSummaryCopiedFeedbackText ?? ""
        default:
            return ""
        }
    }

    private var lastCreateFeedVisibilityDeltaCopiedFeedbackText: String? {
        guard let lastCreateFeedVisibilityDeltaCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastCreateFeedVisibilityDeltaCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied feed-visibility delta (\(Int(elapsed))s ago): \(lastCreateFeedVisibilityDeltaCopiedText)"
    }

    private var lastCreateFeedGateBundleCopiedFeedbackText: String? {
        guard let lastCreateFeedGateBundleCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastCreateFeedGateBundleCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied create + feed-gate bundle (\(Int(elapsed))s ago): \(lastCreateFeedGateBundleCopiedText)"
    }

    private var lastCreateFeedGateSnapshotBundleCopiedFeedbackText: String? {
        guard let lastCreateFeedGateSnapshotBundleCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastCreateFeedGateSnapshotBundleCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied last create + feed-gate bundle (\(Int(elapsed))s ago): \(lastCreateFeedGateSnapshotBundleCopiedText)"
    }

    private var lastDeleteSummaryCopiedFeedbackText: String? {
        guard let lastDeleteSummaryCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastDeleteSummaryCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied delete summary (\(Int(elapsed))s ago): \(lastDeleteSummaryCopiedText)"
    }

    private var lastDeleteFeedGateBundleCopiedFeedbackText: String? {
        guard let lastDeleteFeedGateBundleCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastDeleteFeedGateBundleCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied last delete + feed-gate bundle (\(Int(elapsed))s ago): \(lastDeleteFeedGateBundleCopiedText)"
    }

    private func buildDeleteCopyAuditLine(source: String, value: String) -> String {
        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return "delete_copy_audit=source:\(source)/value:\(normalizedValue)"
    }

    private func buildDeleteCopyAuditFirstReadySourceLine(source: String) -> String {
        "delete_copy_audit_first_ready_source=\(source)"
    }

    private var resolvedQuickReactionUserID: String? {
        if let currentSessionUserID {
            return currentSessionUserID
        }

        let trimmedReactionUserID = normalizedReactionUserIDDraft
        return trimmedReactionUserID.isEmpty ? nil : trimmedReactionUserID
    }

    private var feedErrorHint: String? {
        guard let fetchError else {
            return nil
        }

        if fetchError.contains("user_not_found") {
            return "Author/viewer/reaction user was not found. Use current session user or a valid user UUID."
        }

        if fetchError.contains("moment_not_found") {
            return "Moment no longer exists. Reload private/authored moments and retry with a fresh moment ID."
        }

        if fetchError.contains("validation_error") {
            return "Request payload is invalid. Re-check UUID fields and image width/height values."
        }

        return nil
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

    private func applyCurrentSessionUserAsCreateAuthor() {
        guard let currentSessionUserID else {
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSessionUserID.isEmpty else {
            return
        }

        let trimmedAuthorDraft = normalizedAuthorUserIDDraft
        if trimmedAuthorDraft == trimmedSessionUserID {
            statusMessage = "Create author already matches current session user (author_source=session_user)."
        } else {
            authorUserIDDraft = trimmedSessionUserID
            statusMessage = "Applied current session user as create author (author_source=session_user)."
        }
        fetchError = nil
    }

    private func applyCurrentSessionUserAsAuthorCreateAndReloadFeed() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_author_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSessionUserID.isEmpty else {
            statusMessage = nil
            fetchError = "session_author_missing_for_quick_apply"
            return
        }

        let trimmedAuthorDraft = normalizedAuthorUserIDDraft
        let sourceStatus: String
        if trimmedAuthorDraft == trimmedSessionUserID {
            sourceStatus = "Create author already matches current session user (author_source=session_user)."
        } else {
            authorUserIDDraft = trimmedSessionUserID
            sourceStatus = "Applied current session user as create author (author_source=session_user)."
        }

        await createMomentWithImage(statusPrefix: sourceStatus)
    }

    private func applyCurrentSessionUserAsViewerAuthorCreateAndReloadFeed() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_user_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSessionUserID.isEmpty else {
            statusMessage = nil
            fetchError = "session_user_missing_for_quick_apply"
            return
        }

        let trimmedAuthorDraft = normalizedAuthorUserIDDraft
        let trimmedViewerDraft = normalizedViewerUserIDDraft

        let authorStatus: String
        if trimmedAuthorDraft == trimmedSessionUserID {
            authorStatus = "Create author already matches current session user (author_source=session_user)."
        } else {
            authorStatus = "Applied current session user as create author (author_source=session_user)."
        }

        let viewerStatus: String
        if trimmedViewerDraft == trimmedSessionUserID {
            viewerStatus = "Viewer already matches current session user (viewer_source=session_user)."
        } else {
            viewerStatus = "Applied current session user as feed viewer (viewer_source=session_user)."
        }

        authorUserIDDraft = trimmedSessionUserID
        viewerUserIDDraft = trimmedSessionUserID
        fetchError = nil

        await createMomentWithImage(statusPrefix: "\(authorStatus) \(viewerStatus)", viewerUserIDOverride: trimmedSessionUserID)
    }

    private func applyCurrentSessionUserAsViewerKeepAuthorAndLoadPrivateFeed() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_viewer_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSessionUserID.isEmpty else {
            statusMessage = nil
            fetchError = "session_viewer_missing_for_quick_apply"
            return
        }

        let trimmedViewerDraft = normalizedViewerUserIDDraft
        let viewerStatus: String
        if trimmedViewerDraft == trimmedSessionUserID {
            viewerStatus = "Viewer already matches current session user (viewer_source=session_user)."
        } else {
            viewerStatus = "Applied current session user as feed viewer (viewer_source=session_user)."
        }

        viewerUserIDDraft = trimmedSessionUserID
        fetchError = nil

        await loadPrivateFeed(statusPrefix: "\(viewerStatus) Kept create author as-is.")
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

    private func useMomentAuthorAsCreateAuthor(_ row: PrivateFeedMomentRow) {
        let trimmedAuthorID = row.authorID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAuthorID.isEmpty else {
            return
        }

        authorUserIDDraft = trimmedAuthorID
        statusMessage = "Create author set from selected moment author."
        fetchError = nil
    }

    private func useMomentIDForDelete(_ row: PrivateFeedMomentRow) {
        let trimmedMomentID = row.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMomentID.isEmpty else {
            return
        }

        if normalizedDeleteMomentIDDraft == trimmedMomentID {
            statusMessage = "Delete target unchanged (already selected)."
        } else {
            statusMessage = "Delete moment id set from selected row."
        }

        deleteMomentIDDraft = trimmedMomentID
        deleteSnapshotSource = "preset_row"
        fetchError = nil
    }

    private func loadReactionsForMoment(_ row: PrivateFeedMomentRow) async {
        reactionTargetMomentIDDraft = row.id
        await loadMomentReactions()
    }

    private func createQuickReactionForMoment(_ row: PrivateFeedMomentRow) async {
        let trimmedReactionType = normalizedReactionTypeDraft
        guard !trimmedReactionType.isEmpty else {
            setQuickReactionError("missing_reaction_type")
            return
        }

        let quickReactionUserID = resolvedQuickReactionUserID(for: row)

        guard let quickReactionUserID else {
            setQuickReactionError(
                quickReactionPreferMomentAuthor
                    ? "missing_author_user"
                    : "missing_reaction_user"
            )
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

            statusMessage = "qr:ok moment=\(shortIdentifier(row.id)) mode=\(quickReactionRefreshMode.shortLabel) refreshing=reactions"
            latestQuickReactionLog = statusMessage
            await loadMomentReactions()

            var refreshedTargets: [String] = []

            switch quickReactionRefreshMode {
            case .none:
                break
            case .privateFeed:
                if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("private")
                    await loadPrivateFeed()
                }
            case .authored:
                if !authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("authored")
                    await loadAuthoredMoments()
                }
            case .both:
                if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("private")
                    await loadPrivateFeed()
                }

                if !authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    refreshedTargets.append("authored")
                    await loadAuthoredMoments()
                }
            }

            if fetchError == nil {
                let refreshedSummary = refreshedTargets.isEmpty ? "none" : refreshedTargets.joined(separator: "+")
                statusMessage = "qr:ok moment=\(shortIdentifier(row.id)) mode=\(quickReactionRefreshMode.shortLabel) refreshed=\(refreshedTargets.count) targets=\(refreshedSummary)"
                latestQuickReactionLog = statusMessage
            }
        } catch {
            setQuickReactionError(
                "request_failed",
                detail: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }

        quickReactionMomentIDInFlight = nil
    }

    private func setQuickReactionError(_ code: String, detail: String? = nil) {
        if let detail, !detail.isEmpty {
            fetchError = "qr:err code=\(code) detail=\(detail)"
        } else {
            fetchError = "qr:err code=\(code)"
        }

        latestQuickReactionLog = fetchError
    }

    private func copyQuickFeedVisibilityDeltaSummary() {
        let normalizedText = quickFeedVisibilityDeltaSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "quick_feed_visibility_delta_empty"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastCreateFeedVisibilityDeltaCopiedText = normalizedText
        lastCreateFeedVisibilityDeltaCopiedAt = Date()
        statusMessage = "Copied quick feed visibility delta to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickFeedVisibilityGateSummary() {
        let normalizedText = quickFeedVisibilityGateSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "quick_feed_visibility_gate_summary_empty"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastCreateFeedVisibilityDeltaCopiedText = normalizedText
        lastCreateFeedVisibilityDeltaCopiedAt = Date()
        statusMessage = "Copied quick feed visibility gate summary to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickCreateFeedGateBundleLine() {
        let normalizedText = quickCreateFeedGateBundleLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "quick_create_feed_gate_bundle_empty"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastCreateFeedGateBundleCopiedText = normalizedText
        lastCreateFeedGateBundleCopiedAt = Date()
        statusMessage = "Copied quick create + feed-gate bundle to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyLastCreateFeedVisibilityDeltaLine() {
        guard let lastCreateFeedVisibilityDeltaLine else {
            statusMessage = nil
            fetchError = "last_create_feed_visibility_delta_missing"
            return
        }

        let normalizedText = lastCreateFeedVisibilityDeltaLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "last_create_feed_visibility_delta_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastCreateFeedVisibilityDeltaCopiedText = normalizedText
        lastCreateFeedVisibilityDeltaCopiedAt = Date()
        statusMessage = "Copied last create feed visibility delta to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyLastCreateFeedGateBundleLine() {
        guard let lastCreateFeedGateBundleLine else {
            statusMessage = nil
            fetchError = "last_create_feed_gate_bundle_missing"
            return
        }

        let normalizedText = lastCreateFeedGateBundleLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "last_create_feed_gate_bundle_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastCreateFeedGateSnapshotBundleCopiedText = normalizedText
        lastCreateFeedGateSnapshotBundleCopiedAt = Date()
        statusMessage = "Copied last create + feed-gate bundle to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickDeleteParitySummaryLine() {
        let normalizedText = quickDeleteParitySummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "quick_delete_parity_summary_empty"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastDeleteSummaryCopiedText = normalizedText
        lastDeleteSummaryCopiedAt = Date()
        deleteCopyAuditSourceDraft = "quick_delete_parity"
        lastDeleteCopyAuditLine = buildDeleteCopyAuditLine(source: "quick_delete_parity", value: normalizedText)
        statusMessage = "Copied quick delete parity summary to clipboard (delete_summary_copy_source=quick_delete_parity / \(normalizedText))."
        fetchError = nil
    }

    private func copyLastDeleteFeedGateBundleLine() {
        guard let lastDeleteFeedGateBundleLine else {
            statusMessage = nil
            fetchError = "last_delete_feed_gate_bundle_missing"
            return
        }

        let normalizedText = lastDeleteFeedGateBundleLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "last_delete_feed_gate_bundle_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastDeleteFeedGateBundleCopiedText = normalizedText
        lastDeleteFeedGateBundleCopiedAt = Date()
        statusMessage = "Copied last delete + feed-gate bundle to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyLastDeleteResultSummaryLine() {
        guard let lastDeletedMomentSummaryLine else {
            statusMessage = nil
            fetchError = "last_delete_result_summary_missing"
            return
        }

        let normalizedText = lastDeletedMomentSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "last_delete_result_summary_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastDeleteSummaryCopiedText = normalizedText
        lastDeleteSummaryCopiedAt = Date()
        deleteCopyAuditSourceDraft = "last_delete_result"
        lastDeleteCopyAuditLine = buildDeleteCopyAuditLine(source: "last_delete_result", value: normalizedText)
        statusMessage = "Copied last delete result summary to clipboard (delete_summary_copy_source=last_delete_result / \(normalizedText))."
        fetchError = nil
    }

    private func copyLastDeleteSummaryCopiedFeedbackText() {
        guard let lastDeleteSummaryCopiedFeedbackText else {
            statusMessage = nil
            fetchError = "last_copied_delete_summary_missing"
            return
        }

        let normalizedText = lastDeleteSummaryCopiedFeedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "last_copied_delete_summary_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        deleteCopyAuditSourceDraft = "copied_feedback"
        lastDeleteCopyAuditLine = buildDeleteCopyAuditLine(source: "copied_feedback", value: normalizedText)
        statusMessage = "Copied copied delete summary feedback to clipboard (delete_summary_copy_source=copied_feedback / \(normalizedText))."
        fetchError = nil
    }

    private func copyDeleteCopyAuditLine() {
        guard let lastDeleteCopyAuditLine else {
            statusMessage = nil
            fetchError = "delete_copy_audit_missing"
            return
        }

        let normalizedText = lastDeleteCopyAuditLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        statusMessage = "Copied delete copy audit line to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyDeleteCopyAuditSourceStateLine() {
        let normalizedText = deleteCopyAuditSourceStateLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_source_state_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        statusMessage = "Copied delete copy audit source-state line to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyDeleteCopyAuditFirstReadySourceLine() {
        guard let line = lastDeleteCopyAuditFirstReadySourceLine?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_first_ready_source_line_missing"
            return
        }

        guard copyToClipboard(line) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        statusMessage = "Copied delete copy audit first-ready source line to clipboard (\(line))."
        fetchError = nil
    }

    private func copyDeleteCopyAuditSourceStateSnapshotLine() {
        let normalizedText = deleteCopyAuditSourceStateLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_source_state_missing"
            return
        }

        guard copyToClipboard(normalizedText) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastDeleteCopyAuditSourceStateSnapshotLine = "last_source_state_snapshot=\(normalizedText)"
        lastDeleteCopyAuditSourceStateSnapshotSourceLine = "last_source_state_snapshot_source=source_state_snapshot_copy"
        statusMessage = "Copied delete copy audit source-state snapshot line to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyLastDeleteCopyAuditSourceStateSnapshotLine() {
        guard let snapshotLine = lastDeleteCopyAuditSourceStateSnapshotLine?.trimmingCharacters(in: .whitespacesAndNewlines), !snapshotLine.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_source_state_snapshot_line_missing"
            return
        }

        guard copyToClipboard(snapshotLine) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        lastDeleteCopyAuditSourceStateSnapshotSourceLine = "last_source_state_snapshot_source=manual_recopy"
        statusMessage = "Copied last source-state snapshot line to clipboard (\(snapshotLine))."
        fetchError = nil
    }

    private func copyLastDeleteCopyAuditSourceStateSnapshotSourceLine() {
        guard let snapshotSourceLine = lastDeleteCopyAuditSourceStateSnapshotSourceLine?.trimmingCharacters(in: .whitespacesAndNewlines), !snapshotSourceLine.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_source_state_snapshot_source_line_missing"
            return
        }

        guard copyToClipboard(snapshotSourceLine) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        statusMessage = "Copied last source-state snapshot source line to clipboard (\(snapshotSourceLine)) / last_source_state_snapshot_source_line_copied."
        fetchError = nil
    }

    private func copyDeleteCopyAuditForFirstReadySource() {
        guard let firstReadySource = deleteCopyAuditSourceOptions.first(where: { source in
            !deleteCopyAuditSourceValue(for: source)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }) else {
            let firstReadySourceLine = buildDeleteCopyAuditFirstReadySourceLine(source: "none")
            lastDeleteCopyAuditFirstReadySourceLine = firstReadySourceLine
            statusMessage = nil
            fetchError = "\(firstReadySourceLine) / delete_copy_audit_first_ready_source_missing"
            return
        }

        let firstReadySourceLine = buildDeleteCopyAuditFirstReadySourceLine(source: firstReadySource)
        lastDeleteCopyAuditFirstReadySourceLine = firstReadySourceLine
        copyDeleteCopyAuditLineForSource(firstReadySource)
        if let statusMessage {
            self.statusMessage = "\(statusMessage) / \(firstReadySourceLine)"
        }
    }

    private func copyDeleteCopyAuditLineForSource(_ source: String) {
        let sourceValue = deleteCopyAuditSourceValue(for: source).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceValue.isEmpty else {
            statusMessage = nil
            fetchError = "delete_copy_audit_source_value_missing:\(source)"
            return
        }

        let auditLine = buildDeleteCopyAuditLine(source: source, value: sourceValue)
        deleteCopyAuditSourceDraft = source
        lastDeleteCopyAuditLine = auditLine

        guard copyToClipboard(auditLine) else {
            statusMessage = "quick_copy_clipboard_unavailable"
            fetchError = nil
            return
        }

        statusMessage = "Copied delete copy audit line to clipboard (\(auditLine))."
        fetchError = nil
    }

    private func copyToClipboard(_ text: String) -> Bool {
#if canImport(UIKit)
        UIPasteboard.general.string = text
        return true
#else
        return false
#endif
    }

    private func copyLatestQuickReactionLogToClipboard() {
        guard let latestQuickReactionLog else {
            return
        }

        if copyToClipboard(latestQuickReactionLog) {
            statusMessage = "qr:copied log"
        } else {
            statusMessage = "qr:copy_unavailable"
        }
    }

    private func clearLatestQuickReactionLog() {
        latestQuickReactionLog = nil
        fetchError = nil
        statusMessage = "qr:cleared log"
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

    private func loadPrivateFeed(statusPrefix: String? = nil, snapshotSource: String = "reload_flow") async {
        let composeStatus: (String) -> String = { message in
            guard let statusPrefix, !statusPrefix.isEmpty else {
                return message
            }
            return "\(statusPrefix) \(message)"
        }

        let trimmedViewerID = viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedViewerID.isEmpty else {
            fetchError = composeStatus("Viewer UUID là bắt buộc để load private feed.")
            return
        }

        isLoading = true
        fetchError = nil
        statusMessage = composeStatus("Reloading private feed...")

        do {
            momentRows = try await PrivateFeedAPIClient().fetchFeed(viewerUserID: trimmedViewerID)
            synchronizeReactionTargetWithLoadedMoments()
            feedVisibilityGateSnapshotSource = snapshotSource
            let gateSummary = buildFeedVisibilityGateSummary(viewerRawID: trimmedViewerID, rows: momentRows, snapshotSource: snapshotSource)
            statusMessage = composeStatus("Loaded \(momentRows.count) private feed moment(s). Gate summary: \(gateSummary.summaryLine).")
        } catch {
            momentRows = []
            synchronizeReactionTargetWithLoadedMoments()
            fetchError = composeStatus((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
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

    private func createMomentWithImage(statusPrefix: String? = nil, viewerUserIDOverride: String? = nil) async {
        let composeStatus: (String) -> String = { message in
            guard let statusPrefix, !statusPrefix.isEmpty else {
                return message
            }
            return "\(statusPrefix) \(message)"
        }

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
        statusMessage = composeStatus("Creating moment + image shell...")

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
            statusMessage = composeStatus("Created moment \(createdMomentID). Reloading authored list...")
            await loadAuthoredMoments()

            let trimmedViewerID = (viewerUserIDOverride ?? viewerUserIDDraft).trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedViewerID.isEmpty {
                await loadPrivateFeed()
                let firstMomentID = momentRows.first?.id ?? "(none)"
                lastCreateFeedVisibilityDeltaLine = "created_moment_id=\(createdMomentID) / viewer=\(trimmedViewerID) / feed_count=\(momentRows.count) / first_moment_id=\(firstMomentID)"
                feedVisibilityGateSnapshotSource = "create_flow"
                let gateSummary = buildFeedVisibilityGateSummary(viewerRawID: trimmedViewerID, rows: momentRows, snapshotSource: "create_flow")
                lastCreateFeedGateSummaryLine = gateSummary.summaryLine
                statusMessage = composeStatus(
                    "Created moment \(createdMomentID). Feed visibility delta: " +
                    "viewer=\(trimmedViewerID) / feed_count=\(momentRows.count) / first_moment_id=\(firstMomentID). " +
                    "Feed visibility gate summary: \(gateSummary.summaryLine)."
                )
            } else {
                lastCreateFeedVisibilityDeltaLine = "created_moment_id=\(createdMomentID) / viewer=(empty) / feed_count=(not_loaded) / first_moment_id=(not_loaded)"
                feedVisibilityGateSnapshotSource = "create_flow"
                let gateSummary = buildFeedVisibilityGateSummary(viewerRawID: "", rows: [], snapshotSource: "create_flow")
                lastCreateFeedGateSummaryLine = gateSummary.summaryLine
                statusMessage = composeStatus(
                    "Created moment \(createdMomentID). Set feed viewer UUID, then load private feed to verify visibility delta. " +
                    "Gate summary: \(gateSummary.summaryLine)."
                )
            }
        } catch {
            let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            fetchError = composeStatus(errorMessage)
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

    private func deleteMoment() async {
        let trimmedMomentID = deleteMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMomentID.isEmpty else {
            fetchError = "Moment ID là bắt buộc để delete moment."
            return
        }

        await performDeleteMoment(momentID: trimmedMomentID, origin: .manual)
    }

    private func deleteMomentFromRow(_ row: PrivateFeedMomentRow) async {
        guard !requireDeleteConfirmation else {
            fetchError = "One-tap delete is locked. Tắt 'Require confirmation for row delete' để tiếp tục."
            return
        }

        let trimmedMomentID = row.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMomentID.isEmpty else {
            return
        }

        deleteMomentIDDraft = trimmedMomentID
        deleteSnapshotSource = "preset_row"
        await performDeleteMoment(momentID: trimmedMomentID, origin: .row)
    }

    private enum DeleteMomentOrigin {
        case manual
        case row
    }

    private func buildDeleteMomentSummary(_ deleted: PrivateFeedMomentDeleteResult) -> String {
        let normalizedDeletedAt = deleted.deleted_at?.trimmingCharacters(in: .whitespacesAndNewlines)
        let deletedAt = (normalizedDeletedAt?.isEmpty == false) ? normalizedDeletedAt! : "(none)"
        let authorLoadedCount = authoredMomentRows.filter { $0.authorID == deleted.author_user_id }.count
        let feedMatchCount = momentRows.filter { $0.id == deleted.id }.count

        return "delete_result=deleted / moment_id=\(deleted.id) / author_user_id=\(deleted.author_user_id) / deleted_at=\(deletedAt) / author_loaded_count=\(authorLoadedCount) / feed_match_count=\(feedMatchCount)"
    }

    private func performDeleteMoment(momentID: String, origin: DeleteMomentOrigin) async {
        isDeletingMoment = true
        deleteMomentIDInFlight = origin == .row ? momentID : nil
        fetchError = nil

        do {
            let deleted = try await PrivateFeedAPIClient().deleteMoment(momentID: momentID)
            let deletedSummary = buildDeleteMomentSummary(deleted)

            statusMessage = origin == .row
                ? "Deleted moment \(momentID) from row action. Reloading lists..."
                : "Deleted moment \(momentID). Reloading lists..."
            deleteSnapshotSource = "manual_input"
            lastDeletedMomentSummaryLine = deletedSummary

            if reactionTargetMomentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == momentID {
                reactionTargetMomentIDDraft = ""
                reactionRows = []
            }

            var deleteGateSummaryLine: String?
            if !viewerUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadPrivateFeed(snapshotSource: "delete_flow")
                deleteGateSummaryLine = quickFeedVisibilityGateSummaryLine
            }

            if !authorUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadAuthoredMoments()
            }

            if let deleteGateSummaryLine, !deleteGateSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                statusMessage = "Deleted moment \(momentID). \(deletedSummary). Feed visibility gate summary: \(deleteGateSummaryLine)."
            } else {
                statusMessage = "Deleted moment \(momentID). \(deletedSummary)."
            }
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        deleteMomentIDInFlight = nil
        isDeletingMoment = false
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

private struct PrivateFeedMomentDeleteResult: Decodable {
    let id: String
    let author_user_id: String
    let deleted_at: String?
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
        let deleted_at: String?
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
        struct ErrorDetail: Decodable {
            let code: String
            let message: String
        }

        let error: ErrorDetail?
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

    func deleteMoment(momentID: String) async throws -> PrivateFeedMomentDeleteResult {
        var request = URLRequest(url: try makeURL(path: "/moments/\(momentID)"))
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Moment delete failed"))
        }

        do {
            return try JSONDecoder().decode(PrivateFeedMomentDeleteResult.self, from: data)
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
        if let payload = try? JSONDecoder().decode(BackendErrorPayload.self, from: data) {
            if let detail = payload.detail, !detail.isEmpty {
                return "\(prefix): \(statusCode) (\(detail))"
            }

            if let error = payload.error {
                let message = error.message.isEmpty ? error.code : error.message
                return "\(prefix): \(statusCode) (\(error.code): \(message))"
            }
        }

        return "\(prefix): \(statusCode)"
    }
}
