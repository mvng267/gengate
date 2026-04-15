import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct NotificationsPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userIDDraft: String = ""
    @State private var createTypeDraft: String = "ios_shell_notice"
    @State private var createPayloadDraft: String = "hello from ios notifications shell"
    @State private var notificationRows: [NotificationRow] = []
    @State private var listMeta: NotificationListMeta?
    @State private var pageLimitDraft: String = "20"
    @State private var pageOffsetDraft: String = "0"
    @State private var pageUnreadOnly: Bool = false
    @State private var mutatingNotificationIDs: Set<String> = []
    @State private var fetchError: String?
    @State private var statusMessage: String?
    @State private var isLoading = false
    @State private var isCreatingNotification = false
    @State private var lastLoadedWindow: NotificationLoadWindow?
    @State private var quickUnreadSummaryCopiedAt: Date?
    @State private var lastQuickUnreadSummaryCopiedText: String = ""
    @State private var quickPageMetaCopiedAt: Date?
    @State private var lastQuickPageMetaCopiedText: String = ""
    @State private var quickPageCursorSummaryCopiedAt: Date?
    @State private var lastQuickPageCursorSummaryCopiedText: String = ""
    @State private var quickMutationDeltaCopiedAt: Date?
    @State private var lastQuickMutationDeltaCopiedText: String = ""
    @State private var lastMutationDelta: NotificationMutationDelta?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Notifications",
                    summary: "iOS native notification center shell now supports create + read/unread mutation so notification flow can be exercised end-to-end from native UI.",
                    status: "Status: native notification center now supports create + read/unread toggles + quick unread summary + quick page cursor summary + quick mutation delta lines; delete remains intentionally out of scope for this slice.",
                    bullets: [
                        "Paste a backend user UUID to create and load notifications for that user.",
                        "This shell can create via `POST /notifications`, then read `/notifications/{user_id}` and toggle each row via `/notifications/{id}/read` + `/notifications/{id}/unread`.",
                        "Quick unread summary line (`current_page_unread / total_unread_count`) helps parity scan quickly with backend/web payloads.",
                        "Quick page cursor summary line (`user_id/limit/offset/filter_mode/count/unread_count/total_unread_count`) helps verify paging/filter window quickly.",
                        "Quick mutation delta line (`notification_id/read_state/current_page_unread/total_unread_count`) lets testers report mark read/unread outcome without manual counting.",
                        "Use this tab to run minimal notification lifecycle checks from iOS without relying on web seeding first."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification center reader")
                        .font(.headline)

                    TextField("User UUID", text: $userIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: userIDDraft, initial: false) { oldValue, newValue in
                            guard normalizedOffset > 0 else {
                                return
                            }

                            let oldTrimmed = oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            let newTrimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard oldTrimmed != newTrimmed else {
                                return
                            }

                            pageOffsetDraft = "0"
                            statusMessage = "User changed. Offset reset to first page."
                            fetchError = nil
                        }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Page limit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("20", text: $pageLimitDraft)
#if os(iOS)
                                .keyboardType(.numberPad)
#endif
                                .padding(10)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Page offset")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0", text: $pageOffsetDraft)
#if os(iOS)
                                .keyboardType(.numberPad)
#endif
                                .padding(10)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    Toggle("Load unread only", isOn: $pageUnreadOnly)
                        .toggleStyle(.switch)

                    HStack(spacing: 10) {
                        Button("All") {
                            pageUnreadOnly = false
                            pageOffsetDraft = "0"
                            statusMessage = "Preset selected: All notifications. Press Load notifications to refresh this window."
                            fetchError = nil
                        }
                        .buttonStyle(.bordered)
                        .disabled(!pageUnreadOnly)

                        Button("Unread only") {
                            pageUnreadOnly = true
                            pageOffsetDraft = "0"
                            statusMessage = "Preset selected: Unread only. Press Load notifications to refresh this window."
                            fetchError = nil
                        }
                        .buttonStyle(.bordered)
                        .disabled(pageUnreadOnly)
                    }

                    Text("Filter mode: \(pageUnreadOnly ? "Unread only" : "All notifications")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("First page") {
                            pageOffsetDraft = "0"
                        }
                        .buttonStyle(.bordered)
                        .disabled((Int(pageOffsetDraft) ?? 0) <= 0)

                        Button("Prev page") {
                            let currentOffset = max(Int(pageOffsetDraft) ?? 0, 0)
                            let currentLimit = min(max(Int(pageLimitDraft) ?? 20, 1), 200)
                            pageOffsetDraft = String(max(0, currentOffset - currentLimit))
                        }
                        .buttonStyle(.bordered)
                        .disabled((Int(pageOffsetDraft) ?? 0) <= 0)

                        Button("Next page") {
                            let currentOffset = max(Int(pageOffsetDraft) ?? 0, 0)
                            let currentLimit = min(max(Int(pageLimitDraft) ?? 20, 1), 200)
                            pageOffsetDraft = String(currentOffset + currentLimit)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Use current session user") {
                        fillFromCurrentSessionUser()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button {
                        Task {
                            await useCurrentSessionUserAndLoad()
                        }
                    } label: {
                        Text("Use current session user + load")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || isCreatingNotification || currentSessionUserID == nil)

                    Button {
                        Task {
                            await loadNotifications()
                        }
                    } label: {
                        Text(loadButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || isCreatingNotification || userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create notification")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Notification type", text: $createTypeDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Payload message", text: $createPayloadDraft)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await createNotification()
                            }
                        } label: {
                            Text(isCreatingNotification ? "Creating notification..." : "Create notification")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isCreatingNotification ||
                            userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            createTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    Text(pendingWindowHint)
                        .font(.footnote)
                        .foregroundStyle(hasPendingWindowChange ? .orange : .secondary)

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text("Loaded notifications: \(notificationRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Quick unread summary: \(quickUnreadSummaryLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Button("Copy quick unread summary") {
                        copyQuickUnreadSummaryLine()
                    }
                    .buttonStyle(.bordered)

                    if let quickUnreadSummaryCopiedFeedbackText {
                        Text(quickUnreadSummaryCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("Quick page cursor summary: \(quickPageCursorSummaryLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Button("Copy quick page cursor summary") {
                        copyQuickPageCursorSummaryLine()
                    }
                    .buttonStyle(.bordered)

                    if let quickPageCursorSummaryCopiedFeedbackText {
                        Text(quickPageCursorSummaryCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("Quick mutation delta: \(quickMutationDeltaLine)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Button("Copy quick mutation delta") {
                        copyQuickMutationDeltaLine()
                    }
                    .buttonStyle(.bordered)

                    if let quickMutationDeltaCopiedFeedbackText {
                        Text(quickMutationDeltaCopiedFeedbackText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let listMeta {
                        Text("Page count: \(listMeta.count) · Page unread: \(listMeta.unreadCount) · Total unread: \(listMeta.totalUnreadCount) · Limit: \(listMeta.limit) · Offset: \(listMeta.offset) · Filter mode: \(listMeta.unreadOnly ? "Unread only" : "All notifications")")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)

                        Text("Quick page meta: \(quickPageMetaLine)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)

                        Button("Copy quick page meta") {
                            copyQuickPageMetaLine()
                        }
                        .buttonStyle(.bordered)

                        if let quickPageMetaCopiedFeedbackText {
                            Text(quickPageMetaCopiedFeedbackText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.headline)

                    Text("Legend: ● read · ○ unread")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if notificationRows.isEmpty {
                        Text("No notifications loaded for this user yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(notificationRows) { row in
                            let isMutating = mutatingNotificationIDs.contains(row.id)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(row.notificationType)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                HStack(spacing: 10) {
                                    Text("read_state: \(row.readState)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: row.isRead ? "checkmark.circle.fill" : "circle")
                                        .font(.footnote)
                                        .foregroundStyle(row.isRead ? .green : .secondary)
                                }

                                Button {
                                    Task {
                                        await toggleReadState(for: row)
                                    }
                                } label: {
                                    Text(isMutating ? "Updating..." : "\(row.isRead ? "●" : "○") \(row.isRead ? "Mark unread" : "Mark read")")
                                }
                                .buttonStyle(.bordered)
                                .disabled(isMutating || isLoading)

                                Text("payload: \(row.payloadSummary)")
                                    .font(.footnote)
                                Text("notification_id: \(row.id)")
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
        .navigationTitle("Notifications")
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

    private var normalizedLimit: Int {
        min(max(Int(pageLimitDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 20, 1), 200)
    }

    private var normalizedOffset: Int {
        max(Int(pageOffsetDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, 0)
    }

    private var hasPendingWindowChange: Bool {
        guard let lastLoadedWindow else {
            return true
        }

        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return lastLoadedWindow.userID != trimmedUserID ||
            lastLoadedWindow.limit != normalizedLimit ||
            lastLoadedWindow.offset != normalizedOffset ||
            lastLoadedWindow.unreadOnly != pageUnreadOnly
    }

    private var loadButtonTitle: String {
        if isLoading {
            return "Loading notifications..."
        }

        return hasPendingWindowChange ? "Load notifications (window changed)" : "Load notifications"
    }

    private var pendingWindowHint: String {
        if lastLoadedWindow == nil {
            return "Window hint: no list window loaded yet. Load once to sync list and summary."
        }

        return hasPendingWindowChange
            ? "Window hint: current user/page/filter differs from last loaded window. Reload to sync."
            : "Window hint: current user/page/filter is in sync with last loaded window."
    }

    private var quickUnreadSummaryLine: String {
        guard let listMeta else {
            return "current_page_unread=(none) / total_unread_count=(none)"
        }

        return "current_page_unread=\(listMeta.unreadCount) / total_unread_count=\(listMeta.totalUnreadCount)"
    }

    private var quickUnreadSummaryCopiedFeedbackText: String? {
        guard let quickUnreadSummaryCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(quickUnreadSummaryCopiedAt)
        guard elapsed >= 0, elapsed < 6 else {
            return nil
        }

        return "Copied quick unread summary (\(Int(elapsed))s ago): \(lastQuickUnreadSummaryCopiedText)"
    }

    private var quickPageMetaLine: String {
        guard let listMeta else {
            return "count=(none) / unread_count=(none) / total_unread_count=(none) / limit=(none) / offset=(none) / filter_mode=(none)"
        }

        return "count=\(listMeta.count) / unread_count=\(listMeta.unreadCount) / total_unread_count=\(listMeta.totalUnreadCount) / limit=\(listMeta.limit) / offset=\(listMeta.offset) / filter_mode=\(listMeta.unreadOnly ? "unread_only" : "all")"
    }

    private var quickPageMetaCopiedFeedbackText: String? {
        guard let quickPageMetaCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(quickPageMetaCopiedAt)
        guard elapsed >= 0, elapsed < 6 else {
            return nil
        }

        return "Copied quick page meta (\(Int(elapsed))s ago): \(lastQuickPageMetaCopiedText)"
    }

    private var quickPageCursorSummaryLine: String {
        let cursorWindow = lastLoadedWindow ?? NotificationLoadWindow(
            userID: userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            limit: normalizedLimit,
            offset: normalizedOffset,
            unreadOnly: pageUnreadOnly
        )

        let countText = listMeta.map { String($0.count) } ?? "(none)"
        let unreadCountText = listMeta.map { String($0.unreadCount) } ?? "(none)"
        let totalUnreadCountText = listMeta.map { String($0.totalUnreadCount) } ?? "(none)"

        return "user_id=\(cursorWindow.userID.isEmpty ? "(empty)" : cursorWindow.userID) / limit=\(cursorWindow.limit) / offset=\(cursorWindow.offset) / filter_mode=\(cursorWindow.unreadOnly ? "unread_only" : "all") / count=\(countText) / unread_count=\(unreadCountText) / total_unread_count=\(totalUnreadCountText)"
    }

    private var quickPageCursorSummaryCopiedFeedbackText: String? {
        guard let quickPageCursorSummaryCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(quickPageCursorSummaryCopiedAt)
        guard elapsed >= 0, elapsed < 6 else {
            return nil
        }

        return "Copied quick page cursor summary (\(Int(elapsed))s ago): \(lastQuickPageCursorSummaryCopiedText)"
    }

    private var quickMutationDeltaLine: String {
        guard let lastMutationDelta else {
            return "notification_id=(none) / read_state=(none) / current_page_unread=(none) / total_unread_count=(none)"
        }

        return "notification_id=\(lastMutationDelta.notificationID) / read_state=\(lastMutationDelta.readState) / current_page_unread=\(lastMutationDelta.currentPageUnreadText) / total_unread_count=\(lastMutationDelta.totalUnreadCountText)"
    }

    private var quickMutationDeltaCopiedFeedbackText: String? {
        guard let quickMutationDeltaCopiedAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(quickMutationDeltaCopiedAt)
        guard elapsed >= 0, elapsed < 6 else {
            return nil
        }

        return "Copied quick mutation delta (\(Int(elapsed))s ago): \(lastQuickMutationDeltaCopiedText)"
    }

    private func prefillFromCurrentSessionUserIfNeeded() {
        guard userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        userIDDraft = currentSessionUserID
    }

    private func fillFromCurrentSessionUser() {
        guard let currentSessionUserID else {
            return
        }
        userIDDraft = currentSessionUserID
    }

    private func useCurrentSessionUserAndLoad() async {
        guard let currentSessionUserID else {
            fetchError = "Current session user không khả dụng."
            return
        }

        let currentDraftUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentDraftUserID == currentSessionUserID {
            statusMessage = "Session user already selected. Reloading first page for current user."
        } else {
            statusMessage = "Applied current session user. Reloading first page."
        }
        fetchError = nil

        userIDDraft = currentSessionUserID
        pageOffsetDraft = "0"
        await loadNotifications(forcedUserID: currentSessionUserID, forcedOffset: 0)
    }

    private func loadNotifications(forcedUserID: String? = nil, forcedOffset: Int? = nil) async {
        lastMutationDelta = nil
        let trimmedUserID = (forcedUserID ?? userIDDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để load notifications."
            return
        }

        let parsedLimit = Int(pageLimitDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 20
        let parsedOffset = Int(pageOffsetDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let safeLimit = min(max(parsedLimit, 1), 200)
        let safeOffset = max(forcedOffset ?? parsedOffset, 0)
        pageLimitDraft = String(safeLimit)
        pageOffsetDraft = String(safeOffset)

        isLoading = true
        fetchError = nil

        do {
            let payload = try await NotificationsAPIClient().fetchNotifications(
                userID: trimmedUserID,
                limit: safeLimit,
                offset: safeOffset,
                unreadOnly: pageUnreadOnly
            )
            notificationRows = payload.items
            listMeta = NotificationListMeta(
                count: payload.count,
                unreadCount: payload.unreadCount,
                totalUnreadCount: payload.totalUnreadCount,
                limit: safeLimit,
                offset: safeOffset,
                unreadOnly: pageUnreadOnly
            )
            mutatingNotificationIDs = []
            lastLoadedWindow = NotificationLoadWindow(
                userID: trimmedUserID,
                limit: safeLimit,
                offset: safeOffset,
                unreadOnly: pageUnreadOnly
            )
            statusMessage = "Loaded \(payload.count) notification(s). Page unread: \(payload.unreadCount). Total unread: \(payload.totalUnreadCount). Page window limit=\(safeLimit), offset=\(safeOffset), unread_only=\(pageUnreadOnly ? "true" : "false"). Use First/Prev/Next to move paging window quickly."
        } catch {
            notificationRows = []
            listMeta = nil
            mutatingNotificationIDs = []
            statusMessage = nil
            lastLoadedWindow = nil
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func createNotification() async {
        let trimmedUserID = userIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedType = createTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayload = createPayloadDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserID.isEmpty else {
            fetchError = "User UUID là bắt buộc để tạo notification."
            return
        }

        guard !trimmedType.isEmpty else {
            fetchError = "Notification type là bắt buộc."
            return
        }

        isCreatingNotification = true
        fetchError = nil

        do {
            let createdRow = try await NotificationsAPIClient().createNotification(
                userID: trimmedUserID,
                notificationType: trimmedType,
                payloadMessage: trimmedPayload.isEmpty ? "sent from ios notifications shell" : trimmedPayload
            )
            statusMessage = "Created notification \(createdRow.id). Reloading list..."
            lastLoadedWindow = nil
            await loadNotifications()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingNotification = false
    }

    private func toggleReadState(for row: NotificationRow) async {
        guard !mutatingNotificationIDs.contains(row.id) else {
            return
        }

        mutatingNotificationIDs.insert(row.id)
        defer {
            mutatingNotificationIDs.remove(row.id)
        }

        fetchError = nil

        do {
            let updated = try await NotificationsAPIClient().setNotificationReadState(notificationID: row.id, read: !row.isRead)
            if let index = notificationRows.firstIndex(where: { $0.id == updated.id }) {
                notificationRows[index] = updated
            }

            var nextMeta = listMeta
            if var currentMeta = listMeta {
                let unreadDelta: Int
                if row.isRead == updated.isRead {
                    unreadDelta = 0
                } else {
                    unreadDelta = updated.isRead ? -1 : 1
                }

                if unreadDelta != 0 {
                    currentMeta = NotificationListMeta(
                        count: currentMeta.count,
                        unreadCount: max(0, currentMeta.unreadCount + unreadDelta),
                        totalUnreadCount: max(0, currentMeta.totalUnreadCount + unreadDelta),
                        limit: currentMeta.limit,
                        offset: currentMeta.offset,
                        unreadOnly: currentMeta.unreadOnly
                    )
                    listMeta = currentMeta
                }
                nextMeta = currentMeta
            }

            let mutationDelta = NotificationMutationDelta(
                notificationID: updated.id,
                readState: updated.isRead ? "read" : "unread",
                currentPageUnread: nextMeta?.unreadCount,
                totalUnreadCount: nextMeta?.totalUnreadCount
            )
            lastMutationDelta = mutationDelta

            let mutationDeltaLine = "notification_id=\(mutationDelta.notificationID) / read_state=\(mutationDelta.readState) / current_page_unread=\(mutationDelta.currentPageUnreadText) / total_unread_count=\(mutationDelta.totalUnreadCountText)"
            statusMessage = updated.isRead
                ? "Marked notification \(updated.id) as read (●). Quick mutation delta: \(mutationDeltaLine)."
                : "Marked notification \(updated.id) as unread (○). Quick mutation delta: \(mutationDeltaLine)."
            lastLoadedWindow = nil
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func copyQuickUnreadSummaryLine() {
        let normalizedText = quickUnreadSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        writeToClipboard(normalizedText)
        lastQuickUnreadSummaryCopiedText = normalizedText
        quickUnreadSummaryCopiedAt = Date()
        statusMessage = "Copied quick unread summary to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickPageMetaLine() {
        let normalizedText = quickPageMetaLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        writeToClipboard(normalizedText)
        lastQuickPageMetaCopiedText = normalizedText
        quickPageMetaCopiedAt = Date()
        statusMessage = "Copied quick page meta to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickPageCursorSummaryLine() {
        let normalizedText = quickPageCursorSummaryLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        writeToClipboard(normalizedText)
        lastQuickPageCursorSummaryCopiedText = normalizedText
        quickPageCursorSummaryCopiedAt = Date()
        statusMessage = "Copied quick page cursor summary to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func copyQuickMutationDeltaLine() {
        guard lastMutationDelta != nil else {
            statusMessage = "quick_mutation_delta_missing"
            return
        }

        let normalizedText = quickMutationDeltaLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        writeToClipboard(normalizedText)
        lastQuickMutationDeltaCopiedText = normalizedText
        quickMutationDeltaCopiedAt = Date()
        statusMessage = "Copied quick mutation delta to clipboard (\(normalizedText))."
        fetchError = nil
    }

    private func writeToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}

private struct NotificationRow: Identifiable {
    let id: String
    let notificationType: String
    let payloadSummary: String
    let isRead: Bool

    var readState: String {
        isRead ? "read" : "unread"
    }
}

private struct NotificationListMeta {
    let count: Int
    let unreadCount: Int
    let totalUnreadCount: Int
    let limit: Int
    let offset: Int
    let unreadOnly: Bool
}

private struct NotificationLoadWindow {
    let userID: String
    let limit: Int
    let offset: Int
    let unreadOnly: Bool
}

private struct NotificationMutationDelta {
    let notificationID: String
    let readState: String
    let currentPageUnread: Int?
    let totalUnreadCount: Int?

    var currentPageUnreadText: String {
        currentPageUnread.map(String.init) ?? "(none)"
    }

    var totalUnreadCountText: String {
        totalUnreadCount.map(String.init) ?? "(none)"
    }
}

private struct NotificationListPayload {
    let count: Int
    let unreadCount: Int
    let totalUnreadCount: Int
    let items: [NotificationRow]
}

private struct NotificationsAPIClient {
    private struct NotificationListResponse: Decodable {
        let count: Int
        let unread_count: Int?
        let total_unread_count: Int?
        let items: [NotificationResponse]
    }

    private struct NotificationResponse: Decodable {
        let id: String
        let user_id: String
        let notification_type: String
        let payload_json: [String: StringOrIntOrBool]
        let read_at: String?
    }

    private struct NotificationCreateRequest: Encodable {
        let user_id: String
        let notification_type: String
        let payload_json: [String: String]
    }

    private enum StringOrIntOrBool: Decodable, CustomStringConvertible {
        case string(String)
        case int(Int)
        case bool(Bool)
        case double(Double)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else {
                throw DecodingError.typeMismatch(
                    StringOrIntOrBool.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Unsupported payload value type")
                )
            }
        }

        var description: String {
            switch self {
            case let .string(value): return value
            case let .int(value): return String(value)
            case let .bool(value): return value ? "true" : "false"
            case let .double(value): return String(value)
            }
        }
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
                return "Thiếu backend base URL hợp lệ cho notifications shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend notifications response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func fetchNotifications(userID: String, limit: Int, offset: Int, unreadOnly: Bool) async throws -> NotificationListPayload {
        let url = try makeURL(path: "/notifications/\(userID)", queryItems: [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "unread_only", value: unreadOnly ? "true" : "false"),
        ])
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notifications fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationListResponse.self, from: data)
            let mappedRows = payload.items.map(mapNotification)
            let fallbackUnreadCount = mappedRows.filter { !$0.isRead }.count
            let unreadCount = payload.unread_count ?? fallbackUnreadCount

            return NotificationListPayload(
                count: payload.count,
                unreadCount: unreadCount,
                totalUnreadCount: payload.total_unread_count ?? unreadCount,
                items: mappedRows
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createNotification(userID: String, notificationType: String, payloadMessage: String) async throws -> NotificationRow {
        var request = URLRequest(url: try makeURL(path: "/notifications"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            NotificationCreateRequest(
                user_id: userID,
                notification_type: notificationType,
                payload_json: [
                    "source": "ios_notifications_shell",
                    "message": payloadMessage,
                ]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notification create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationResponse.self, from: data)
            return mapNotification(payload)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func setNotificationReadState(notificationID: String, read: Bool) async throws -> NotificationRow {
        let path = read ? "/notifications/\(notificationID)/read" : "/notifications/\(notificationID)/unread"
        var request = URLRequest(url: try makeURL(path: path))
        request.httpMethod = "PATCH"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Notification mutation failed"))
        }

        do {
            let payload = try JSONDecoder().decode(NotificationResponse.self, from: data)
            return mapNotification(payload)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func mapNotification(_ payload: NotificationResponse) -> NotificationRow {
        NotificationRow(
            id: payload.id,
            notificationType: payload.notification_type,
            payloadSummary: payload.payload_json
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value.description)" }
                .joined(separator: ", "),
            isRead: payload.read_at != nil
        )
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard let baseURL else {
            throw APIError.invalidBaseURL
        }

        let base = baseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidBaseURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
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
