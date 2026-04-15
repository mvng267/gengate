import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

private let friendRequestCreateQuickCopyEmpty = "request_id=(none) / action=created / requester=(none) / receiver=(none)"
private let friendRequestAcceptQuickCopyEmpty = "request_id=(none) / action=accepted / accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)"
private let friendRequestRejectQuickCopyEmpty = "request_id=(none) / action=rejected / accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)"

struct ProfilePlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userIDDraft: String = ""
    @State private var receiverUserIDDraft: String = ""
    @State private var pendingRequestCount: Int?
    @State private var friendshipCount: Int?
    @State private var pendingRequestRows: [FriendRequestRow] = []
    @State private var friendshipRows: [FriendshipRow] = []
    @State private var fetchError: String?
    @State private var statusMessage: String?
    @State private var isLoading = false
    @State private var isCreatingRequest = false
    @State private var busyAcceptRequestID: String?
    @State private var busyRejectRequestID: String?
    @State private var lastFriendGraphActionDeltaLine: String?
    @State private var lastFriendGraphActionDeltaCopiedAt: Date?
    @State private var lastFriendGraphActionDeltaCopiedText: String = ""
    @State private var lastFriendRequestCreateQuickCopy: String = friendRequestCreateQuickCopyEmpty
    @State private var lastFriendRequestAcceptQuickCopy: String = friendRequestAcceptQuickCopyEmpty
    @State private var lastFriendRequestRejectQuickCopy: String = friendRequestRejectQuickCopyEmpty
    @State private var lastFriendRequestCreateAcceptBundleQuickCopy: String = "friend_request_create_marker={\(friendRequestCreateQuickCopyEmpty)} | friend_request_accept_marker={\(friendRequestAcceptQuickCopyEmpty)}"
    @State private var lastFriendRequestCreateRejectBundleQuickCopy: String = "friend_request_create_marker={\(friendRequestCreateQuickCopyEmpty)} | friend_request_reject_marker={\(friendRequestRejectQuickCopyEmpty)}"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Profile",
                    summary: "iOS native friend graph reader. Use a real user UUID to inspect pending requests and accepted friendships through the same backend contracts already used by web.",
                    status: "Status: native friend graph shell now supports create/accept/reject friend-request actions; profile editing and broader iOS domain clients are still pending.",
                    bullets: [
                        "Use the Session tab first to create or restore a session if you want the protected iOS shell context.",
                        "Paste a backend user UUID below, then fetch pending requests and friendships for that user.",
                        "You can now create friend requests via `/friends/requests`, accept pending inbound requests via `/friends/requests/{id}/accept`, and reject pending inbound requests via `/friends/requests/{id}/reject` directly from this tab."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Friend graph reader")
                        .font(.headline)

                    TextField("User UUID", text: $userIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Use current session user as requester + load friend graph") {
                        Task {
                            await applyCurrentSessionUserAsRequesterAndLoadFriendGraph()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button("Use current session user as receiver + send friend request") {
                        Task {
                            await applyCurrentSessionUserAsReceiverAndSendFriendRequest()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isLoading || isCreatingRequest)

                    Button("Use current session user as requester + keep receiver + send friend request") {
                        Task {
                            await applyCurrentSessionUserAsRequesterKeepReceiverAndSendFriendRequest()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil || isLoading || isCreatingRequest)

                    Button {
                        Task {
                            await loadFriendGraph()
                        }
                    } label: {
                        Text(isLoading ? "Loading friend graph..." : "Load friend graph")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create friend request")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Receiver user UUID", text: $receiverUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if isSelfFriendRequestDraft {
                            Text("Requester và receiver đang trùng nhau; đổi receiver để gửi request hợp lệ.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            Button {
                                swapRequesterAndReceiver()
                            } label: {
                                Text("Swap requester/receiver")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(
                                isCreatingRequest ||
                                isLoading ||
                                userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )

                            Button {
                                Task {
                                    await createFriendRequest()
                                }
                            } label: {
                                Text(isCreatingRequest ? "Sending friend request..." : "Send friend request")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(
                                isCreatingRequest ||
                                isLoading ||
                                userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                isSelfFriendRequestDraft
                            )
                        }
                    }

                    Text("Session indicator: \(sessionStore.sessionIndicatorLabel)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

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

                    if let friendRequestErrorHint {
                        Text("Friend-request hint: \(friendRequestErrorHint)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let pendingRequestCount, let friendshipCount {
                        let requestedUserLabel = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        let pendingPairModeSuffix = selectedPendingPairModeLabel.map { " · pending pair mode: \($0)" } ?? ""

                        seamRow(
                            title: "Snapshot summary",
                            state: "Pending requests: \(pendingRequestCount) · Accepted friendships: \(friendshipCount)",
                            detail: "Requested user: \(requestedUserLabel)\(pendingPairModeSuffix)"
                        )

                        if let pendingDirectionSummary {
                            Text("Pending summary: Inbound pending \(pendingDirectionSummary.inbound) · Outbound pending \(pendingDirectionSummary.outbound) · Total pending \(pendingDirectionSummary.total)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        if let quickCopyFriendGraphSummary {
                            Text("Quick copy: \(quickCopyFriendGraphSummary)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        Text("Quick delta summary: \(quickFriendGraphDeltaSummaryLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick delta summary") {
                            copyQuickFriendGraphDeltaSummary()
                        }
                        .buttonStyle(.bordered)

                        Text("Quick copy friend-request create marker: \(lastFriendRequestCreateQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick friend-request create marker") {
                            copyFriendRequestCreateQuickCopy()
                        }
                        .buttonStyle(.bordered)

                        Text("Quick copy friend-request accept marker: \(lastFriendRequestAcceptQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick friend-request accept marker") {
                            copyFriendRequestAcceptQuickCopy()
                        }
                        .buttonStyle(.bordered)

                        Text("Quick copy friend-request reject marker: \(lastFriendRequestRejectQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick friend-request reject marker") {
                            copyFriendRequestRejectQuickCopy()
                        }
                        .buttonStyle(.bordered)

                        Text("Quick copy friend-request create + accept bundle: \(lastFriendRequestCreateAcceptBundleQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick friend-request create + accept bundle") {
                            copyFriendRequestCreateAcceptBundleQuickCopy()
                        }
                        .buttonStyle(.bordered)

                        Text("Quick copy friend-request create + reject bundle: \(lastFriendRequestCreateRejectBundleQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Copy quick friend-request create + reject bundle") {
                            copyFriendRequestCreateRejectBundleQuickCopy()
                        }
                        .buttonStyle(.bordered)

                        if let lastFriendGraphActionDeltaLine {
                            Text("Last action delta: \(lastFriendGraphActionDeltaLine)")
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)

                            Button("Copy last action delta") {
                                copyLastFriendGraphActionDeltaLine()
                            }
                            .buttonStyle(.bordered)
                        }

                        if let lastFriendGraphActionDeltaCopiedFeedbackText {
                            Text(lastFriendGraphActionDeltaCopiedFeedbackText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No friend graph snapshot loaded yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pending friend requests")
                        .font(.headline)

                    if pendingRequestRows.isEmpty {
                        Text("No pending friend requests loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pendingRequestRows) { row in
                            let isSamePairSelected = isPendingRequestPairSelected(row, reversed: false)
                            let isReversePairSelected = isPendingRequestPairSelected(row, reversed: true)

                            VStack(alignment: .leading, spacing: 8) {
                                seamRow(
                                    title: "\(row.requesterLabel) → \(row.receiverLabel)",
                                    state: "status: \(row.status)",
                                    detail: "request_id: \(row.id)"
                                )

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Button {
                                            applyPendingRequestPair(row, reversed: false)
                                        } label: {
                                            Text(isSamePairSelected ? "Using same pair" : "Use same pair")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(isLoading || isCreatingRequest || isSamePairSelected)

                                        Button {
                                            applyPendingRequestPair(row, reversed: true)
                                        } label: {
                                            Text(isReversePairSelected ? "Using reverse pair" : "Use reverse pair")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(isLoading || isCreatingRequest || isReversePairSelected)
                                    }

                                    if row.canAccept {
                                        HStack(spacing: 8) {
                                            Button {
                                                Task {
                                                    await acceptFriendRequest(requestID: row.id)
                                                }
                                            } label: {
                                                Text(busyAcceptRequestID == row.id ? "Accepting..." : "Accept request")
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.bordered)
                                            .disabled(
                                                isLoading ||
                                                busyAcceptRequestID == row.id ||
                                                busyRejectRequestID == row.id
                                            )

                                            Button(role: .destructive) {
                                                Task {
                                                    await rejectFriendRequest(requestID: row.id)
                                                }
                                            } label: {
                                                Text(busyRejectRequestID == row.id ? "Rejecting..." : "Reject request")
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.bordered)
                                            .disabled(
                                                isLoading ||
                                                busyAcceptRequestID == row.id ||
                                                busyRejectRequestID == row.id
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Accepted friendships")
                        .font(.headline)

                    if friendshipRows.isEmpty {
                        Text("No accepted friendships loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friendshipRows) { row in
                            seamRow(
                                title: "\(row.userALabel) ↔ \(row.userBLabel)",
                                state: "state: \(row.state)",
                                detail: "friendship_id: \(row.id)"
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
        }
        .navigationTitle("Profile")
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

    private var friendRequestErrorHint: String? {
        guard let fetchError else {
            return nil
        }

        if fetchError.contains("friend_request_already_pending") {
            return "Pending request already exists for this pair. Try accept existing request instead of creating a new one."
        }

        if fetchError.contains("friendship_already_exists") {
            return "Users are already friends. Create request is no longer needed."
        }

        if fetchError.contains("request_not_pending") {
            return "This request is no longer pending. Reload friend graph to continue."
        }

        if fetchError.contains("invalid_request") {
            return "Requester and receiver must be different users."
        }

        return nil
    }

    private var isSelfFriendRequestDraft: Bool {
        let requesterUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverUserID = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !requesterUserID.isEmpty && requesterUserID == receiverUserID
    }

    private var selectedPendingPairModeLabel: String? {
        let requesterDraft = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverDraft = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !requesterDraft.isEmpty, !receiverDraft.isEmpty else {
            return nil
        }

        for row in pendingRequestRows {
            if requesterDraft == row.requesterUserID && receiverDraft == row.receiverUserID {
                return "same"
            }

            if requesterDraft == row.receiverUserID && receiverDraft == row.requesterUserID {
                return "reverse"
            }
        }

        return nil
    }

    private var pendingDirectionSummary: (inbound: Int, outbound: Int, total: Int)? {
        guard pendingRequestCount != nil else {
            return nil
        }

        let requestedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedUserID.isEmpty else {
            return nil
        }

        var inbound = 0
        var outbound = 0
        var total = 0

        for row in pendingRequestRows where row.status == "pending" {
            if row.receiverUserID == requestedUserID {
                inbound += 1
            }

            if row.requesterUserID == requestedUserID {
                outbound += 1
            }

            total += 1
        }

        return (inbound: inbound, outbound: outbound, total: total)
    }

    private var quickCopyFriendGraphSummary: String? {
        let requestedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedUserID.isEmpty,
              let pendingDirectionSummary,
              let friendshipCount else {
            return nil
        }

        return "user=\(requestedUserID) | pending_inbound=\(pendingDirectionSummary.inbound) | pending_outbound=\(pendingDirectionSummary.outbound) | pending_total=\(pendingDirectionSummary.total) | accepted=\(friendshipCount)"
    }

    private var quickFriendGraphDeltaSummaryLine: String {
        guard let pendingDirectionSummary,
              let friendshipCount else {
            return "accepted_count=(none) / pending_inbound=(none) / pending_outbound=(none)"
        }

        return "accepted_count=\(friendshipCount) / pending_inbound=\(pendingDirectionSummary.inbound) / pending_outbound=\(pendingDirectionSummary.outbound)"
    }

    private var lastFriendGraphActionDeltaCopiedFeedbackText: String? {
        guard let lastFriendGraphActionDeltaCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastFriendGraphActionDeltaCopiedAt)
        guard elapsed < 8 else {
            return nil
        }

        return "Copied friend graph action delta (\(Int(elapsed))s ago): \(lastFriendGraphActionDeltaCopiedText)"
    }

    private func buildFriendRequestCreateAcceptBundleQuickCopy(
        createQuickCopy: String? = nil,
        acceptQuickCopy: String? = nil
    ) -> String {
        let normalizedCreateQuickCopy = createQuickCopy?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAcceptQuickCopy = acceptQuickCopy?.trimmingCharacters(in: .whitespacesAndNewlines)

        let createMarker = normalizedCreateQuickCopy?.isEmpty == false
            ? normalizedCreateQuickCopy!
            : (lastFriendRequestCreateQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? friendRequestCreateQuickCopyEmpty
                : lastFriendRequestCreateQuickCopy)
        let acceptMarker = normalizedAcceptQuickCopy?.isEmpty == false
            ? normalizedAcceptQuickCopy!
            : (lastFriendRequestAcceptQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? friendRequestAcceptQuickCopyEmpty
                : lastFriendRequestAcceptQuickCopy)

        return "friend_request_create_marker={\(createMarker)} | friend_request_accept_marker={\(acceptMarker)}"
    }

    private func buildFriendRequestCreateRejectBundleQuickCopy(
        createQuickCopy: String? = nil,
        rejectQuickCopy: String? = nil
    ) -> String {
        let normalizedCreateQuickCopy = createQuickCopy?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRejectQuickCopy = rejectQuickCopy?.trimmingCharacters(in: .whitespacesAndNewlines)

        let createMarker = normalizedCreateQuickCopy?.isEmpty == false
            ? normalizedCreateQuickCopy!
            : (lastFriendRequestCreateQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? friendRequestCreateQuickCopyEmpty
                : lastFriendRequestCreateQuickCopy)
        let rejectMarker = normalizedRejectQuickCopy?.isEmpty == false
            ? normalizedRejectQuickCopy!
            : (lastFriendRequestRejectQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? friendRequestRejectQuickCopyEmpty
                : lastFriendRequestRejectQuickCopy)

        return "friend_request_create_marker={\(createMarker)} | friend_request_reject_marker={\(rejectMarker)}"
    }

    private func copyFriendRequestCreateQuickCopy() {
        let normalizedText = lastFriendRequestCreateQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_create_quick_copy_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend-request create quick copy to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyFriendRequestAcceptQuickCopy() {
        let normalizedText = lastFriendRequestAcceptQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_accept_quick_copy_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend-request accept quick copy to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyFriendRequestRejectQuickCopy() {
        let normalizedText = lastFriendRequestRejectQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_reject_quick_copy_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend-request reject quick copy to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyFriendRequestCreateAcceptBundleQuickCopy() {
        let normalizedText = lastFriendRequestCreateAcceptBundleQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_create_accept_bundle_quick_copy_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend-request create + accept bundle quick copy to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyFriendRequestCreateRejectBundleQuickCopy() {
        let normalizedText = lastFriendRequestCreateRejectBundleQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_create_reject_bundle_quick_copy_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend-request create + reject bundle quick copy to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func prefillFromCurrentSessionUserIfNeeded() {
        guard userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        userIDDraft = currentSessionUserID
    }

    private func applyCurrentSessionUserAsRequesterAndLoadFriendGraph() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_requester_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRequester = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedRequester == trimmedSessionUserID {
            await loadFriendGraph(
                statusMessage: "Requester already matches current session user (requester_source=session_user). Reloading friend graph snapshot..."
            )
            return
        }

        userIDDraft = trimmedSessionUserID
        await loadFriendGraph(
            statusMessage: "Applied current session user as requester (requester_source=session_user). Reloading friend graph snapshot..."
        )
    }

    private func applyCurrentSessionUserAsReceiverAndSendFriendRequest() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_receiver_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let requesterUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !requesterUserID.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_requester_missing_for_quick_send"
            return
        }

        guard requesterUserID != trimmedSessionUserID else {
            statusMessage = nil
            fetchError = "friend_request_invalid_request code=invalid_request detail=requester và receiver phải khác nhau"
            return
        }

        receiverUserIDDraft = trimmedSessionUserID

        await submitSessionBoundFriendRequestCreateFlow(
            requesterUserID: requesterUserID,
            receiverUserID: trimmedSessionUserID,
            statusPrefix: "Applied current session user as receiver (receiver_source=session_user)."
        )
    }

    private func applyCurrentSessionUserAsRequesterKeepReceiverAndSendFriendRequest() async {
        guard let currentSessionUserID else {
            statusMessage = nil
            fetchError = "session_requester_missing_for_quick_apply"
            return
        }

        let trimmedSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverUserID = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !receiverUserID.isEmpty else {
            statusMessage = nil
            fetchError = "friend_request_receiver_missing_for_quick_send"
            return
        }

        guard trimmedSessionUserID != receiverUserID else {
            statusMessage = nil
            fetchError = "friend_request_invalid_request code=invalid_request detail=requester và receiver phải khác nhau"
            return
        }

        userIDDraft = trimmedSessionUserID

        await submitSessionBoundFriendRequestCreateFlow(
            requesterUserID: trimmedSessionUserID,
            receiverUserID: receiverUserID,
            statusPrefix: "Applied current session user as requester (requester_source=session_user) + kept receiver."
        )
    }

    private func submitSessionBoundFriendRequestCreateFlow(
        requesterUserID: String,
        receiverUserID: String,
        statusPrefix: String
    ) async {
        isCreatingRequest = true
        statusMessage = "\(statusPrefix) Sending friend request..."
        fetchError = nil

        do {
            let createdRequestID = try await FriendGraphAPIClient().createFriendRequest(
                requesterUserID: requesterUserID,
                receiverUserID: receiverUserID
            )
            let createQuickCopy = "request_id=\(createdRequestID) / action=created / requester=\(requesterUserID) / receiver=\(receiverUserID)"
            lastFriendRequestCreateQuickCopy = createQuickCopy
            lastFriendRequestCreateAcceptBundleQuickCopy = buildFriendRequestCreateAcceptBundleQuickCopy(
                createQuickCopy: createQuickCopy
            )
            lastFriendRequestCreateRejectBundleQuickCopy = buildFriendRequestCreateRejectBundleQuickCopy(
                createQuickCopy: createQuickCopy
            )
            await loadFriendGraph(
                statusMessage: "\(statusPrefix) Friend request created. Reloading friend graph..."
            )
            lastFriendGraphActionDeltaLine = nil
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingRequest = false
    }

    private func applyFriendGraphDeltaLine(requestID: String, action: String, snapshot: FriendGraphSnapshot) -> String {
        let requestedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        let pendingInboundCount = snapshot.pendingRequests.filter {
            $0.status == "pending" && $0.receiverUserID == requestedUserID
        }.count
        let pendingOutboundCount = snapshot.pendingRequests.filter {
            $0.status == "pending" && $0.requesterUserID == requestedUserID
        }.count

        let deltaLine = "request_id=\(requestID) / action=\(action) / accepted_count=\(snapshot.friendshipCount) / pending_inbound=\(pendingInboundCount) / pending_outbound=\(pendingOutboundCount)"
        lastFriendGraphActionDeltaLine = deltaLine
        return deltaLine
    }

    private func copyQuickFriendGraphDeltaSummary() {
        let normalizedText = quickFriendGraphDeltaSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_graph_quick_delta_summary_empty"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend graph quick delta summary to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyLastFriendGraphActionDeltaLine() {
        guard let lastFriendGraphActionDeltaLine else {
            statusMessage = nil
            fetchError = "friend_graph_action_delta_missing"
            return
        }

        let normalizedText = lastFriendGraphActionDeltaLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            statusMessage = nil
            fetchError = "friend_graph_action_delta_missing"
            return
        }

        copyToClipboard(normalizedText)
        lastFriendGraphActionDeltaCopiedText = normalizedText
        lastFriendGraphActionDeltaCopiedAt = Date()
        statusMessage = "Copied friend graph action delta line to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }

    private func loadFriendGraph(statusMessage: String? = nil) async {
        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để load friend graph."
            return
        }

        isLoading = true
        if let statusMessage {
            self.statusMessage = statusMessage
            fetchError = nil
        } else {
            fetchError = nil
        }

        do {
            let snapshot = try await FriendGraphAPIClient().fetchSnapshot(userID: trimmedUserID)
            pendingRequestCount = snapshot.requestCount
            friendshipCount = snapshot.friendshipCount
            pendingRequestRows = snapshot.pendingRequests
            friendshipRows = snapshot.friendships

            let pendingInboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.receiverUserID == trimmedUserID
            }.count
            let pendingOutboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.requesterUserID == trimmedUserID
            }.count

            self.statusMessage = "Loaded friend graph: \(snapshot.requestCount) pending request(s), \(snapshot.friendshipCount) accepted friendship(s) · inbound: \(pendingInboundCount) · outbound: \(pendingOutboundCount)."
        } catch {
            pendingRequestCount = nil
            friendshipCount = nil
            pendingRequestRows = []
            friendshipRows = []
            self.statusMessage = nil
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func swapRequesterAndReceiver() {
        let trimmedRequester = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReceiver = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRequester.isEmpty, !trimmedReceiver.isEmpty else {
            return
        }

        userIDDraft = trimmedReceiver
        receiverUserIDDraft = trimmedRequester
        statusMessage = "Swapped requester/receiver."
        fetchError = nil
    }

    private func createFriendRequest() async {
        let requesterUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverUserID = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !requesterUserID.isEmpty, !receiverUserID.isEmpty else {
            fetchError = "Cần requester và receiver UUID để tạo friend request."
            return
        }

        guard requesterUserID != receiverUserID else {
            statusMessage = nil
            fetchError = "friend_request_invalid_request code=invalid_request detail=requester và receiver phải khác nhau"
            return
        }

        isCreatingRequest = true
        statusMessage = nil
        fetchError = nil

        do {
            let createdRequestID = try await FriendGraphAPIClient().createFriendRequest(
                requesterUserID: requesterUserID,
                receiverUserID: receiverUserID
            )
            let createQuickCopy = "request_id=\(createdRequestID) / action=created / requester=\(requesterUserID) / receiver=\(receiverUserID)"
            lastFriendRequestCreateQuickCopy = createQuickCopy
            lastFriendRequestCreateAcceptBundleQuickCopy = buildFriendRequestCreateAcceptBundleQuickCopy(
                createQuickCopy: createQuickCopy
            )
            lastFriendRequestCreateRejectBundleQuickCopy = buildFriendRequestCreateRejectBundleQuickCopy(
                createQuickCopy: createQuickCopy
            )
            await loadFriendGraph(statusMessage: "Friend request created. Receiver kept for quick dedupe re-test. Reloading friend graph...")
            lastFriendGraphActionDeltaLine = nil
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingRequest = false
    }

    private func applyPendingRequestPair(_ row: FriendRequestRow, reversed: Bool) {
        if reversed {
            userIDDraft = row.receiverUserID
            receiverUserIDDraft = row.requesterUserID
            statusMessage = "Filled reverse pair from pending request."
        } else {
            userIDDraft = row.requesterUserID
            receiverUserIDDraft = row.receiverUserID
            statusMessage = "Filled same pair from pending request."
        }
        fetchError = nil
    }

    private func isPendingRequestPairSelected(_ row: FriendRequestRow, reversed: Bool) -> Bool {
        let requesterDraft = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let receiverDraft = receiverUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        if reversed {
            return requesterDraft == row.receiverUserID && receiverDraft == row.requesterUserID
        }

        return requesterDraft == row.requesterUserID && receiverDraft == row.receiverUserID
    }

    private func acceptFriendRequest(requestID: String) async {
        guard !requestID.isEmpty else {
            fetchError = "Friend request id không hợp lệ."
            return
        }

        busyAcceptRequestID = requestID
        statusMessage = nil
        fetchError = nil

        do {
            try await FriendGraphAPIClient().acceptFriendRequest(requestID: requestID)
            let snapshot = try await FriendGraphAPIClient().fetchSnapshot(userID: userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines))

            pendingRequestCount = snapshot.requestCount
            friendshipCount = snapshot.friendshipCount
            pendingRequestRows = snapshot.pendingRequests
            friendshipRows = snapshot.friendships
            let acceptQuickCopy = applyFriendGraphDeltaLine(requestID: requestID, action: "accepted", snapshot: snapshot)
            lastFriendRequestAcceptQuickCopy = acceptQuickCopy
            lastFriendRequestCreateAcceptBundleQuickCopy = buildFriendRequestCreateAcceptBundleQuickCopy(
                acceptQuickCopy: acceptQuickCopy
            )

            let requestedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            let pendingInboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.receiverUserID == requestedUserID
            }.count
            let pendingOutboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.requesterUserID == requestedUserID
            }.count

            statusMessage = "Friend request accepted. accepted_count=\(snapshot.friendshipCount) / pending_inbound=\(pendingInboundCount) / pending_outbound=\(pendingOutboundCount)."
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        busyAcceptRequestID = nil
    }

    private func rejectFriendRequest(requestID: String) async {
        guard !requestID.isEmpty else {
            fetchError = "Friend request id không hợp lệ."
            return
        }

        busyRejectRequestID = requestID
        statusMessage = nil
        fetchError = nil

        do {
            try await FriendGraphAPIClient().rejectFriendRequest(requestID: requestID)
            let snapshot = try await FriendGraphAPIClient().fetchSnapshot(userID: userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines))

            pendingRequestCount = snapshot.requestCount
            friendshipCount = snapshot.friendshipCount
            pendingRequestRows = snapshot.pendingRequests
            friendshipRows = snapshot.friendships
            let rejectQuickCopy = applyFriendGraphDeltaLine(requestID: requestID, action: "rejected", snapshot: snapshot)
            lastFriendRequestRejectQuickCopy = rejectQuickCopy
            lastFriendRequestCreateRejectBundleQuickCopy = buildFriendRequestCreateRejectBundleQuickCopy(
                rejectQuickCopy: rejectQuickCopy
            )

            let requestedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            let pendingInboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.receiverUserID == requestedUserID
            }.count
            let pendingOutboundCount = snapshot.pendingRequests.filter {
                $0.status == "pending" && $0.requesterUserID == requestedUserID
            }.count

            statusMessage = "Friend request rejected. accepted_count=\(snapshot.friendshipCount) / pending_inbound=\(pendingInboundCount) / pending_outbound=\(pendingOutboundCount)."
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        busyRejectRequestID = nil
    }

    private func seamRow(title: String, state: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(state)
                .font(.footnote)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct FriendGraphSnapshot {
    let requestCount: Int
    let friendshipCount: Int
    let pendingRequests: [FriendRequestRow]
    let friendships: [FriendshipRow]
}

private struct FriendRequestRow: Identifiable {
    let id: String
    let status: String
    let requesterUserID: String
    let receiverUserID: String
    let requesterLabel: String
    let receiverLabel: String
    let canAccept: Bool
}

private struct FriendshipRow: Identifiable {
    let id: String
    let state: String
    let userALabel: String
    let userBLabel: String
}

private struct FriendGraphAPIClient {
    private struct FriendRequestListResponse: Decodable {
        let count: Int
        let items: [FriendRequestItem]
    }

    private struct FriendshipListResponse: Decodable {
        let count: Int
        let items: [FriendshipItem]
    }

    private struct FriendRequestCreateRequest: Encodable {
        let requester_user_id: String
        let receiver_user_id: String
    }

    private struct FriendRequestCreateResponse: Decodable {
        let id: String
        let requester_user_id: String
        let receiver_user_id: String
        let status: String
    }

    private struct FriendshipResponse: Decodable {
        let id: String
        let user_a_id: String
        let user_b_id: String
        let state: String
    }

    private struct FriendRequestItem: Decodable {
        let id: String
        let status: String
        let requester: FriendUserSummary
        let receiver: FriendUserSummary
    }

    private struct FriendshipItem: Decodable {
        let id: String
        let state: String
        let user_a: FriendUserSummary
        let user_b: FriendUserSummary
    }

    private struct FriendUserSummary: Decodable {
        let id: String
        let email: String
        let username: String?
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
                return "Thiếu backend base URL hợp lệ cho friend graph shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend friend graph response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchSnapshot(userID: String) async throws -> FriendGraphSnapshot {
        let requestsResponse = try await fetchFriendRequests(userID: userID)
        let friendshipsResponse = try await fetchFriendships(userID: userID)

        return FriendGraphSnapshot(
            requestCount: requestsResponse.count,
            friendshipCount: friendshipsResponse.count,
            pendingRequests: requestsResponse.items.map {
                FriendRequestRow(
                    id: $0.id,
                    status: $0.status,
                    requesterUserID: $0.requester.id,
                    receiverUserID: $0.receiver.id,
                    requesterLabel: $0.requester.username ?? $0.requester.email,
                    receiverLabel: $0.receiver.username ?? $0.receiver.email,
                    canAccept: $0.status == "pending" && $0.receiver.id == userID
                )
            },
            friendships: friendshipsResponse.items.map {
                FriendshipRow(
                    id: $0.id,
                    state: $0.state,
                    userALabel: $0.user_a.username ?? $0.user_a.email,
                    userBLabel: $0.user_b.username ?? $0.user_b.email
                )
            }
        )
    }

    func createFriendRequest(requesterUserID: String, receiverUserID: String) async throws -> String {
        var request = URLRequest(url: try makeURL(path: "/friends/requests"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            FriendRequestCreateRequest(
                requester_user_id: requesterUserID,
                receiver_user_id: receiverUserID
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend request create failed"))
        }

        do {
            let created = try JSONDecoder().decode(FriendRequestCreateResponse.self, from: data)
            return created.id
        } catch {
            throw APIError.invalidResponse
        }
    }

    func acceptFriendRequest(requestID: String) async throws {
        var request = URLRequest(url: try makeURL(path: "/friends/requests/\(requestID)/accept"))
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend request accept failed"))
        }

        do {
            _ = try JSONDecoder().decode(FriendshipResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func rejectFriendRequest(requestID: String) async throws {
        var request = URLRequest(url: try makeURL(path: "/friends/requests/\(requestID)/reject"))
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend request reject failed"))
        }

        do {
            _ = try JSONDecoder().decode(FriendRequestCreateResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func fetchFriendRequests(userID: String) async throws -> FriendRequestListResponse {
        let url = try makeURL(path: "/friends/requests", userID: userID)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friend requests fetch failed"))
        }

        do {
            return try JSONDecoder().decode(FriendRequestListResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func fetchFriendships(userID: String) async throws -> FriendshipListResponse {
        let url = try makeURL(path: "/friends", userID: userID)
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Friendships fetch failed"))
        }

        do {
            return try JSONDecoder().decode(FriendshipListResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeURL(path: String, userID: String) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "user_id", value: userID)]

        guard let url = components?.url else {
            throw APIError.invalidBaseURL
        }

        return url
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
