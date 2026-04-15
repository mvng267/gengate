import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct InboxPlaceholderView: View {
    @Environment(AppSessionStore.self) private var sessionStore

    @State private var userAIDDraft: String = ""
    @State private var userBIDDraft: String = ""
    @State private var conversationSummary: DirectConversationSummary?
    @State private var conversationMembers: [InboxConversationMemberRow] = []
    @State private var messageRows: [InboxMessageRow] = []
    @State private var attachmentMap: [String: [InboxAttachmentRow]] = [:]
    @State private var deviceKeyMap: [String: [InboxDeviceKeyRow]] = [:]
    @State private var messageDraft: String = ""
    @State private var attachmentTargetMessageIDDraft: String = ""
    @State private var deviceKeyTargetMessageIDDraft: String = ""
    @State private var readCursorTargetUserIDDraft: String = ""
    @State private var readCursorTargetMessageIDDraft: String = ""
    @State private var readStatusFocusUserIDDraft: String = ""
    @State private var recipientUserIDDraft: String = ""
    @State private var recipientDeviceIDDraft: String = ""
    @State private var recipientDeviceOptions: [InboxDeviceOptionRow] = []
    @State private var isLoadingRecipientDevices = false
    @State private var recipientDevicesAutoReloadTask: Task<Void, Never>?
    @State private var lastRecipientDevicesAutoReloadAt: Date?
    @State private var lastRecipientDevicesRateLimitSkipAt: Date?
    @State private var wrappedMessageKeyBlobDraft: String = "ios-demo-wrapped-message-key"
    @State private var messageToDeleteIDDraft: String = ""
    @State private var attachmentTypeDraft: String = "image"
    @State private var attachmentStorageKeyDraft: String = "attachments/ios-demo-image.enc"
    @State private var attachmentBlobDraft: String = "ios-demo-attachment-blob"
    @State private var fetchError: String?
    @State private var isLoading = false
    @State private var isSendingMessage = false
    @State private var sendStatusHint: String?
    @State private var lastSendQuickCopy: String = "sender=(none) | message_id=(none)"
    @State private var lastReadCursorApplyQuickCopy: String = "target_user=(none) | previous_cursor_message=(none) | applied_message=(none) | current_member_cursor=(none) | focus_user=(none) | read_state=unknown | read_cursor_apply_state=unknown"
    @State private var lastReadCursorTriageQuickCopy: String = "read_cursor_triage=target_user:(none),previous:(none),applied:(none),current:(none),apply_state:unknown"
    @State private var lastFirstUnreadJumpQuickCopy: String = "focus_user=(none) | first_unread_candidate=(none) | applied_message=(none) | read_state=unknown"
    @State private var lastFirstUnreadGuardQuickCopy: String = "focus_user=(none) | first_unread_guard_state=unknown | candidate=(none)"
    @State private var isCreatingAttachment = false
    @State private var isCreatingDeviceKey = false
    @State private var isUpdatingReadCursor = false
    @State private var isDeletingMessage = false
    @State private var autoRefreshEnabled = false
    @State private var lastCursorFormSyncSummary: String?
    @State private var lastCursorFormSyncAt: Date?
    @State private var lastRecipientDeviceContextResetReason: String?
    @State private var lastRecipientDeviceContextResetAt: Date?
    @State private var lastRecipientDeviceContextResetUserID: String?
    @State private var lastRecipientDeviceSourceHintCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchKeyCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchKeyCopyText: String?
    @State private var lastRecipientDeviceSourceHintReportPayloadCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintReportPayloadCopyText: String?
    @State private var lastRecipientDeviceSourceHintMatrixSnapshotCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintMatrixSnapshotCopyText: String?
    @State private var lastRecipientDeviceSourceHintTriageLineCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintTriageLineCopyText: String?
    @State private var lastRecipientDeviceSourceHintTriageLineBodyCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintTriageLineBodyCopyText: String?
    @State private var lastRecipientDeviceSourceHintDiffHintCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintDiffHintCopyText: String?
    @State private var lastRecipientDeviceSourceHintUsageNoteCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintUsageNoteCopyText: String?
    @State private var lastRecipientDeviceSourceHintTriageKitCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintTriageKitCopyText: String?
    @State private var lastRecipientDeviceSourceHintTriageKitPreviewCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintTriageKitPreviewCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewDeltaCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewDeltaCopyText: String?
    @State private var lastRecipientDeviceSourceHintTriagePreviewPairCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintTriagePreviewPairCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairUseWhenCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairUseWhenCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyText: String?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchPreviewTokenCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchPreviewTokenCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyText: String?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyAt: Date?
    @State private var lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyText: String?

    private let recipientDevicesAutoReloadDebounceNanoseconds: UInt64 = 350_000_000
    private let recipientDevicesAutoReloadMinIntervalSeconds: TimeInterval = 1.0

    private static let recipientSourceHintReportTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeaturePlaceholderView(
                    title: "Inbox",
                    summary: "iOS native inbox shell. Use two real user UUIDs to resolve a direct conversation, send text, create attachment/device-key metadata, auto-load recipient devices, and inspect read-cursor/member summary state via the same backend contracts as web.",
                    status: "Status: native inbox now supports text send + attachment create/list + device-key create/list + recipient-device fetch + read-cursor updates + focused read/unread indicator + member cursor summary + quick latest-read action + read-cursor presets + cursor ordering hints + first-unread jump action + row-tap cursor form picker + member-cursor message target picker + cursor-form sync hint with stale-target guards + recipient-device fallback/auto-reload/rate-limit guards + skip-hint reset + bounded event timestamps + clear-input/thread-switch/load-failure/non-member recipient-device context reset + explicit reset-reason helper note + input-change helper-note reset + empty-context-only helper-note visibility + short recipient-id mismatch hint + compact helper-note reason + readable short-caption mapping + recipient quick-member presets + dynamic first-valid-device apply/re-apply action + first-option inline subtitle (full + short id) + emphasized short-id line + source-hint short-id consistency across first-option/in-sync/manual/fallback states + same-as-first skip helper-note + empty-options reapply guidance + source-hint verify matrix + branch-key legend + matrix snapshot quick-copy + triage-line quick-copy + triage-line body quick-copy + triage preview line-vs-body block + compact diff hint + usage guidance note + usage-note quick-copy + triage-kit quick-copy + triage-kit compact preview + triage-kit preview quick-copy + preview delta marker + preview-delta quick-copy + preview-pair quick-copy + preview-pair use marker + preview-pair use-marker quick-copy + preview-pair-lite quick-copy + preview-pair-lite preview-line quick-copy + preview-pair-lite tag-header quick-copy + preview-pair-lite use-when-line quick-copy + preview-pair-lite condensed-line quick-copy + branch-preview token quick-copy + branch-use-when-preview quick-copy + branch-use-when-preview tagged-block quick-copy + branch-summary tag-header quick-copy + branch-summary compact-bundle quick-copy + branch-use-when-preview-lite quick-copy + preview-pair-lite inline scan block + selection-source hint + one-tap device UUID clear action; realtime delivery remains pending.",
                    bullets: [
                        "Enter two distinct backend user UUIDs that already participate in a direct conversation or can be resolved into one.",
                        "This shell calls `/conversations/direct`, `/conversations/{id}/members`, `/messages?conversation_id=<uuid>`, `/messages/{id}/attachments`, `/messages/{id}/device-keys`, and `/auth/devices/{user_id}`.",
                        "You can now call `PATCH /conversations/{id}/members/{user_id}/read-cursor` directly from iOS to move read cursor and observe `last_read_by` + focused `read_status(user)` + member cursor summary in-shell.",
                        "Quick action `Mark latest message as read (focus user)` helps testers advance read cursor to newest loaded row with one tap.",
                        "Quick action `Use current session user as read-cursor target + read focus` đồng bộ cả `Member user UUID` và `Read-status focus user UUID` để retest read parity không cần nhập tay.",
                        "Quick preset buttons now let testers pick member/message targets without copy-pasting UUIDs manually.",
                        "Member summary now shows cursor ordering hint + unread count behind cursor to spot lagging read state quickly.",
                        "Quick action `Jump focus user to first unread candidate` advances cursor to the earliest unread loaded message for the focus user.",
                        "In member summary, tapping a user row now sets `Read-status focus user UUID` and `Member user UUID` together (no manual paste).",
                        "Each member card now has quick action to copy its `last_read_message_id` into `Last-read message UUID` target.",
                        "Member row tap now applies full read-cursor form context (`Read-status focus user UUID` + `Member user UUID` + optional `Last-read message UUID`).",
                        "Read-cursor form now shows a brief sync hint after row tap so testers can verify which member/context was just applied.",
                        "After thread reload, sync hint refreshes to current read-cursor form values to avoid stale context text.",
                        "When direct-thread identity inputs (User A/User B) change, sync hint is cleared immediately to avoid carry-over across threads.",
                        "If thread load fails and conversation state resets, sync hint is also cleared to keep form context truthful.",
                        "If direct conversation member list comes back empty, sync hint is cleared to avoid implying usable read-cursor context.",
                        "Manual read-cursor target message UUID is now auto-cleared when it no longer exists in loaded message rows (stale target guard).",
                        "Manual read-cursor target user UUID is now auto-cleared when it no longer belongs to current conversation members.",
                        "Manual read-status focus user UUID is now auto-cleared when it no longer belongs to current conversation members.",
                        "Manual delete-target message UUID is now auto-cleared when it no longer exists in loaded message rows.",
                        "Manual attachment/device-key target message UUIDs are now auto-cleared when they no longer exist in loaded message rows.",
                        "Recipient device UUID draft is now validated against refreshed `/auth/devices/{user_id}` options and auto-fallbacks to first valid device when stale.",
                        "Recipient device list now auto-reloads (debounced + rate-limited) when `Recipient user UUID` changes, reducing manual reload friction and burst calls in device-key flow.",
                        "When auto reload is skipped by rate-limit guard, a short helper hint appears so testers know why options are not refreshed yet.",
                        "Manual `Reload recipient devices` now explicitly clears skip-hint state before/after reload so UI reflects freshest fetch path.",
                        "Recipient-device section now surfaces tiny event timestamps for latest auto-reload and rate-limit skip events (bounded visibility window) to help human testers debug behavior quickly without long-run UI noise.",
                        "After timestamp hints auto-hide (>20s), the UI shows a brief passive note so testers know it is intentional behavior, not missing data.",
                        "Clearing `Recipient user UUID` now also clears auto-reload timestamp state to prevent cross-context leftover debug notes.",
                        "Switching direct-thread identity (`User A`/`User B`) now also clears recipient-device timestamp debug state to avoid cross-thread carry-over.",
                        "Switching direct-thread identity (`User A`/`User B`) now clears recipient-device user/device drafts + options immediately to prevent stale device-target actions before next reload.",
                        "If direct-thread load fails and thread state resets, recipient-device user/device/options are now cleared in the same reset path so stale targets do not leak across recovery flows.",
                        "After successful thread load, if current recipient user is not in loaded conversation members, recipient-device context is auto-cleared to avoid cross-conversation stale target carry-over.",
                        "When non-member auto-clear happens, inbox now shows a short inline reset-reason helper note (~20s) so testers know this reset is intentional.",
                        "Typing a new `Recipient user UUID` now clears the previous reset-reason helper note immediately to avoid stale explanation text in the new context.",
                        "Reset-reason helper note is now shown only while recipient context is still empty (user/device/options all empty) after auto-clear, reducing visual noise once context is refilled.",
                        "Non-member auto-clear helper note now includes a shortened recipient user id (e.g. `abcd…wxyz`) so testers can quickly map mismatch context without full UUID scanning.",
                        "Reset helper note now uses a compact reason label (`non_member_after_switch`) to reduce line-wrap noise on narrow iPhone layouts.",
                        "Helper note now maps compact reason labels to short human-readable captions (e.g. `non-member after switch`) so UI stays concise but understandable for testers.",
                        "Recipient-device form now has quick member preset buttons so testers can fill `Recipient user UUID` from current conversation members without manual copy/paste.",
                        "After recipient devices are loaded, one dynamic action now handles both apply/re-apply first valid device depending on whether current recipient device UUID is empty or stale.",
                        "Dynamic first-valid action now includes an inline subtitle with target first-option UUID + short-id so testers can scan quickly on narrow screens before tapping.",
                        "Short-id target fragment is now rendered on its own emphasized line (`Short target ID`) to make scan-state clearer when UUIDs are long.",
                        "Selection-source hint now explicitly labels in-sync cases that already match first option (`same as first option`) so testers can skip redundant re-apply taps.",
                        "`same as first option` hint now also includes short-id fragment for faster scan when first UUID is long.",
                        "When selection is already same-as-first, a tiny helper note now says re-apply can be skipped to reduce redundant taps.",
                        "Helper-note now also clarifies empty-options context (`load devices first`) so testers don't misread re-apply availability before options exist.",
                        "Empty-state `first option` source hint now includes short-id fragment to keep scan pattern consistent with in-sync same-as-first hints.",
                        "When empty-state has no first option yet, source hint now explicitly marks `short-id chưa khả dụng` to keep fallback semantics clear.",
                        "Manual out-of-options source hint now uses compact label + short-id (`manual UUID/out-of-options`) for quicker mismatch scanning.",
                        "In-sync (non-first) source hint now also includes short-id fragment for consistent scan speed across all valid-selection states.",
                        "Short-id prefix label is now unified (`short-id`) across in-sync non-first and manual/out-of-options source hints for copy consistency.",
                        "First-option empty-state source hint now also uses `short-id` prefix (instead of `short`) so all source-hint branches share identical wording.",
                        "Status summary wording is now compacted into a single source-hint consistency phrase to match current `short-id`-normalized behavior across all branches.",
                        "Recipient-device section now shows a compact source-hint verify matrix so testers can quickly map current state against expected hint fragment before executing device-key actions.",
                        "Added quick action `Copy source hint` to copy the current runtime source-hint string for bug reports and triage notes.",
                        "Added quick action `Copy source-hint report payload` to capture a compact triage line (branch key + recipient user/device short-id + hint + timestamp).",
                        "Recipient-device section now shows `Source-hint branch key` (e.g. `empty-first`, `sync-first`, `sync-nonfirst`, `manual-oob`) to map UI state quickly with payload logs.",
                        "Added quick action `Copy source-hint branch key` so testers can paste only the compact state token when full payload is unnecessary.",
                        "Source-hint area now includes a mini branch-key legend to decode each token (`empty-first`, `empty-none`, `sync-first`, `sync-nonfirst`, `manual-oob`) without leaving the screen.",
                        "Added quick action `Copy source-hint matrix snapshot` to capture verify matrix + branch-key legend + current branch key in one compact multiline block for report templates.",
                        "Added quick action `Copy source-hint triage line` to capture branch key + selection-source hint + reapply-guidance in one compact single line for quick bug notes.",
                        "Added quick action `Copy source-hint triage body` to copy the same triage content without prefix tag, ready for issue title/body paste.",
                        "Source-hint area now shows a small side-by-side triage preview block (`line` vs `body`) so testers can compare tagged/untagged forms before copying.",
                        "Added compact `Diff hint` line to make the only difference explicit: `line = body + prefix tag [inbox-source-hint-triage]`.",
                        "Added quick action `Copy source-hint diff hint` to reuse the exact clarification sentence in onboarding/debug notes.",
                        "Triage preview block now includes a compact usage note (`line` for tagged logs/search, `body` for concise issue text, `diff hint` for onboarding/explanation).",
                        "Added quick action `Copy source-hint usage note` so testers can paste the same line directly into bug-report templates/onboarding docs.",
                        "Added quick action `Copy source-hint triage kit` to copy one bundled payload (line/body/diff/usage) for single-paste bug reports.",
                        "Triage preview now includes a compact triage-kit preview line (branch + shortened line/body) so testers can scan payload intent before copying.",
                        "Added quick action `Copy source-hint triage-kit preview` to copy the compact preview line directly into short bug notes.",
                        "Triage preview now includes a compact `Preview delta` marker so testers can see exactly what compact preview omits vs full triage-kit (`diff/usage`).",
                        "Added quick action `Copy source-hint preview delta` to copy that compact-vs-full explanation line directly into bug notes/onboarding docs.",
                        "Added quick action `Copy source-hint preview pair` to copy one short block combining compact preview + preview-delta hint for single-paste triage notes.",
                        "Preview-pair payload now includes `use_when=...` marker so bug notes carry immediate context about when preview-pair should be used.",
                        "Added quick action `Copy source-hint preview-pair use-when` to reuse only the context marker line in onboarding/debug notes.",
                        "Added quick action `Copy source-hint preview-pair-lite` to copy a super-short block (`use_when + preview`) for compact triage notes.",
                        "Added quick action `Copy source-hint preview-pair-lite preview` to copy only the `preview=...` line for ultra-short issue titles.",
                        "Added quick action `Copy source-hint preview-pair-lite tag` to copy only header tag `[inbox-source-hint-triage-preview-pair-lite]` for fast block separation in long notes.",
                        "Added quick action `Copy source-hint preview-pair-lite use-when` to copy only line `use_when=...` for cases where context needs to be pasted separately from payload lines.",
                        "Added quick action `Copy source-hint preview-pair-lite condensed` to copy one-line compact marker `use_when=... | preview=...` for ultra-short issue title/body notes.",
                        "Added quick action `Copy source-hint branch-preview token` to copy short token `branch=<key> | preview=...` for quick issue label/summary tagging.",
                        "Added quick action `Copy source-hint branch-use-when-preview` to copy one-line heading `branch=<key> | use_when=... | preview=...` for issue summary blocks.",
                        "Added quick action `Copy source-hint branch-use-when-preview tagged` to copy one compact tagged block (`[inbox-source-hint-triage-branch-summary]` + branch/use_when/preview line) for ticket note paste.",
                        "Added quick action `Copy source-hint branch-summary tag` to copy only tag header `[inbox-source-hint-triage-branch-summary]` for flexible note composition.",
                        "Added quick action `Copy source-hint branch-summary compact bundle` to copy compact block (`tag + summary + branch-preview token`) for one-paste ticket templates.",
                        "Added quick action `Copy source-hint branch-use-when-preview-lite` to copy ultra-short one-line marker `use_when=... | preview=...` (không tag/header) cho issue title/body ngắn.",
                        "Triage preview now renders inline `preview-pair-lite` block so testers can scan payload content before tapping copy.",
                        "After copy, short-lived feedback lines show elapsed time + short fragment so testers can confirm exactly what was captured.",
                        "Recipient-device section now shows a compact selection-source hint so testers know whether current `Recipient device UUID` is in-sync with loaded options or still a manual out-of-options value.",
                        "One-tap action `Clear recipient device UUID` helps testers reset stale/manual device input instantly before selecting a fresh option."
                    ]
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Direct thread reader")
                        .font(.headline)

                    TextField("User A UUID", text: $userAIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: userAIDDraft) {
                            handleDirectThreadIdentityChange()
                        }

                    TextField("User B UUID", text: $userBIDDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: userBIDDraft) {
                            handleDirectThreadIdentityChange()
                        }

                    Button("Use current session user for User A") {
                        fillUserAFromCurrentSession()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentSessionUserID == nil)

                    Button {
                        Task {
                            await applyCurrentSessionUserAsUserAUserBAndOpenDirectThread()
                        }
                    } label: {
                        Text(isLoading ? "Applying session user + loading..." : "Use current session user as user_a + user_b + open direct thread")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || currentSessionUserID == nil)

                    Button {
                        Task {
                            await loadInboxThread()
                        }
                    } label: {
                        Text(isLoading ? "Loading inbox thread..." : "Load inbox thread")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Send text message as User A")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Message text", text: $messageDraft)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await applyCurrentSessionUserAsUserAAndSend()
                            }
                        } label: {
                            Text(isSendingMessage ? "Sending message..." : "Use current session user as User A + send")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            conversationSummary == nil ||
                            currentSessionUserID == nil ||
                            messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button {
                            Task {
                                await sendMessage()
                            }
                        } label: {
                            Text(isSendingMessage ? "Sending message..." : "Send message")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            conversationSummary == nil ||
                            userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create attachment metadata")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Target message UUID (optional, defaults to newest loaded)", text: $attachmentTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Attachment type", text: $attachmentTypeDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Storage key (optional)", text: $attachmentStorageKeyDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Encrypted blob placeholder", text: $attachmentBlobDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await createAttachment()
                            }
                        } label: {
                            Text(isCreatingAttachment ? "Creating attachment..." : "Create attachment")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isDeletingMessage ||
                            isCreatingAttachment ||
                            conversationSummary == nil ||
                            (resolvedAttachmentTargetMessageID?.isEmpty ?? true) ||
                            attachmentTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            attachmentBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create message device key")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Target message UUID (optional, defaults to newest loaded)", text: $deviceKeyTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Recipient user UUID", text: $recipientUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: recipientUserIDDraft) {
                                if lastRecipientDeviceContextResetReason != nil {
                                    lastRecipientDeviceContextResetReason = nil
                                    lastRecipientDeviceContextResetAt = nil
                                    lastRecipientDeviceContextResetUserID = nil
                                }

                                let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedRecipientUserID.isEmpty,
                                   !trimmedRecipientDeviceID.isEmpty,
                                   !recipientDeviceOptions.contains(where: { $0.id == trimmedRecipientDeviceID }) {
                                    recipientDeviceIDDraft = ""
                                }

                                recipientDevicesAutoReloadTask?.cancel()

                                guard !trimmedRecipientUserID.isEmpty else {
                                    recipientDeviceOptions = []
                                    recipientDeviceIDDraft = ""
                                    lastRecipientDevicesAutoReloadAt = nil
                                    lastRecipientDevicesRateLimitSkipAt = nil
                                    return
                                }

                                recipientDevicesAutoReloadTask = Task {
                                    try? await Task.sleep(nanoseconds: recipientDevicesAutoReloadDebounceNanoseconds)
                                    guard !Task.isCancelled else {
                                        return
                                    }

                                    let latestRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard latestRecipientUserID == trimmedRecipientUserID else {
                                        return
                                    }

                                    let now = Date()
                                    if let lastRecipientDevicesAutoReloadAt,
                                       now.timeIntervalSince(lastRecipientDevicesAutoReloadAt) < recipientDevicesAutoReloadMinIntervalSeconds {
                                        lastRecipientDevicesRateLimitSkipAt = now
                                        return
                                    }

                                    lastRecipientDevicesAutoReloadAt = now
                                    lastRecipientDevicesRateLimitSkipAt = nil
                                    await loadRecipientDevices(silent: true)
                                }
                            }

                        if !conversationMembers.isEmpty {
                            let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick recipient member presets")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(conversationMembers) { member in
                                            Button {
                                                recipientUserIDDraft = member.userID
                                            } label: {
                                                Text(
                                                    member.userID == trimmedRecipientUserID
                                                    ? "✓ \(shortUserID(member.userID))"
                                                    : shortUserID(member.userID)
                                                )
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                }

                                Text("Tap để điền nhanh `Recipient user UUID` từ member list hiện tại.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if isLoadingRecipientDevices {
                            Text("Recipient devices: loading...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else if recipientDeviceOptions.isEmpty {
                            Text("Recipient devices: chưa load (nhập Recipient user UUID để fetch `/auth/devices/{user_id}`)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Recipient device", selection: $recipientDeviceIDDraft) {
                                Text("Select recipient device UUID").tag("")
                                ForEach(recipientDeviceOptions) { option in
                                    Text("\(option.deviceName) · \(option.platform) · \(option.deviceTrustState) · \(option.id)")
                                        .tag(option.id)
                                }
                            }
#if os(iOS)
                            .pickerStyle(.menu)
#endif
                        }

                        TextField("Recipient device UUID", text: $recipientDeviceIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let recipientDeviceContextResetHintText {
                            Text(recipientDeviceContextResetHintText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if !recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           !recipientDeviceOptions.isEmpty,
                           !recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           !recipientDeviceOptions.contains(where: { $0.id == recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) }) {
                            Text("Recipient device UUID không còn trong danh sách thiết bị hiện tại; bấm `Reload recipient devices` để fallback về thiết bị hợp lệ.")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }

                        if let recipientDeviceSelectionSourceHintText {
                            Text(recipientDeviceSelectionSourceHintText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if let recipientDeviceSourceHintBranchKey {
                                Text("Source-hint branch key: \(recipientDeviceSourceHintBranchKey)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    copyRecipientDeviceSourceHint(recipientDeviceSelectionSourceHintText)
                                } label: {
                                    Text("Copy source hint")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    copyRecipientDeviceSourceHintBranchKey()
                                } label: {
                                    Text("Copy source-hint branch key")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchKey == nil)

                                Button {
                                    copyRecipientDeviceSourceHintReportPayload()
                                } label: {
                                    Text("Copy source-hint report payload")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintReportPayloadText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintMatrixSnapshot()
                                } label: {
                                    Text("Copy source-hint matrix snapshot")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintMatrixSnapshotText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintTriageLine()
                                } label: {
                                    Text("Copy source-hint triage line")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriageLineText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintTriageLineBody()
                                } label: {
                                    Text("Copy source-hint triage body")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriageLineBodyText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintDiffHint()
                                } label: {
                                    Text("Copy source-hint diff hint")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    copyRecipientDeviceSourceHintUsageNote()
                                } label: {
                                    Text("Copy source-hint usage note")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    copyRecipientDeviceSourceHintTriageKit()
                                } label: {
                                    Text("Copy source-hint triage kit")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriageKitText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintTriageKitPreview()
                                } label: {
                                    Text("Copy source-hint triage-kit preview")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriageKitCompactPreviewText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewDelta()
                                } label: {
                                    Text("Copy source-hint preview delta")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriageKitPreviewDeltaHintText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintTriagePreviewPair()
                                } label: {
                                    Text("Copy source-hint preview pair")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairUseWhen()
                                } label: {
                                    Text("Copy source-hint preview-pair use-when")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairUseWhenText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairLite()
                                } label: {
                                    Text("Copy source-hint preview-pair-lite")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairLiteText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairLitePreviewLine()
                                } label: {
                                    Text("Copy source-hint preview-pair-lite preview")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairLiteTagHeader()
                                } label: {
                                    Text("Copy source-hint preview-pair-lite tag")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairLiteTagHeaderText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairLiteUseWhenLine()
                                } label: {
                                    Text("Copy source-hint preview-pair-lite use-when")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintPreviewPairLiteCondensedLine()
                                } label: {
                                    Text("Copy source-hint preview-pair-lite condensed")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintTriagePreviewPairLiteCondensedLineText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchPreviewToken()
                                } label: {
                                    Text("Copy source-hint branch-preview token")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchPreviewTokenText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchUseWhenPreviewSummary()
                                } label: {
                                    Text("Copy source-hint branch-use-when-preview")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchUseWhenPreviewSummaryText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlock()
                                } label: {
                                    Text("Copy source-hint branch-use-when-preview tagged")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchSummaryTagHeader()
                                } label: {
                                    Text("Copy source-hint branch-summary tag")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchSummaryTagHeaderText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchSummaryCompactBundle()
                                } label: {
                                    Text("Copy source-hint branch-summary compact bundle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchSummaryCompactBundleText == nil)

                                Button {
                                    copyRecipientDeviceSourceHintBranchUseWhenPreviewLite()
                                } label: {
                                    Text("Copy source-hint branch-use-when-preview-lite")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(recipientDeviceSourceHintBranchUseWhenPreviewLiteText == nil)
                            }

                            if let recipientDeviceSourceHintCopiedFeedbackText {
                                Text(recipientDeviceSourceHintCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchKeyCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchKeyCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintReportPayloadCopiedFeedbackText {
                                Text(recipientDeviceSourceHintReportPayloadCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintMatrixSnapshotCopiedFeedbackText {
                                Text(recipientDeviceSourceHintMatrixSnapshotCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintTriageLineCopiedFeedbackText {
                                Text(recipientDeviceSourceHintTriageLineCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintTriageLineBodyCopiedFeedbackText {
                                Text(recipientDeviceSourceHintTriageLineBodyCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintDiffHintCopiedFeedbackText {
                                Text(recipientDeviceSourceHintDiffHintCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintUsageNoteCopiedFeedbackText {
                                Text(recipientDeviceSourceHintUsageNoteCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintTriageKitCopiedFeedbackText {
                                Text(recipientDeviceSourceHintTriageKitCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintTriageKitPreviewCopiedFeedbackText {
                                Text(recipientDeviceSourceHintTriageKitPreviewCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewDeltaCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewDeltaCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintTriagePreviewPairCopiedFeedbackText {
                                Text(recipientDeviceSourceHintTriagePreviewPairCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairUseWhenCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairUseWhenCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairLiteCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairLiteCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairLitePreviewLineCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairLitePreviewLineCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairLiteTagHeaderCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairLiteTagHeaderCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairLiteUseWhenLineCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairLiteUseWhenLineCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintPreviewPairLiteCondensedLineCopiedFeedbackText {
                                Text(recipientDeviceSourceHintPreviewPairLiteCondensedLineCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchPreviewTokenCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchPreviewTokenCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchUseWhenPreviewSummaryCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchUseWhenPreviewSummaryCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchSummaryTagHeaderCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchSummaryTagHeaderCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchSummaryCompactBundleCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchSummaryCompactBundleCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let recipientDeviceSourceHintBranchUseWhenPreviewLiteCopiedFeedbackText {
                                Text(recipientDeviceSourceHintBranchUseWhenPreviewLiteCopiedFeedbackText)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Source-hint verify matrix: empty+first→`first option ... short-id`; empty+no-options→`short-id chưa khả dụng`; in-sync+first→`same as first option`; in-sync+non-first→`in-sync, short-id`; manual/out-of-options→`manual UUID/out-of-options`.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("Branch-key legend: empty-first→empty + có first option; empty-none→empty + chưa có option; sync-first→in-sync + first option; sync-nonfirst→in-sync + non-first option; manual-oob→manual/out-of-options.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let recipientDeviceSourceHintTriageLineText,
                           let recipientDeviceSourceHintTriageLineBodyText {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Triage preview (line vs body):")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(recipientDeviceSourceHintDiffHintText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(recipientDeviceSourceHintUsageNoteText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text("line: \(recipientDeviceSourceHintTriageLineText)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)

                                Text("body: \(recipientDeviceSourceHintTriageLineBodyText)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)

                                if let recipientDeviceSourceHintTriageKitCompactPreviewText {
                                    Text("Triage-kit preview: \(recipientDeviceSourceHintTriageKitCompactPreviewText)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)

                                    if let recipientDeviceSourceHintTriageKitPreviewDeltaHintText {
                                        Text(recipientDeviceSourceHintTriageKitPreviewDeltaHintText)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    if let recipientDeviceSourceHintTriagePreviewPairLiteText {
                                        Text("Preview-pair-lite (scan before copy):")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)

                                        Text(recipientDeviceSourceHintTriagePreviewPairLiteText)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        if let recipientDeviceReapplyGuidanceHintText {
                            Text(recipientDeviceReapplyGuidanceHintText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if let lastRecipientDevicesRateLimitSkipAt {
                            let skipElapsed = Date().timeIntervalSince(lastRecipientDevicesRateLimitSkipAt)
                            if skipElapsed <= 1.2 {
                                Text("Auto reload recipient devices vừa bị giới hạn tần suất (<1s). Chờ một nhịp ngắn hoặc bấm `Reload recipient devices`.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        let hasHiddenAutoReloadTimestampNote: Bool = {
                            guard let lastRecipientDevicesAutoReloadAt else {
                                return false
                            }
                            return Date().timeIntervalSince(lastRecipientDevicesAutoReloadAt) > 20
                        }()

                        if let lastRecipientDevicesAutoReloadAt {
                            let autoReloadElapsed = Date().timeIntervalSince(lastRecipientDevicesAutoReloadAt)
                            if autoReloadElapsed <= 20 {
                                Text("Auto recipient-device reload: \(Int(autoReloadElapsed))s ago")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        let hasHiddenSkipTimestampNote: Bool = {
                            guard let lastRecipientDevicesRateLimitSkipAt else {
                                return false
                            }
                            return Date().timeIntervalSince(lastRecipientDevicesRateLimitSkipAt) > 20
                        }()

                        if let lastRecipientDevicesRateLimitSkipAt {
                            let skipElapsedSeconds = Date().timeIntervalSince(lastRecipientDevicesRateLimitSkipAt)
                            if skipElapsedSeconds <= 20 {
                                Text("Rate-limit skip event: \(Int(skipElapsedSeconds))s ago")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if hasHiddenAutoReloadTimestampNote || hasHiddenSkipTimestampNote {
                            Text("Timestamp debug hints tự ẩn sau ~20s để giữ UI gọn; trigger event mới để hiện lại.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        TextField("Wrapped message key blob", text: $wrappedMessageKeyBlobDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                lastRecipientDevicesRateLimitSkipAt = nil
                                await loadRecipientDevices()
                                lastRecipientDevicesRateLimitSkipAt = nil
                            }
                        } label: {
                            Text("Reload recipient devices")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button {
                            if let firstRecipientDeviceOptionID {
                                recipientDeviceIDDraft = firstRecipientDeviceOptionID
                            }
                        } label: {
                            Text(applyFirstRecipientDeviceActionTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            !canApplyFirstRecipientDeviceOption
                        )

                        if let firstRecipientDeviceOptionID,
                           canApplyFirstRecipientDeviceOption {
                            Text("Action target: first valid option \(firstRecipientDeviceOptionID)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            Text("Short target ID: \(shortUserID(firstRecipientDeviceOptionID))")
                                .font(.caption2.monospaced())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            recipientDeviceIDDraft = ""
                        } label: {
                            Text("Clear recipient device UUID")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button {
                            Task {
                                await createMessageDeviceKey()
                            }
                        } label: {
                            Text(isCreatingDeviceKey ? "Creating device key..." : "Create device key")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isLoadingRecipientDevices ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isDeletingMessage ||
                            isCreatingDeviceKey ||
                            conversationSummary == nil ||
                            (resolvedDeviceKeyTargetMessageID?.isEmpty ?? true) ||
                            recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            wrappedMessageKeyBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Update read cursor")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if !conversationMembers.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick member presets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(conversationMembers) { member in
                                    Button {
                                        readCursorTargetUserIDDraft = member.userID
                                    } label: {
                                        HStack {
                                            Text(member.userID)
                                                .font(.caption.monospaced())
                                                .lineLimit(1)
                                            Spacer()
                                            if member.userID == resolvedReadCursorTargetUserID {
                                                Text("selected")
                                                    .font(.caption2)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        TextField("Member user UUID (defaults to User A)", text: $readCursorTargetUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !messageRows.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick message presets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(messageRows.suffix(3).reversed()) { message in
                                    Button {
                                        readCursorTargetMessageIDDraft = message.id
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(message.id)
                                                .font(.caption.monospaced())
                                                .lineLimit(1)
                                            Text(message.payloadText)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        TextField("Last-read message UUID (optional, defaults to newest loaded)", text: $readCursorTargetMessageIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Read-status focus user UUID (optional, defaults to User A)", text: $readStatusFocusUserIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let cursorFormSyncHintText {
                            Text(cursorFormSyncHintText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.blue)
                        }

                        Button {
                            Task {
                                await updateReadCursor()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Updating read cursor..." : "Update read cursor")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadCursorTargetUserID?.isEmpty ?? true) ||
                            (resolvedReadCursorTargetMessageID?.isEmpty ?? true)
                        )

                        Button {
                            Task {
                                await markLatestMessageAsReadForFocusUser()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Marking latest as read..." : "Mark latest message as read (focus user)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadStatusFocusUserID?.isEmpty ?? true) ||
                            (latestLoadedMessageID?.isEmpty ?? true)
                        )

                        Button {
                            applyFocusUserAndFirstUnreadCandidatePreset()
                        } label: {
                            Text("Use focus user + first unread candidate")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadStatusFocusUserID?.isEmpty ?? true)
                        )

                        Button {
                            Task {
                                await jumpToFirstUnreadCandidateForFocusUser()
                            }
                        } label: {
                            Text(isUpdatingReadCursor ? "Jumping to first unread..." : "Jump focus user to first unread candidate")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isDeletingMessage ||
                            isUpdatingReadCursor ||
                            conversationSummary == nil ||
                            (resolvedReadStatusFocusUserID?.isEmpty ?? true)
                        )

                        if let firstUnreadMessageIDForFocusUser {
                            Text("first_unread_candidate_message_id: \(firstUnreadMessageIDForFocusUser)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        } else if conversationSummary != nil, (resolvedReadStatusFocusUserID?.isEmpty ?? true) == false {
                            Text("first_unread_guard=already_at_latest_or_no_unread")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delete message (soft-delete)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Message UUID to delete (optional, defaults to newest loaded)", text: $messageToDeleteIDDraft)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                            .padding(12)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await deleteMessage()
                            }
                        } label: {
                            Text(isDeletingMessage ? "Deleting message..." : "Delete message")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isLoading ||
                            isSendingMessage ||
                            isCreatingAttachment ||
                            isCreatingDeviceKey ||
                            isUpdatingReadCursor ||
                            isDeletingMessage ||
                            conversationSummary == nil ||
                            (resolvedMessageToDeleteID?.isEmpty ?? true)
                        )
                    }

                    if let currentSessionUserID {
                        Text("Current session user_id: \(currentSessionUserID)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)

                        Button {
                            applyCurrentSessionUserAsReadStatusFocusUser()
                        } label: {
                            Text("Use current session user as read focus user")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading || conversationSummary == nil)

                        Button {
                            applyCurrentSessionUserAsReadCursorTargetAndFocusUser()
                        } label: {
                            Text("Use current session user as read-cursor target + read focus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading || conversationSummary == nil)
                    }

                    if let sendStatusHint {
                        Text("Status hint: \(sendStatusHint)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let fetchError {
                        Text("Fetch error: \(fetchError)")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if let conversationSummary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conversation resolved")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("conversation_id: \(conversationSummary.id)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text("type: \(conversationSummary.conversationType) · members: \(conversationSummary.memberUserIDs.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Loaded messages: \(messageRows.count)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Quick copy conversation: \(conversationQuickCopySummary)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy send result: \(lastSendQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick send result") {
                            copyLastSendQuickCopyResult()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy read cursor: \(readCursorQuickCopySummary)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick read cursor") {
                            copyReadCursorQuickCopySummary()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy read-cursor apply result: \(lastReadCursorApplyQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick read-cursor apply result") {
                            copyReadCursorApplyQuickCopySummary()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy read-cursor triage line: \(lastReadCursorTriageQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick read-cursor triage line") {
                            copyReadCursorTriageQuickCopySummary()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy first-unread jump result: \(lastFirstUnreadJumpQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick first-unread jump result") {
                            copyFirstUnreadJumpQuickCopySummary()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text("Quick copy first-unread guard state: \(lastFirstUnreadGuardQuickCopy)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Copy quick first-unread guard state") {
                            copyFirstUnreadGuardQuickCopySummary()
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("Attachment target message_id: \(resolvedAttachmentTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Device-key target message_id: \(resolvedDeviceKeyTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-cursor target user_id: \(resolvedReadCursorTargetUserID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-cursor target message_id: \(resolvedReadCursorTargetMessageID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Read-status focus user_id: \(resolvedReadStatusFocusUserID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Delete target message_id: \(resolvedMessageToDeleteID ?? "(not resolved)")")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    Toggle(isOn: $autoRefreshEnabled) {
                        Text("Auto refresh every 3s")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .toggleStyle(.switch)
                    .disabled(conversationSummary == nil || isLoading)

                    if autoRefreshEnabled {
                        Text("Auto refresh đang bật: inbox sẽ tự reload mỗi 3 giây khi idle.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Member read-cursor summary")
                        .font(.headline)

                    if conversationMembers.isEmpty {
                        Text("No conversation members loaded yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(conversationMembers) { member in
                            let cursorMessageID = member.lastReadMessageID
                            let cursorMessage = messageRows.first(where: { $0.id == cursorMessageID })
                            let isFocusUser = member.userID == resolvedReadStatusFocusUserID
                            let isAtLatest = cursorMessageID != nil && cursorMessageID == latestLoadedMessageID
                            let unreadBehindCount = unreadMessageCountBehindCursor(lastReadMessageID: cursorMessageID)
                            let cursorOrderHint = cursorOrderHintText(lastReadMessageID: cursorMessageID)

                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    readStatusFocusUserIDDraft = member.userID
                                    readCursorTargetUserIDDraft = member.userID

                                    if let cursorMessageID {
                                        readCursorTargetMessageIDDraft = cursorMessageID
                                    }

                                    if let cursorMessageID {
                                        lastCursorFormSyncSummary = "cursor_form_sync: user=\(member.userID) message=\(cursorMessageID)"
                                    } else {
                                        lastCursorFormSyncSummary = "cursor_form_sync: user=\(member.userID) message=(none)"
                                    }
                                    lastCursorFormSyncAt = Date()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("user_id: \(member.userID)")
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)

                                        Spacer()

                                        Text(isFocusUser ? "focus+cursor_form" : "set_focus+cursor_form")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(isFocusUser ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Text("last_read_message_id: \(cursorMessageID ?? "(none)")")
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)

                                Button {
                                    applyConversationMemberAsReadFocusUser(member.userID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member as read focus user")
                                            .font(.caption)

                                        Spacer()

                                        Text(resolvedReadStatusFocusUserID == member.userID ? "focus_selected" : "set_focus")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(resolvedReadStatusFocusUserID == member.userID ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    applyConversationMemberAsReadCursorTargetUser(member.userID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member as read-cursor target user")
                                            .font(.caption)

                                        Spacer()

                                        Text(resolvedReadCursorTargetUserID == member.userID ? "target_selected" : "set_target")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(resolvedReadCursorTargetUserID == member.userID ? .green : .secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    applyConversationMemberAsReadCursorTargetAndFocusUser(member.userID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member as read-cursor target + read focus")
                                            .font(.caption)

                                        Spacer()

                                        let isSelectedForBoth = resolvedReadCursorTargetUserID == member.userID && resolvedReadStatusFocusUserID == member.userID
                                        Text(isSelectedForBoth ? "target+focus_selected" : "set_target+focus")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(isSelectedForBoth ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    applyConversationMemberCursorMessageAsReadCursorTargetMessage(cursorMessageID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member cursor as message target")
                                            .font(.caption)

                                        Spacer()

                                        if let cursorMessageID {
                                            Text(resolvedReadCursorTargetMessageID == cursorMessageID ? "message_target_selected" : "set_message_target")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(resolvedReadCursorTargetMessageID == cursorMessageID ? .green : .secondary)
                                        } else {
                                            Text("cursor_missing")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled(cursorMessageID == nil)

                                Button {
                                    applyConversationMemberCursorContextForReadCursor(memberUserID: member.userID, lastReadMessageID: cursorMessageID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member cursor context (target + message)")
                                            .font(.caption)

                                        Spacer()

                                        if let cursorMessageID {
                                            let isContextSelected = resolvedReadCursorTargetUserID == member.userID && resolvedReadCursorTargetMessageID == cursorMessageID
                                            Text(isContextSelected ? "context_selected" : "set_context")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(isContextSelected ? .blue : .secondary)
                                        } else {
                                            Text("cursor_missing")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled(cursorMessageID == nil)

                                Button {
                                    applyConversationMemberCursorContextAndFocusUser(memberUserID: member.userID, lastReadMessageID: cursorMessageID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member cursor context + focus")
                                            .font(.caption)

                                        Spacer()

                                        if let cursorMessageID {
                                            let isContextFocusSelected = resolvedReadCursorTargetUserID == member.userID && resolvedReadCursorTargetMessageID == cursorMessageID && resolvedReadStatusFocusUserID == member.userID
                                            Text(isContextFocusSelected ? "context+focus_selected" : "set_context+focus")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(isContextFocusSelected ? .blue : .secondary)
                                        } else {
                                            Text("cursor_missing")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled(cursorMessageID == nil)

                                Button {
                                    applyConversationMemberCursorContextFocusAndMarkRead(memberUserID: member.userID, lastReadMessageID: cursorMessageID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member cursor context + focus + mark read")
                                            .font(.caption)

                                        Spacer()

                                        if isUpdatingReadCursor {
                                            Text("updating")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("apply_and_mark")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled(cursorMessageID == nil || isUpdatingReadCursor)

                                Button {
                                    applyConversationMemberLatestLoadedFocusAndMarkRead(memberUserID: member.userID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member focus + latest loaded + mark read")
                                            .font(.caption)

                                        Spacer()

                                        if isUpdatingReadCursor {
                                            Text("updating")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("latest+focus")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled((latestLoadedMessageID?.isEmpty ?? true) || isUpdatingReadCursor)

                                Button {
                                    applyConversationMemberFirstUnreadFocusAndMarkRead(memberUserID: member.userID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Use member focus + first unread + mark read")
                                            .font(.caption)

                                        Spacer()

                                        if isUpdatingReadCursor {
                                            Text("updating")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("first_unread+focus")
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled((firstUnreadMessageIDForFocusUser?.isEmpty ?? true) || isUpdatingReadCursor)

                                if cursorMessageID == nil {
                                    Text("cursor_message_target: unavailable")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }

                                if let cursorMessage {
                                    Text("cursor_payload: \(cursorMessage.payloadText)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Text("cursor_state: \(isAtLatest ? "at_latest" : "behind_or_unknown")")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(isAtLatest ? .green : .orange)

                                Text("cursor_order_hint: \(cursorOrderHint)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)

                                Text("unread_behind_cursor: \(unreadBehindCount)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(unreadBehindCount == 0 ? .green : .orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Messages")
                        .font(.headline)

                    if messageRows.isEmpty {
                        Text("No messages loaded for this direct thread yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(messageRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("sender_user_id: \(row.senderUserID)")
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(row.payloadText)
                                    .font(.footnote)

                                let attachments = attachmentMap[row.id] ?? []
                                Text("attachment_count: \(attachments.count)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let firstAttachment = attachments.first {
                                    Text("first_attachment: \(firstAttachment.attachmentType) · \(firstAttachment.storageKey ?? "(no storage key)")")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                let deviceKeys = deviceKeyMap[row.id] ?? []
                                Text("device_key_count: \(deviceKeys.count)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let firstDeviceKey = deviceKeys.first {
                                    Text("first_device_key: recipient_user=\(firstDeviceKey.recipientUserID) · recipient_device=\(firstDeviceKey.recipientDeviceID)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                let readCursorOwners = conversationMembers
                                    .filter { $0.lastReadMessageID == row.id }
                                    .map(\.userID)

                                if !readCursorOwners.isEmpty {
                                    Text("last_read_by: \(readCursorOwners.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                if row.id == resolvedReadStatusMessageID,
                                   let focusUserID = resolvedReadStatusFocusUserID {
                                    let focusReadState = readCursorOwners.contains(focusUserID) ? "read" : "unread"
                                    let focusReadColor: Color = focusReadState == "read" ? .green : .orange

                                    Text("read_status(\(focusUserID)): \(focusReadState)")
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(focusReadColor)
                                }

                                Text("message_id: \(row.id)")
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
        .navigationTitle("Inbox")
        .onAppear {
            prefillUserAFromCurrentSessionIfNeeded()
        }
        .onDisappear {
            recipientDevicesAutoReloadTask?.cancel()
            recipientDevicesAutoReloadTask = nil
            lastRecipientDevicesAutoReloadAt = nil
            lastRecipientDevicesRateLimitSkipAt = nil
        }
        .task(id: autoRefreshEnabled) {
            guard autoRefreshEnabled else {
                return
            }

            while autoRefreshEnabled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)

                if !autoRefreshEnabled {
                    break
                }

                if conversationSummary == nil || isLoading || isMutatingInbox {
                    continue
                }

                await loadInboxThread(silent: true)
            }
        }
    }

    private var currentSessionUserID: String? {
        if case let .authenticated(userSession) = sessionStore.authState {
            return userSession.userID
        }
        return nil
    }

    private var conversationQuickCopySummary: String {
        let userA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let userB = userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryUserA = userA.isEmpty ? "(empty)" : userA
        let summaryUserB = userB.isEmpty ? "(empty)" : userB
        let summaryMessageCount = messageRows.count
        let summaryLastMessageID = messageRows.last?.id ?? "(none)"

        return "user_a=\(summaryUserA) | user_b=\(summaryUserB) | message_count=\(summaryMessageCount) | last_message_id=\(summaryLastMessageID)"
    }

    private var resolvedAttachmentTargetMessageID: String? {
        let manualMessageID = attachmentTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedDeviceKeyTargetMessageID: String? {
        let manualMessageID = deviceKeyTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedReadCursorTargetUserID: String? {
        let manualUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualUserID.isEmpty {
            return manualUserID
        }

        let fallbackUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallbackUserA.isEmpty {
            return fallbackUserA
        }

        return nil
    }

    private var resolvedReadCursorTargetMessageID: String? {
        let manualMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedMessageToDeleteID: String? {
        let manualMessageID = messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualMessageID.isEmpty {
            return manualMessageID
        }

        return messageRows.last?.id
    }

    private var resolvedReadStatusFocusUserID: String? {
        let manualUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manualUserID.isEmpty {
            return manualUserID
        }

        let fallbackUserA = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallbackUserA.isEmpty {
            return fallbackUserA
        }

        return nil
    }

    private var firstRecipientDeviceOptionID: String? {
        recipientDeviceOptions.first?.id
    }

    private var canApplyFirstRecipientDeviceOption: Bool {
        guard let firstRecipientDeviceOptionID else {
            return false
        }

        return recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) != firstRecipientDeviceOptionID
    }

    private var applyFirstRecipientDeviceActionTitle: String {
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRecipientDeviceID.isEmpty {
            return "Use first valid recipient device"
        }

        return "Re-apply first valid recipient device"
    }

    private var recipientDeviceSelectionSourceHintText: String? {
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientDeviceID.isEmpty else {
            if let firstRecipientDeviceOptionID {
                return "Recipient device source: chưa chọn (first option: \(firstRecipientDeviceOptionID), short-id: \(shortUserID(firstRecipientDeviceOptionID)))."
            }
            return "Recipient device source: chưa chọn (manual input hoặc load devices để có options; short-id chưa khả dụng)."
        }

        if let firstRecipientDeviceOptionID,
           trimmedRecipientDeviceID == firstRecipientDeviceOptionID {
            return "Recipient device source: current options (in-sync, same as first option: \(shortUserID(firstRecipientDeviceOptionID)))."
        }

        if recipientDeviceOptions.contains(where: { $0.id == trimmedRecipientDeviceID }) {
            return "Recipient device source: current options (in-sync, short-id: \(shortUserID(trimmedRecipientDeviceID)))."
        }

        return "Recipient device source: manual UUID/out-of-options (short-id: \(shortUserID(trimmedRecipientDeviceID)))."
    }

    private var recipientDeviceReapplyGuidanceHintText: String? {
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientDeviceID.isEmpty else {
            if recipientDeviceOptions.isEmpty {
                return "Chưa có recipient-device options — load devices trước khi cân nhắc thao tác re-apply."
            }
            return nil
        }

        guard let firstRecipientDeviceOptionID else {
            if recipientDeviceOptions.isEmpty {
                return "Danh sách recipient-device options hiện trống — không có target để re-apply."
            }
            return nil
        }

        if trimmedRecipientDeviceID == firstRecipientDeviceOptionID {
            return "Selection đã trùng first option — có thể bỏ qua thao tác re-apply."
        }

        return nil
    }

    private var recipientDeviceSourceHintCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintCopyAt,
              let lastRecipientDeviceSourceHintCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied source hint (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintCopyText, limit: 88))"
    }

    private var recipientDeviceSourceHintBranchKey: String? {
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientDeviceID.isEmpty else {
            if firstRecipientDeviceOptionID != nil {
                return "empty-first"
            }
            return "empty-none"
        }

        if let firstRecipientDeviceOptionID,
           trimmedRecipientDeviceID == firstRecipientDeviceOptionID {
            return "sync-first"
        }

        if recipientDeviceOptions.contains(where: { $0.id == trimmedRecipientDeviceID }) {
            return "sync-nonfirst"
        }

        return "manual-oob"
    }

    private var recipientDeviceSourceHintReportPayloadText: String? {
        guard let sourceHintText = recipientDeviceSelectionSourceHintText,
              let branchKey = recipientDeviceSourceHintBranchKey else {
            return nil
        }

        let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipientUserShort = shortUserID(trimmedRecipientUserID)
        let recipientDeviceShort = shortUserID(trimmedRecipientDeviceID)
        let trimmedSourceHintText = sourceHintText.trimmingCharacters(in: .whitespacesAndNewlines)
        let timestamp = Self.recipientSourceHintReportTimestampFormatter.string(from: Date())

        return "[inbox-source-hint] ts=\(timestamp) branch=\(branchKey) recipient_user=\(recipientUserShort) recipient_device=\(recipientDeviceShort) hint=\(trimmedSourceHintText)"
    }

    private var recipientDeviceSourceHintBranchKeyCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchKeyCopyAt,
              let lastRecipientDeviceSourceHintBranchKeyCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchKeyCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch key (\(Int(elapsed))s ago): \(lastRecipientDeviceSourceHintBranchKeyCopyText)"
    }

    private var recipientDeviceSourceHintMatrixSnapshotText: String? {
        guard let branchKey = recipientDeviceSourceHintBranchKey else {
            return nil
        }

        let matrixLine = "Source-hint verify matrix: empty+first→first option ... short-id; empty+no-options→short-id chưa khả dụng; in-sync+first→same as first option; in-sync+non-first→in-sync, short-id; manual/out-of-options→manual UUID/out-of-options."
        let legendLine = "Branch-key legend: empty-first→empty + có first option; empty-none→empty + chưa có option; sync-first→in-sync + first option; sync-nonfirst→in-sync + non-first option; manual-oob→manual/out-of-options."

        return "[inbox-source-hint-matrix]\nbranch=\(branchKey)\n\(matrixLine)\n\(legendLine)"
    }

    private var recipientDeviceSourceHintDiffHintText: String {
        "Diff hint: line = body + prefix tag `[inbox-source-hint-triage]`."
    }

    private var recipientDeviceSourceHintUsageNoteText: String {
        "Usage: triage line cho tagged log/search; triage body cho issue text gọn; diff hint cho onboarding/explanation nhanh."
    }

    private var recipientDeviceSourceHintTriageLineBodyText: String? {
        guard let branchKey = recipientDeviceSourceHintBranchKey,
              let sourceHintText = recipientDeviceSelectionSourceHintText else {
            return nil
        }

        let guidanceText = recipientDeviceReapplyGuidanceHintText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(none)"
        let normalizedSourceHint = sourceHintText.trimmingCharacters(in: .whitespacesAndNewlines)

        return "branch=\(branchKey) selection=\(normalizedSourceHint) guidance=\(guidanceText)"
    }

    private var recipientDeviceSourceHintTriageLineText: String? {
        guard let triageLineBodyText = recipientDeviceSourceHintTriageLineBodyText else {
            return nil
        }

        return "[inbox-source-hint-triage] \(triageLineBodyText)"
    }

    private var recipientDeviceSourceHintTriageKitText: String? {
        guard let triageLineText = recipientDeviceSourceHintTriageLineText,
              let triageBodyText = recipientDeviceSourceHintTriageLineBodyText else {
            return nil
        }

        return """
[inbox-source-hint-triage-kit]
line=\(triageLineText)
body=\(triageBodyText)
diff=\(recipientDeviceSourceHintDiffHintText)
usage=\(recipientDeviceSourceHintUsageNoteText)
"""
    }

    private var recipientDeviceSourceHintTriageKitCompactPreviewText: String? {
        guard let triageLineText = recipientDeviceSourceHintTriageLineText,
              let triageBodyText = recipientDeviceSourceHintTriageLineBodyText,
              let branchKey = recipientDeviceSourceHintBranchKey else {
            return nil
        }

        return "branch=\(branchKey) | line=\(shortCaption(triageLineText, limit: 56)) | body=\(shortCaption(triageBodyText, limit: 56))"
    }

    private var recipientDeviceSourceHintTriageKitPreviewDeltaHintText: String? {
        guard recipientDeviceSourceHintTriageKitCompactPreviewText != nil,
              recipientDeviceSourceHintTriageKitText != nil else {
            return nil
        }

        return "Preview delta: compact preview chỉ giữ `branch + line/body rút gọn`; full triage-kit vẫn chứa đủ 4 fields `line/body/diff/usage`."
    }

    private var recipientDeviceSourceHintTriagePreviewPairText: String? {
        guard let compactPreviewText = recipientDeviceSourceHintTriageKitCompactPreviewText,
              let previewDeltaHintText = recipientDeviceSourceHintTriageKitPreviewDeltaHintText,
              let useWhenText = recipientDeviceSourceHintTriagePreviewPairUseWhenText else {
            return nil
        }

        return """
[inbox-source-hint-triage-preview-pair]
use_when=\(useWhenText)
preview=
\(compactPreviewText)
delta=
\(previewDeltaHintText)
"""
    }

    private var recipientDeviceSourceHintTriagePreviewPairUseWhenText: String? {
        guard recipientDeviceSourceHintTriageKitCompactPreviewText != nil,
              recipientDeviceSourceHintTriageKitPreviewDeltaHintText != nil else {
            return nil
        }

        return "need one short block that still explains compact-vs-full triage context"
    }

    private var recipientDeviceSourceHintTriagePreviewPairLiteText: String? {
        guard let useWhenText = recipientDeviceSourceHintTriagePreviewPairUseWhenText,
              let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return nil
        }

        return """
[inbox-source-hint-triage-preview-pair-lite]
use_when=\(useWhenText)
\(previewLineText)
"""
    }

    private var recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText: String? {
        guard let compactPreviewText = recipientDeviceSourceHintTriageKitCompactPreviewText else {
            return nil
        }

        return "preview=\(compactPreviewText)"
    }

    private var recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText: String? {
        guard let useWhenText = recipientDeviceSourceHintTriagePreviewPairUseWhenText else {
            return nil
        }

        return "use_when=\(useWhenText)"
    }

    private var recipientDeviceSourceHintTriagePreviewPairLiteTagHeaderText: String? {
        guard recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText != nil,
              recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText != nil else {
            return nil
        }

        return "[inbox-source-hint-triage-preview-pair-lite]"
    }

    private var recipientDeviceSourceHintTriagePreviewPairLiteCondensedLineText: String? {
        guard let useWhenLineText = recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText,
              let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return nil
        }

        return "\(useWhenLineText) | \(previewLineText)"
    }

    private var recipientDeviceSourceHintBranchPreviewTokenText: String? {
        guard let branchKey = recipientDeviceSourceHintBranchKey,
              let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return nil
        }

        return "branch=\(branchKey) | \(previewLineText)"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewSummaryText: String? {
        guard let branchKey = recipientDeviceSourceHintBranchKey,
              let useWhenLineText = recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText,
              let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return nil
        }

        return "branch=\(branchKey) | \(useWhenLineText) | \(previewLineText)"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockText: String? {
        guard let summaryLineText = recipientDeviceSourceHintBranchUseWhenPreviewSummaryText,
              let tagHeaderText = recipientDeviceSourceHintBranchSummaryTagHeaderText else {
            return nil
        }

        return "\(tagHeaderText)\n\(summaryLineText)"
    }

    private var recipientDeviceSourceHintBranchSummaryTagHeaderText: String? {
        guard recipientDeviceSourceHintBranchUseWhenPreviewSummaryText != nil else {
            return nil
        }

        return "[inbox-source-hint-triage-branch-summary]"
    }

    private var recipientDeviceSourceHintBranchSummaryCompactBundleText: String? {
        guard let tagHeaderText = recipientDeviceSourceHintBranchSummaryTagHeaderText,
              let summaryLineText = recipientDeviceSourceHintBranchUseWhenPreviewSummaryText,
              let branchPreviewTokenText = recipientDeviceSourceHintBranchPreviewTokenText else {
            return nil
        }

        return "\(tagHeaderText)\n\(summaryLineText)\n\(branchPreviewTokenText)"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewLiteText: String? {
        guard let useWhenLineText = recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText,
              let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return nil
        }

        return "\(useWhenLineText) | \(previewLineText)"
    }

    private var recipientDeviceSourceHintReportPayloadCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintReportPayloadCopyAt,
              let lastRecipientDeviceSourceHintReportPayloadCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintReportPayloadCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied report payload (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintReportPayloadCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintMatrixSnapshotCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintMatrixSnapshotCopyAt,
              let lastRecipientDeviceSourceHintMatrixSnapshotCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintMatrixSnapshotCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied matrix snapshot (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintMatrixSnapshotCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintTriageLineCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintTriageLineCopyAt,
              let lastRecipientDeviceSourceHintTriageLineCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintTriageLineCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied triage line (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintTriageLineCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintTriageLineBodyCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintTriageLineBodyCopyAt,
              let lastRecipientDeviceSourceHintTriageLineBodyCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintTriageLineBodyCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied triage body (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintTriageLineBodyCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintDiffHintCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintDiffHintCopyAt,
              let lastRecipientDeviceSourceHintDiffHintCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintDiffHintCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied diff hint (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintDiffHintCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintUsageNoteCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintUsageNoteCopyAt,
              let lastRecipientDeviceSourceHintUsageNoteCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintUsageNoteCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied usage note (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintUsageNoteCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintTriageKitCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintTriageKitCopyAt,
              let lastRecipientDeviceSourceHintTriageKitCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintTriageKitCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied triage kit (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintTriageKitCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintTriageKitPreviewCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintTriageKitPreviewCopyAt,
              let lastRecipientDeviceSourceHintTriageKitPreviewCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintTriageKitPreviewCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied triage-kit preview (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintTriageKitPreviewCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewDeltaCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewDeltaCopyAt,
              let lastRecipientDeviceSourceHintPreviewDeltaCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewDeltaCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview delta (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewDeltaCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintTriagePreviewPairCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintTriagePreviewPairCopyAt,
              let lastRecipientDeviceSourceHintTriagePreviewPairCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintTriagePreviewPairCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview pair (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintTriagePreviewPairCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairUseWhenCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairUseWhenCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairUseWhenCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairUseWhenCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair use-when (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairUseWhenCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairLiteCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairLiteCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairLiteCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairLiteCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair-lite (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairLiteCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairLitePreviewLineCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair-lite preview (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairLiteTagHeaderCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair-lite tag (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairLiteUseWhenLineCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair-lite use-when (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintPreviewPairLiteCondensedLineCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyAt,
              let lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied preview-pair-lite condensed (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchPreviewTokenCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchPreviewTokenCopyAt,
              let lastRecipientDeviceSourceHintBranchPreviewTokenCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchPreviewTokenCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-preview token (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchPreviewTokenCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewSummaryCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyAt,
              let lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-use-when-preview (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyAt,
              let lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-use-when-preview tagged (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchSummaryTagHeaderCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyAt,
              let lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-summary tag (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchSummaryCompactBundleCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyAt,
              let lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-summary compact bundle (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyText, limit: 96))"
    }

    private var recipientDeviceSourceHintBranchUseWhenPreviewLiteCopiedFeedbackText: String? {
        guard let lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyAt,
              let lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyText else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyAt)
        guard elapsed <= 12 else {
            return nil
        }

        return "Copied branch-use-when-preview-lite (\(Int(elapsed))s ago): \(shortCaption(lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyText, limit: 96))"
    }

    private var resolvedReadStatusMessageID: String? {
        if let targetMessageID = resolvedReadCursorTargetMessageID,
           !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return targetMessageID
        }

        return messageRows.last?.id
    }

    private var readCursorQuickCopySummary: String {
        let focusUserID = resolvedReadStatusFocusUserID ?? "(none)"
        let resolvedMessageID = resolvedReadStatusMessageID ?? "(none)"

        let readState: String
        if let focusUserID = resolvedReadStatusFocusUserID,
           let resolvedMessageID = resolvedReadStatusMessageID,
           !focusUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !resolvedMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let isRead = conversationMembers.contains { member in
                member.userID == focusUserID && member.lastReadMessageID == resolvedMessageID
            }
            readState = isRead ? "read" : "unread"
        } else {
            readState = "unknown"
        }

        return "focus_user=\(focusUserID) | resolved_message=\(resolvedMessageID) | read_state=\(readState)"
    }

    private var latestLoadedMessageID: String? {
        messageRows.last?.id
    }

    private var firstUnreadMessageIDForFocusUser: String? {
        guard let focusUserID = resolvedReadStatusFocusUserID,
              !focusUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let focusMember = conversationMembers.first(where: { $0.userID == focusUserID })
        let cursorMessageID = focusMember?.lastReadMessageID

        guard !messageRows.isEmpty else {
            return nil
        }

        guard let cursorMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == cursorMessageID }) else {
            return messageRows.first?.id
        }

        let unreadIndex = cursorIndex + 1
        guard unreadIndex < messageRows.count else {
            return nil
        }

        return messageRows[unreadIndex].id
    }

    private func unreadMessageCountBehindCursor(lastReadMessageID: String?) -> Int {
        guard let lastReadMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == lastReadMessageID }) else {
            return messageRows.count
        }

        let trailingCount = messageRows.count - cursorIndex - 1
        return max(trailingCount, 0)
    }

    private func cursorOrderHintText(lastReadMessageID: String?) -> String {
        guard let lastReadMessageID,
              let cursorIndex = messageRows.firstIndex(where: { $0.id == lastReadMessageID }) else {
            return "unknown"
        }

        return "index \(cursorIndex + 1)/\(messageRows.count)"
    }

    private func shortUserID(_ userID: String?) -> String {
        guard let trimmedUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedUserID.isEmpty else {
            return "unknown"
        }

        if trimmedUserID.count <= 8 {
            return trimmedUserID
        }

        let prefix = trimmedUserID.prefix(4)
        let suffix = trimmedUserID.suffix(4)
        return "\(prefix)…\(suffix)"
    }

    private func shortCaption(_ text: String, limit: Int) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count > limit else {
            return trimmedText
        }

        let headCount = max(limit - 1, 0)
        let head = trimmedText.prefix(headCount)
        return "\(head)…"
    }

    private func copyLastSendQuickCopyResult() {
        let normalizedText = lastSendQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "send_result_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied send-result quick copy to clipboard (\(normalizedText))."
    }

    private func copyReadCursorQuickCopySummary() {
        let normalizedText = readCursorQuickCopySummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "read_cursor_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied read-cursor quick copy to clipboard (\(normalizedText))."
    }

    private func copyReadCursorApplyQuickCopySummary() {
        let normalizedText = lastReadCursorApplyQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "read_cursor_apply_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied read-cursor apply quick copy to clipboard (\(normalizedText))."
    }

    private func copyReadCursorTriageQuickCopySummary() {
        let normalizedText = lastReadCursorTriageQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "read_cursor_triage_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied read-cursor triage quick copy to clipboard (\(normalizedText))."
    }

    private func copyFirstUnreadJumpQuickCopySummary() {
        let normalizedText = lastFirstUnreadJumpQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "first_unread_jump_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied first-unread jump quick copy to clipboard (\(normalizedText))."
    }

    private func copyFirstUnreadGuardQuickCopySummary() {
        let normalizedText = lastFirstUnreadGuardQuickCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            sendStatusHint = "first_unread_guard_quick_copy_empty"
            return
        }

        writeToClipboard(normalizedText)
        sendStatusHint = "Copied first-unread guard quick copy to clipboard (\(normalizedText))."
    }

    private func copyRecipientDeviceSourceHint(_ hintText: String) {
        let normalizedText = hintText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        writeToClipboard(normalizedText)

        lastRecipientDeviceSourceHintCopyText = normalizedText
        lastRecipientDeviceSourceHintCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchKey() {
        guard let branchKey = recipientDeviceSourceHintBranchKey else {
            return
        }

        let normalizedBranchKey = branchKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchKey.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchKey)

        lastRecipientDeviceSourceHintBranchKeyCopyText = normalizedBranchKey
        lastRecipientDeviceSourceHintBranchKeyCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintReportPayload() {
        guard let reportPayload = recipientDeviceSourceHintReportPayloadText else {
            return
        }

        let normalizedPayload = reportPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPayload.isEmpty else {
            return
        }

        writeToClipboard(normalizedPayload)

        lastRecipientDeviceSourceHintReportPayloadCopyText = normalizedPayload
        lastRecipientDeviceSourceHintReportPayloadCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintMatrixSnapshot() {
        guard let snapshotText = recipientDeviceSourceHintMatrixSnapshotText else {
            return
        }

        let normalizedSnapshotText = snapshotText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSnapshotText.isEmpty else {
            return
        }

        writeToClipboard(normalizedSnapshotText)

        lastRecipientDeviceSourceHintMatrixSnapshotCopyText = normalizedSnapshotText
        lastRecipientDeviceSourceHintMatrixSnapshotCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintTriageLine() {
        guard let triageLineText = recipientDeviceSourceHintTriageLineText else {
            return
        }

        let normalizedTriageLineText = triageLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTriageLineText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTriageLineText)

        lastRecipientDeviceSourceHintTriageLineCopyText = normalizedTriageLineText
        lastRecipientDeviceSourceHintTriageLineCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintTriageLineBody() {
        guard let triageLineBodyText = recipientDeviceSourceHintTriageLineBodyText else {
            return
        }

        let normalizedTriageLineBodyText = triageLineBodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTriageLineBodyText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTriageLineBodyText)

        lastRecipientDeviceSourceHintTriageLineBodyCopyText = normalizedTriageLineBodyText
        lastRecipientDeviceSourceHintTriageLineBodyCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintDiffHint() {
        let normalizedDiffHintText = recipientDeviceSourceHintDiffHintText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedDiffHintText.isEmpty else {
            return
        }

        writeToClipboard(normalizedDiffHintText)

        lastRecipientDeviceSourceHintDiffHintCopyText = normalizedDiffHintText
        lastRecipientDeviceSourceHintDiffHintCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintUsageNote() {
        let normalizedUsageNoteText = recipientDeviceSourceHintUsageNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUsageNoteText.isEmpty else {
            return
        }

        writeToClipboard(normalizedUsageNoteText)

        lastRecipientDeviceSourceHintUsageNoteCopyText = normalizedUsageNoteText
        lastRecipientDeviceSourceHintUsageNoteCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintTriageKit() {
        guard let triageKitText = recipientDeviceSourceHintTriageKitText else {
            return
        }

        let normalizedTriageKitText = triageKitText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTriageKitText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTriageKitText)

        lastRecipientDeviceSourceHintTriageKitCopyText = normalizedTriageKitText
        lastRecipientDeviceSourceHintTriageKitCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintTriageKitPreview() {
        guard let triageKitCompactPreviewText = recipientDeviceSourceHintTriageKitCompactPreviewText else {
            return
        }

        let normalizedTriageKitCompactPreviewText = triageKitCompactPreviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTriageKitCompactPreviewText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTriageKitCompactPreviewText)

        lastRecipientDeviceSourceHintTriageKitPreviewCopyText = normalizedTriageKitCompactPreviewText
        lastRecipientDeviceSourceHintTriageKitPreviewCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewDelta() {
        guard let previewDeltaHintText = recipientDeviceSourceHintTriageKitPreviewDeltaHintText else {
            return
        }

        let normalizedPreviewDeltaHintText = previewDeltaHintText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPreviewDeltaHintText.isEmpty else {
            return
        }

        writeToClipboard(normalizedPreviewDeltaHintText)

        lastRecipientDeviceSourceHintPreviewDeltaCopyText = normalizedPreviewDeltaHintText
        lastRecipientDeviceSourceHintPreviewDeltaCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintTriagePreviewPair() {
        guard let triagePreviewPairText = recipientDeviceSourceHintTriagePreviewPairText else {
            return
        }

        let normalizedTriagePreviewPairText = triagePreviewPairText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTriagePreviewPairText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTriagePreviewPairText)

        lastRecipientDeviceSourceHintTriagePreviewPairCopyText = normalizedTriagePreviewPairText
        lastRecipientDeviceSourceHintTriagePreviewPairCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairUseWhen() {
        guard let previewPairUseWhenText = recipientDeviceSourceHintTriagePreviewPairUseWhenText else {
            return
        }

        let normalizedPreviewPairUseWhenText = previewPairUseWhenText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPreviewPairUseWhenText.isEmpty else {
            return
        }

        writeToClipboard(normalizedPreviewPairUseWhenText)

        lastRecipientDeviceSourceHintPreviewPairUseWhenCopyText = normalizedPreviewPairUseWhenText
        lastRecipientDeviceSourceHintPreviewPairUseWhenCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairLite() {
        guard let previewPairLiteText = recipientDeviceSourceHintTriagePreviewPairLiteText else {
            return
        }

        let normalizedPreviewPairLiteText = previewPairLiteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPreviewPairLiteText.isEmpty else {
            return
        }

        writeToClipboard(normalizedPreviewPairLiteText)

        lastRecipientDeviceSourceHintPreviewPairLiteCopyText = normalizedPreviewPairLiteText
        lastRecipientDeviceSourceHintPreviewPairLiteCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairLitePreviewLine() {
        guard let previewLineText = recipientDeviceSourceHintTriagePreviewPairLitePreviewLineText else {
            return
        }

        let normalizedPreviewLineText = previewLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPreviewLineText.isEmpty else {
            return
        }

        writeToClipboard(normalizedPreviewLineText)

        lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyText = normalizedPreviewLineText
        lastRecipientDeviceSourceHintPreviewPairLitePreviewLineCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairLiteTagHeader() {
        guard let tagHeaderText = recipientDeviceSourceHintTriagePreviewPairLiteTagHeaderText else {
            return
        }

        let normalizedTagHeaderText = tagHeaderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTagHeaderText.isEmpty else {
            return
        }

        writeToClipboard(normalizedTagHeaderText)

        lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyText = normalizedTagHeaderText
        lastRecipientDeviceSourceHintPreviewPairLiteTagHeaderCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairLiteUseWhenLine() {
        guard let useWhenLineText = recipientDeviceSourceHintTriagePreviewPairLiteUseWhenLineText else {
            return
        }

        let normalizedUseWhenLineText = useWhenLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUseWhenLineText.isEmpty else {
            return
        }

        writeToClipboard(normalizedUseWhenLineText)

        lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyText = normalizedUseWhenLineText
        lastRecipientDeviceSourceHintPreviewPairLiteUseWhenLineCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintPreviewPairLiteCondensedLine() {
        guard let condensedLineText = recipientDeviceSourceHintTriagePreviewPairLiteCondensedLineText else {
            return
        }

        let normalizedCondensedLineText = condensedLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCondensedLineText.isEmpty else {
            return
        }

        writeToClipboard(normalizedCondensedLineText)

        lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyText = normalizedCondensedLineText
        lastRecipientDeviceSourceHintPreviewPairLiteCondensedLineCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchPreviewToken() {
        guard let branchPreviewTokenText = recipientDeviceSourceHintBranchPreviewTokenText else {
            return
        }

        let normalizedBranchPreviewTokenText = branchPreviewTokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchPreviewTokenText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchPreviewTokenText)

        lastRecipientDeviceSourceHintBranchPreviewTokenCopyText = normalizedBranchPreviewTokenText
        lastRecipientDeviceSourceHintBranchPreviewTokenCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchUseWhenPreviewSummary() {
        guard let branchUseWhenPreviewSummaryText = recipientDeviceSourceHintBranchUseWhenPreviewSummaryText else {
            return
        }

        let normalizedBranchUseWhenPreviewSummaryText = branchUseWhenPreviewSummaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchUseWhenPreviewSummaryText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchUseWhenPreviewSummaryText)

        lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyText = normalizedBranchUseWhenPreviewSummaryText
        lastRecipientDeviceSourceHintBranchUseWhenPreviewSummaryCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlock() {
        guard let branchUseWhenPreviewTaggedBlockText = recipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockText else {
            return
        }

        let normalizedBranchUseWhenPreviewTaggedBlockText = branchUseWhenPreviewTaggedBlockText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchUseWhenPreviewTaggedBlockText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchUseWhenPreviewTaggedBlockText)

        lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyText = normalizedBranchUseWhenPreviewTaggedBlockText
        lastRecipientDeviceSourceHintBranchUseWhenPreviewTaggedBlockCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchSummaryTagHeader() {
        guard let branchSummaryTagHeaderText = recipientDeviceSourceHintBranchSummaryTagHeaderText else {
            return
        }

        let normalizedBranchSummaryTagHeaderText = branchSummaryTagHeaderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchSummaryTagHeaderText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchSummaryTagHeaderText)

        lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyText = normalizedBranchSummaryTagHeaderText
        lastRecipientDeviceSourceHintBranchSummaryTagHeaderCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchSummaryCompactBundle() {
        guard let branchSummaryCompactBundleText = recipientDeviceSourceHintBranchSummaryCompactBundleText else {
            return
        }

        let normalizedBranchSummaryCompactBundleText = branchSummaryCompactBundleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchSummaryCompactBundleText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchSummaryCompactBundleText)

        lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyText = normalizedBranchSummaryCompactBundleText
        lastRecipientDeviceSourceHintBranchSummaryCompactBundleCopyAt = Date()
    }

    private func copyRecipientDeviceSourceHintBranchUseWhenPreviewLite() {
        guard let branchUseWhenPreviewLiteText = recipientDeviceSourceHintBranchUseWhenPreviewLiteText else {
            return
        }

        let normalizedBranchUseWhenPreviewLiteText = branchUseWhenPreviewLiteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBranchUseWhenPreviewLiteText.isEmpty else {
            return
        }

        writeToClipboard(normalizedBranchUseWhenPreviewLiteText)

        lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyText = normalizedBranchUseWhenPreviewLiteText
        lastRecipientDeviceSourceHintBranchUseWhenPreviewLiteCopyAt = Date()
    }

    private func writeToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }

    private func recipientResetReasonCaption(_ reason: String) -> String {
        switch reason {
        case "non_member_after_switch":
            return "non-member after switch"
        default:
            return reason
        }
    }

    private var isMutatingInbox: Bool {
        isSendingMessage ||
        isCreatingAttachment ||
        isCreatingDeviceKey ||
        isUpdatingReadCursor ||
        isDeletingMessage ||
        isLoadingRecipientDevices
    }

    private var cursorFormSyncHintText: String? {
        guard let lastCursorFormSyncSummary else {
            return nil
        }

        guard let lastCursorFormSyncAt else {
            return lastCursorFormSyncSummary
        }

        let elapsed = Date().timeIntervalSince(lastCursorFormSyncAt)
        guard elapsed <= 15 else {
            return nil
        }

        return "\(lastCursorFormSyncSummary) · \(Int(elapsed))s ago"
    }

    private var recipientDeviceContextResetHintText: String? {
        guard recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              recipientDeviceOptions.isEmpty,
              let lastRecipientDeviceContextResetReason,
              let lastRecipientDeviceContextResetAt else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastRecipientDeviceContextResetAt)
        guard elapsed <= 20 else {
            return nil
        }

        let shortRecipientUserID = shortUserID(lastRecipientDeviceContextResetUserID)
        let resetReasonCaption = recipientResetReasonCaption(lastRecipientDeviceContextResetReason)
        return "Recipient-device context reset (\(resetReasonCaption), recipient=\(shortRecipientUserID)) · \(Int(elapsed))s ago."
    }

    private func prefillUserAFromCurrentSessionIfNeeded() {
        guard userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentSessionUserID else {
            return
        }
        userAIDDraft = currentSessionUserID
    }

    private func fillUserAFromCurrentSession() {
        guard let currentSessionUserID else {
            return
        }
        userAIDDraft = currentSessionUserID
    }

    private func applyCurrentSessionUserAsUserAUserBAndOpenDirectThread() async {
        guard let currentSessionUserID else {
            sendStatusHint = "session_user_missing_for_quick_apply"
            return
        }

        let trimmedCurrentSessionUserID = currentSessionUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentUserAID = userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentUserBID = userBIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        let pairStatus: String
        if currentUserAID == trimmedCurrentSessionUserID, currentUserBID == trimmedCurrentSessionUserID {
            pairStatus = "User A + User B already match current session user (user_pair_source=session_user)."
        } else {
            pairStatus = "Applied current session user as User A + User B (user_pair_source=session_user)."
        }

        userAIDDraft = trimmedCurrentSessionUserID
        userBIDDraft = trimmedCurrentSessionUserID
        sendStatusHint = "\(pairStatus) Loading inbox thread..."
        await loadInboxThread(
            userAIDOverride: trimmedCurrentSessionUserID,
            userBIDOverride: trimmedCurrentSessionUserID,
            statusPrefix: pairStatus
        )
    }

    private func applyCurrentSessionUserAsUserAAndSend() async {
        guard let currentSessionUserID else {
            sendStatusHint = "session_sender_missing_for_quick_apply"
            return
        }

        guard conversationSummary != nil else {
            fetchError = "Load direct thread trước khi gửi message."
            return
        }

        let senderStatus: String
        if userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == currentSessionUserID {
            senderStatus = "User A already matches current session user (sender_source=session_user)."
        } else {
            senderStatus = "Applied current session user as User A (sender_source=session_user)."
        }

        userAIDDraft = currentSessionUserID
        sendStatusHint = "\(senderStatus) Sending direct message shell..."
        await sendMessage(senderUserIDOverride: currentSessionUserID, statusPrefix: senderStatus)
    }

    private func applyCurrentSessionUserAsReadStatusFocusUser() {
        guard let currentSessionUserID else {
            sendStatusHint = "session_focus_user_missing_for_quick_apply"
            return
        }

        let focusStatus: String
        if readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == currentSessionUserID {
            focusStatus = "Read focus user already matches current session user (focus_user_source=session_user)."
        } else {
            focusStatus = "Applied current session user as read focus user (focus_user_source=session_user)."
        }

        readStatusFocusUserIDDraft = currentSessionUserID
        sendStatusHint = focusStatus
    }

    private func applyConversationMemberAsReadFocusUser(_ memberUserID: String) {
        let normalizedMemberUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedMemberUserID.isEmpty else {
            sendStatusHint = "member_focus_user_missing"
            return
        }

        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentFocusUserID == normalizedMemberUserID {
            sendStatusHint = "Read focus user already matches selected member (focus_user_source=member_row)."
        } else {
            sendStatusHint = "Applied selected member as read focus user (focus_user_source=member_row)."
        }

        readStatusFocusUserIDDraft = normalizedMemberUserID
    }

    private func applyConversationMemberAsReadCursorTargetUser(_ memberUserID: String) {
        let normalizedMemberUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedMemberUserID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_missing"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentTargetUserID == normalizedMemberUserID {
            sendStatusHint = "Read-cursor target user already matches selected member (read_cursor_user_source=member_row)."
        } else {
            sendStatusHint = "Applied selected member as read-cursor target user (read_cursor_user_source=member_row)."
        }

        readCursorTargetUserIDDraft = normalizedMemberUserID
    }

    private func applyConversationMemberAsReadCursorTargetAndFocusUser(_ memberUserID: String) {
        let normalizedMemberUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedMemberUserID.isEmpty else {
            sendStatusHint = "member_read_cursor_user_missing_for_quick_apply"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedMemberUserID && currentFocusUserID == normalizedMemberUserID

        readCursorTargetUserIDDraft = normalizedMemberUserID
        readStatusFocusUserIDDraft = normalizedMemberUserID

        if alreadyMatched {
            sendStatusHint = "Read-cursor target + read focus already match selected member (read_cursor_user_source=member_row)."
        } else {
            sendStatusHint = "Applied selected member as read-cursor target + read focus (read_cursor_user_source=member_row)."
        }
    }

    private func applyConversationMemberCursorMessageAsReadCursorTargetMessage(_ lastReadMessageID: String?) {
        let normalizedMessageID = lastReadMessageID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedMessageID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_message_missing"
            return
        }

        let alreadyMatched = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == normalizedMessageID
        readCursorTargetMessageIDDraft = normalizedMessageID

        if alreadyMatched {
            sendStatusHint = "Read-cursor target message already matches selected member cursor message (read_cursor_message_source=member_cursor)."
        } else {
            sendStatusHint = "Applied selected member cursor message as read-cursor target message (read_cursor_message_source=member_cursor)."
        }
    }

    private func applyConversationMemberCursorContextForReadCursor(memberUserID: String, lastReadMessageID: String?) {
        let normalizedUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMessageID = lastReadMessageID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !normalizedUserID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_missing_for_context_apply"
            return
        }

        guard !normalizedMessageID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_message_missing_for_context_apply"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedUserID && currentTargetMessageID == normalizedMessageID

        readCursorTargetUserIDDraft = normalizedUserID
        readCursorTargetMessageIDDraft = normalizedMessageID

        if alreadyMatched {
            sendStatusHint = "Read-cursor target user + message already match selected member cursor context (read_cursor_context_source=member_row)."
        } else {
            sendStatusHint = "Applied selected member cursor context as read-cursor target user + message (read_cursor_context_source=member_row)."
        }
    }

    private func applyConversationMemberCursorContextAndFocusUser(memberUserID: String, lastReadMessageID: String?) {
        let normalizedUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMessageID = lastReadMessageID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !normalizedUserID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_missing_for_context_focus_apply"
            return
        }

        guard !normalizedMessageID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_message_missing_for_context_focus_apply"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedUserID && currentTargetMessageID == normalizedMessageID && currentFocusUserID == normalizedUserID

        readCursorTargetUserIDDraft = normalizedUserID
        readCursorTargetMessageIDDraft = normalizedMessageID
        readStatusFocusUserIDDraft = normalizedUserID

        if alreadyMatched {
            sendStatusHint = "Read-cursor target user + message + focus already match selected member cursor context (read_cursor_context_focus_source=member_row)."
        } else {
            sendStatusHint = "Applied selected member cursor context + focus user (read_cursor_context_focus_source=member_row)."
        }
    }

    private func applyConversationMemberCursorContextFocusAndMarkRead(memberUserID: String, lastReadMessageID: String?) {
        let normalizedUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMessageID = lastReadMessageID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !normalizedUserID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_missing_for_context_focus_auto_apply"
            return
        }

        guard !normalizedMessageID.isEmpty else {
            sendStatusHint = "member_read_cursor_target_message_missing_for_context_focus_auto_apply"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedUserID && currentTargetMessageID == normalizedMessageID && currentFocusUserID == normalizedUserID

        readCursorTargetUserIDDraft = normalizedUserID
        readCursorTargetMessageIDDraft = normalizedMessageID
        readStatusFocusUserIDDraft = normalizedUserID

        sendStatusHint = alreadyMatched
            ? "Read-cursor context + focus already match selected member; marking read now (read_cursor_context_focus_auto_source=member_row)."
            : "Applied selected member cursor context + focus and marking read now (read_cursor_context_focus_auto_source=member_row)."

        Task {
            await performReadCursorUpdate(targetUserID: normalizedUserID, targetMessageID: normalizedMessageID)
        }
    }

    private func applyConversationMemberLatestLoadedFocusAndMarkRead(memberUserID: String) {
        let normalizedUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUserID.isEmpty else {
            sendStatusHint = "member_focus_user_missing_for_latest_auto_mark"
            return
        }

        guard let latestMessageID = latestLoadedMessageID,
              !latestMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            sendStatusHint = "latest_loaded_message_missing_for_member_focus_auto_mark"
            return
        }

        let normalizedMessageID = latestMessageID.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedUserID && currentTargetMessageID == normalizedMessageID && currentFocusUserID == normalizedUserID

        readCursorTargetUserIDDraft = normalizedUserID
        readCursorTargetMessageIDDraft = normalizedMessageID
        readStatusFocusUserIDDraft = normalizedUserID

        sendStatusHint = alreadyMatched
            ? "Member focus + latest loaded message already match current read-cursor context; marking read now (read_cursor_latest_focus_auto_source=member_row)."
            : "Applied member focus + latest loaded message and marking read now (read_cursor_latest_focus_auto_source=member_row)."

        Task {
            await performReadCursorUpdate(targetUserID: normalizedUserID, targetMessageID: normalizedMessageID)
        }
    }

    private func applyConversationMemberFirstUnreadFocusAndMarkRead(memberUserID: String) {
        let normalizedUserID = memberUserID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUserID.isEmpty else {
            sendStatusHint = "member_focus_user_missing_for_first_unread_auto_mark"
            return
        }

        guard let firstUnreadMessageID = firstUnreadMessageIDForFocusUser,
              !firstUnreadMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastFirstUnreadGuardQuickCopy = "focus_user=\(normalizedUserID) | first_unread_guard_state=already_at_latest_or_no_unread | candidate=(none)"
            sendStatusHint = "already_at_latest_or_no_unread (first_unread_candidate_missing_for_member_focus_auto_mark)"
            return
        }

        let normalizedMessageID = firstUnreadMessageID.trimmingCharacters(in: .whitespacesAndNewlines)
        lastFirstUnreadGuardQuickCopy = "focus_user=\(normalizedUserID) | first_unread_guard_state=candidate_available | candidate=\(normalizedMessageID)"
        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTargetMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyMatched = currentTargetUserID == normalizedUserID && currentTargetMessageID == normalizedMessageID && currentFocusUserID == normalizedUserID

        readCursorTargetUserIDDraft = normalizedUserID
        readCursorTargetMessageIDDraft = normalizedMessageID
        readStatusFocusUserIDDraft = normalizedUserID

        sendStatusHint = alreadyMatched
            ? "Member focus + first unread candidate already match current read-cursor context; marking read now (read_cursor_first_unread_focus_auto_source=member_row)."
            : "Applied member focus + first unread candidate and marking read now (read_cursor_first_unread_focus_auto_source=member_row)."

        Task {
            await performReadCursorUpdate(targetUserID: normalizedUserID, targetMessageID: normalizedMessageID)
        }
    }

    private func applyCurrentSessionUserAsReadCursorTargetAndFocusUser() {
        guard let currentSessionUserID else {
            sendStatusHint = "session_read_cursor_user_missing_for_quick_apply"
            return
        }

        let currentTargetUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        let bothAlreadyMatch = currentTargetUserID == currentSessionUserID && currentFocusUserID == currentSessionUserID

        readCursorTargetUserIDDraft = currentSessionUserID
        readStatusFocusUserIDDraft = currentSessionUserID

        if bothAlreadyMatch {
            sendStatusHint = "Read-cursor target + read focus already match current session user (read_cursor_user_source=session_user)."
        } else {
            sendStatusHint = "Applied current session user as read-cursor target + read focus (read_cursor_user_source=session_user)."
        }
    }

    private func clearCursorFormSyncHintIfIdentityChanged() {
        lastCursorFormSyncSummary = nil
        lastCursorFormSyncAt = nil
        lastRecipientDevicesAutoReloadAt = nil
        lastRecipientDevicesRateLimitSkipAt = nil
    }

    private func clearRecipientDeviceContext(reason: String? = nil, recipientUserID: String? = nil) {
        recipientDevicesAutoReloadTask?.cancel()
        recipientDevicesAutoReloadTask = nil
        recipientDeviceOptions = []
        recipientDeviceIDDraft = ""
        recipientUserIDDraft = ""

        if let reason {
            lastRecipientDeviceContextResetReason = reason
            lastRecipientDeviceContextResetAt = Date()
            lastRecipientDeviceContextResetUserID = recipientUserID
        } else {
            lastRecipientDeviceContextResetReason = nil
            lastRecipientDeviceContextResetAt = nil
            lastRecipientDeviceContextResetUserID = nil
        }
    }

    private func handleDirectThreadIdentityChange() {
        clearCursorFormSyncHintIfIdentityChanged()
        clearRecipientDeviceContext()
    }

    private func loadInboxThread(
        userAIDOverride: String? = nil,
        userBIDOverride: String? = nil,
        statusPrefix: String? = nil,
        silent: Bool = false
    ) async {
        let trimmedUserA = (userAIDOverride ?? userAIDDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserB = (userBIDOverride ?? userBIDDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStatusPrefix = statusPrefix?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserA.isEmpty, !trimmedUserB.isEmpty else {
            if !silent {
                fetchError = "Cần đủ hai user UUID để load direct thread."
            }
            return
        }

        isLoading = true
        if !silent {
            fetchError = nil
            lastSendQuickCopy = "sender=(none) | message_id=(none)"
            if let normalizedStatusPrefix, !normalizedStatusPrefix.isEmpty {
                sendStatusHint = "\(normalizedStatusPrefix) Loading inbox thread..."
            }
        }

        do {
            let apiClient = InboxAPIClient()
            let directConversation = try await apiClient.resolveDirectConversation(userAID: trimmedUserA, userBID: trimmedUserB)
            let members = try await apiClient.fetchConversationMembers(conversationID: directConversation.id)
            let messages = try await apiClient.fetchMessages(conversationID: directConversation.id)
            var nextAttachmentMap: [String: [InboxAttachmentRow]] = [:]
            var nextDeviceKeyMap: [String: [InboxDeviceKeyRow]] = [:]
            for message in messages {
                nextAttachmentMap[message.id] = try await apiClient.fetchAttachments(messageID: message.id)
                nextDeviceKeyMap[message.id] = try await apiClient.fetchMessageDeviceKeys(messageID: message.id)
            }
            conversationSummary = directConversation
            conversationMembers = members
            messageRows = messages
            attachmentMap = nextAttachmentMap
            deviceKeyMap = nextDeviceKeyMap
            userAIDDraft = trimmedUserA
            userBIDDraft = trimmedUserB

            let manualReadCursorMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadCursorMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualReadCursorMessageID }) {
                readCursorTargetMessageIDDraft = ""
            }

            let manualDeleteMessageID = messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualDeleteMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualDeleteMessageID }) {
                messageToDeleteIDDraft = ""
            }

            let manualAttachmentTargetMessageID = attachmentTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualAttachmentTargetMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualAttachmentTargetMessageID }) {
                attachmentTargetMessageIDDraft = ""
            }

            let manualDeviceKeyTargetMessageID = deviceKeyTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualDeviceKeyTargetMessageID.isEmpty,
               !messages.contains(where: { $0.id == manualDeviceKeyTargetMessageID }) {
                deviceKeyTargetMessageIDDraft = ""
            }

            let manualReadCursorUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadCursorUserID.isEmpty,
               !members.contains(where: { $0.userID == manualReadCursorUserID }) {
                readCursorTargetUserIDDraft = ""
            }

            let manualReadStatusFocusUserID = readStatusFocusUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !manualReadStatusFocusUserID.isEmpty,
               !members.contains(where: { $0.userID == manualReadStatusFocusUserID }) {
                readStatusFocusUserIDDraft = ""
            }

            if members.isEmpty {
                clearCursorFormSyncHintIfIdentityChanged()
            }

            if let lastCursorFormSyncAt {
                let elapsed = Date().timeIntervalSince(lastCursorFormSyncAt)
                if elapsed > 15 {
                    lastCursorFormSyncSummary = nil
                    self.lastCursorFormSyncAt = nil
                }
            }

            let syncUserID = readCursorTargetUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            let syncMessageID = readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !syncUserID.isEmpty, !members.isEmpty {
                if syncMessageID.isEmpty {
                    lastCursorFormSyncSummary = "cursor_form_sync: user=\(syncUserID) message=(auto_or_empty)"
                } else {
                    lastCursorFormSyncSummary = "cursor_form_sync: user=\(syncUserID) message=\(syncMessageID)"
                }
                self.lastCursorFormSyncAt = Date()
            }

            let resolvedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !resolvedRecipientUserID.isEmpty {
                let memberUserIDs = Set(members.map(\.userID))
                if memberUserIDs.contains(resolvedRecipientUserID) {
                    await loadRecipientDevices(silent: true)
                } else {
                    clearRecipientDeviceContext(
                        reason: "non_member_after_switch",
                        recipientUserID: resolvedRecipientUserID
                    )
                }
            }

            if !silent,
               let normalizedStatusPrefix,
               !normalizedStatusPrefix.isEmpty {
                sendStatusHint = "\(normalizedStatusPrefix) Loaded direct thread \(directConversation.id) with \(messages.count) message(s)."
            }
        } catch {
            if !silent {
                conversationSummary = nil
                conversationMembers = []
                messageRows = []
                attachmentMap = [:]
                deviceKeyMap = [:]
                clearCursorFormSyncHintIfIdentityChanged()
                clearRecipientDeviceContext()
                let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                fetchError = errorMessage
                if let normalizedStatusPrefix,
                   !normalizedStatusPrefix.isEmpty {
                    sendStatusHint = "\(normalizedStatusPrefix) \(errorMessage)"
                }
            }
        }

        isLoading = false
    }

    private func sendMessage() async {
        await sendMessage(senderUserIDOverride: nil, statusPrefix: nil)
    }

    private func sendMessage(senderUserIDOverride: String?, statusPrefix: String?) async {
        let trimmedUserA = senderUserIDOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? userAIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayload = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let conversationID = conversationSummary?.id else {
            fetchError = "Load direct thread trước khi gửi message."
            return
        }

        guard !trimmedUserA.isEmpty else {
            fetchError = "User A UUID là bắt buộc để gửi message."
            return
        }

        guard !trimmedPayload.isEmpty else {
            fetchError = "Message text không được để trống."
            return
        }

        isSendingMessage = true
        fetchError = nil
        if let statusPrefix {
            sendStatusHint = "\(statusPrefix) Sending direct message shell..."
        } else {
            sendStatusHint = nil
        }

        do {
            let created = try await InboxAPIClient().createMessage(
                conversationID: conversationID,
                senderUserID: trimmedUserA,
                payloadText: trimmedPayload
            )
            messageDraft = ""
            messageToDeleteIDDraft = ""
            await loadInboxThread()

            let sentStatus = "Sent message \(created.id) into direct thread \(conversationID)."
            let senderValue = trimmedUserA.isEmpty ? "(empty)" : trimmedUserA
            lastSendQuickCopy = "sender=\(senderValue) | message_id=\(created.id)"
            if let statusPrefix {
                sendStatusHint = "\(statusPrefix) \(sentStatus)"
            } else {
                sendStatusHint = sentStatus
            }
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSendingMessage = false
    }

    private func createAttachment() async {
        guard let targetMessageID = resolvedAttachmentTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để tạo attachment."
            return
        }

        let trimmedType = attachmentTypeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStorageKey = attachmentStorageKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBlob = attachmentBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedType.isEmpty else {
            fetchError = "Attachment type là bắt buộc."
            return
        }

        guard !trimmedBlob.isEmpty else {
            fetchError = "Encrypted blob placeholder là bắt buộc."
            return
        }

        isCreatingAttachment = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().createAttachment(
                messageID: targetMessageID,
                attachmentType: trimmedType,
                encryptedAttachmentBlob: trimmedBlob,
                storageKey: trimmedStorageKey.isEmpty ? nil : trimmedStorageKey
            )
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingAttachment = false
    }

    private func createMessageDeviceKey() async {
        guard let targetMessageID = resolvedDeviceKeyTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để tạo device key."
            return
        }

        let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRecipientDeviceID = recipientDeviceIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWrappedBlob = wrappedMessageKeyBlobDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientUserID.isEmpty else {
            fetchError = "Recipient user UUID là bắt buộc."
            return
        }

        guard !trimmedRecipientDeviceID.isEmpty else {
            fetchError = "Recipient device UUID là bắt buộc."
            return
        }

        guard !trimmedWrappedBlob.isEmpty else {
            fetchError = "Wrapped message key blob là bắt buộc."
            return
        }

        isCreatingDeviceKey = true
        fetchError = nil

        do {
            _ = try await InboxAPIClient().createMessageDeviceKey(
                messageID: targetMessageID,
                recipientUserID: trimmedRecipientUserID,
                recipientDeviceID: trimmedRecipientDeviceID,
                wrappedMessageKeyBlob: trimmedWrappedBlob
            )
            wrappedMessageKeyBlobDraft = "ios-demo-wrapped-message-key"
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isCreatingDeviceKey = false
    }

    private func loadRecipientDevices(silent: Bool = false) async {
        let trimmedRecipientUserID = recipientUserIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipientUserID.isEmpty else {
            recipientDeviceOptions = []
            recipientDeviceIDDraft = ""
            lastRecipientDevicesRateLimitSkipAt = nil
            return
        }

        lastRecipientDevicesRateLimitSkipAt = nil

        isLoadingRecipientDevices = true

        defer {
            isLoadingRecipientDevices = false
        }

        do {
            let options = try await InboxAPIClient().fetchDevices(userID: trimmedRecipientUserID)
            recipientDeviceOptions = options
            if options.contains(where: { $0.id == recipientDeviceIDDraft }) == false {
                recipientDeviceIDDraft = options.first?.id ?? ""
            }
        } catch {
            recipientDeviceOptions = []
            recipientDeviceIDDraft = ""
            if !silent {
                fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func updateReadCursor() async {
        guard let targetUserID = resolvedReadCursorTargetUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần member user UUID hợp lệ để cập nhật read cursor."
            return
        }

        guard let targetMessageID = resolvedReadCursorTargetMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để cập nhật read cursor."
            return
        }

        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func markLatestMessageAsReadForFocusUser() async {
        guard let targetUserID = resolvedReadStatusFocusUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần focus user UUID hợp lệ để mark latest message as read."
            return
        }

        guard let targetMessageID = latestLoadedMessageID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Không có message nào để mark as read."
            return
        }

        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func applyFocusUserAndFirstUnreadCandidatePreset() {
        guard let targetUserID = resolvedReadStatusFocusUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            sendStatusHint = "focus_user_missing_for_first_unread_preset"
            return
        }

        readCursorTargetUserIDDraft = targetUserID

        guard let targetMessageID = firstUnreadMessageIDForFocusUser,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            readCursorTargetMessageIDDraft = ""
            lastFirstUnreadGuardQuickCopy = "focus_user=\(targetUserID) | first_unread_guard_state=already_at_latest_or_no_unread | candidate=(none)"
            sendStatusHint = "Applied focus user as read-cursor target; no first unread candidate (read_cursor_first_unread_preset_source=focus_user)."
            return
        }

        readCursorTargetMessageIDDraft = targetMessageID
        lastFirstUnreadGuardQuickCopy = "focus_user=\(targetUserID) | first_unread_guard_state=candidate_available | candidate=\(targetMessageID)"
        sendStatusHint = "Applied focus user + first unread candidate as read-cursor target/message (read_cursor_first_unread_preset_source=focus_user)."
    }

    private func jumpToFirstUnreadCandidateForFocusUser() async {
        guard let targetUserID = resolvedReadStatusFocusUserID,
              !targetUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần focus user UUID hợp lệ để jump first unread."
            return
        }

        guard let targetMessageID = firstUnreadMessageIDForFocusUser,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastFirstUnreadGuardQuickCopy = "focus_user=\(targetUserID) | first_unread_guard_state=already_at_latest_or_no_unread | candidate=(none)"
            sendStatusHint = "already_at_latest_or_no_unread (read_cursor_first_unread_focus_source=focus_user)"
            fetchError = nil
            return
        }

        lastFirstUnreadGuardQuickCopy = "focus_user=\(targetUserID) | first_unread_guard_state=candidate_available | candidate=\(targetMessageID)"
        sendStatusHint = "Applying focus user + first unread candidate and marking read now (read_cursor_first_unread_focus_source=focus_user)."
        await performReadCursorUpdate(targetUserID: targetUserID, targetMessageID: targetMessageID)
    }

    private func performReadCursorUpdate(targetUserID: String, targetMessageID: String) async {
        guard let conversationID = conversationSummary?.id else {
            fetchError = "Load direct thread trước khi cập nhật read cursor."
            return
        }

        isUpdatingReadCursor = true
        fetchError = nil

        do {
            let previousMemberCursorMessageID = conversationMembers.first(where: { $0.userID == targetUserID })?.lastReadMessageID

            let updatedMemberRow = try await InboxAPIClient().updateConversationReadCursor(
                conversationID: conversationID,
                userID: targetUserID,
                lastReadMessageID: targetMessageID
            )

            let normalizedFocusUserID = resolvedReadStatusFocusUserID ?? "(none)"
            let appliedReadState: String
            if let focusUserID = resolvedReadStatusFocusUserID,
               !focusUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               focusUserID == targetUserID {
                appliedReadState = "read"
            } else if resolvedReadStatusFocusUserID != nil {
                appliedReadState = "unread"
            } else {
                appliedReadState = "unknown"
            }

            let readCursorApplyState = previousMemberCursorMessageID == targetMessageID ? "noop" : "updated"

            let normalizedPreviousCursorMessageID = previousMemberCursorMessageID ?? "(none)"
            let normalizedCurrentMemberCursorMessageID = updatedMemberRow.lastReadMessageID ?? "(none)"
            lastReadCursorApplyQuickCopy = "target_user=\(targetUserID) | previous_cursor_message=\(normalizedPreviousCursorMessageID) | applied_message=\(targetMessageID) | current_member_cursor=\(normalizedCurrentMemberCursorMessageID) | focus_user=\(normalizedFocusUserID) | read_state=\(appliedReadState) | read_cursor_apply_state=\(readCursorApplyState)"
            lastReadCursorTriageQuickCopy = "read_cursor_triage=target_user:\(targetUserID),previous:\(normalizedPreviousCursorMessageID),applied:\(targetMessageID),current:\(normalizedCurrentMemberCursorMessageID),apply_state:\(readCursorApplyState)"

            if sendStatusHint?.contains("read_cursor_first_unread_focus_auto_source=member_row") == true ||
                sendStatusHint?.contains("read_cursor_first_unread_focus_source=focus_user") == true {
                lastFirstUnreadJumpQuickCopy = "focus_user=\(normalizedFocusUserID) | first_unread_candidate=\(targetMessageID) | applied_message=\(targetMessageID) | read_state=\(appliedReadState)"
            }

            sendStatusHint = (sendStatusHint.map { "\($0) " } ?? "") + "Read-cursor apply state: \(readCursorApplyState)."

            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isUpdatingReadCursor = false
    }

    private func deleteMessage() async {
        guard let targetMessageID = resolvedMessageToDeleteID,
              !targetMessageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fetchError = "Cần message UUID hợp lệ để delete."
            return
        }

        isDeletingMessage = true
        fetchError = nil

        do {
            try await InboxAPIClient().deleteMessage(messageID: targetMessageID)
            if attachmentTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                attachmentTargetMessageIDDraft = ""
            }
            if deviceKeyTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                deviceKeyTargetMessageIDDraft = ""
            }
            if readCursorTargetMessageIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                readCursorTargetMessageIDDraft = ""
            }
            if messageToDeleteIDDraft.trimmingCharacters(in: .whitespacesAndNewlines) == targetMessageID {
                messageToDeleteIDDraft = ""
            }
            await loadInboxThread()
        } catch {
            fetchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isDeletingMessage = false
    }
}

private struct DirectConversationSummary {
    let id: String
    let conversationType: String
    let memberUserIDs: [String]
}

private struct InboxMessageRow: Identifiable {
    let id: String
    let senderUserID: String
    let payloadText: String
}

private struct InboxConversationMemberRow: Identifiable {
    let id: String
    let conversationID: String
    let userID: String
    let lastReadMessageID: String?
}

private struct InboxAttachmentRow: Identifiable {
    let id: String
    let attachmentType: String
    let storageKey: String?
}

private struct InboxDeviceKeyRow: Identifiable {
    let id: String
    let messageID: String
    let recipientUserID: String
    let recipientDeviceID: String
}

private struct InboxDeviceOptionRow: Identifiable {
    let id: String
    let platform: String
    let deviceName: String
    let deviceTrustState: String
}

private struct InboxAPIClient {
    private struct DirectConversationResponse: Decodable {
        let id: String
        let conversation_type: String
        let member_user_ids: [String]
    }

    private struct ConversationMemberListResponse: Decodable {
        let count: Int
        let items: [ConversationMemberResponse]
    }

    private struct ConversationMemberResponse: Decodable {
        let id: String
        let conversation_id: String
        let user_id: String
        let last_read_message_id: String?
    }

    private struct MessageListResponse: Decodable {
        let count: Int
        let items: [MessageResponse]
    }

    private struct MessageResponse: Decodable {
        let id: String
        let conversation_id: String
        let sender_user_id: String
        let payload_text: String
    }

    private struct MessageCreateRequest: Encodable {
        let sender_user_id: String
        let payload_text: String
        let conversation_id: String
    }

    private struct AttachmentListResponse: Decodable {
        let count: Int
        let items: [AttachmentResponse]
    }

    private struct AttachmentResponse: Decodable {
        let id: String
        let message_id: String
        let attachment_type: String
        let encrypted_attachment_blob: String
        let storage_key: String?
    }

    private struct AttachmentCreateRequest: Encodable {
        let attachment_type: String
        let encrypted_attachment_blob: String
        let storage_key: String?
    }

    private struct MessageDeviceKeyListResponse: Decodable {
        let count: Int
        let items: [MessageDeviceKeyResponse]
    }

    private struct MessageDeviceKeyResponse: Decodable {
        let id: String
        let message_id: String
        let recipient_user_id: String
        let recipient_device_id: String
        let wrapped_message_key_blob: String
    }

    private struct MessageDeviceKeyCreateRequest: Encodable {
        let recipient_user_id: String
        let recipient_device_id: String
        let wrapped_message_key_blob: String
    }

    private struct ConversationReadCursorUpdateRequest: Encodable {
        let last_read_message_id: String
    }

    private struct DeviceListResponse: Decodable {
        let count: Int
        let items: [DeviceResponse]
    }

    private struct DeviceResponse: Decodable {
        let id: String
        let user_id: String
        let platform: String
        let device_name: String
        let device_trust_state: String
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
                return "Thiếu backend base URL hợp lệ cho inbox shell."
            case let .requestFailed(message):
                return message
            case .invalidResponse:
                return "Backend inbox response thiếu field cần thiết."
            }
        }
    }

    private let baseURL = BackendEnvironment.apiBaseURL

    func resolveDirectConversation(userAID: String, userBID: String) async throws -> DirectConversationSummary {
        let url = try makeURL(path: "/conversations/direct")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_a_id": userAID,
            "user_b_id": userBID,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Direct conversation resolve failed"))
        }

        do {
            let payload = try JSONDecoder().decode(DirectConversationResponse.self, from: data)
            return DirectConversationSummary(
                id: payload.id,
                conversationType: payload.conversation_type,
                memberUserIDs: payload.member_user_ids
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchConversationMembers(conversationID: String) async throws -> [InboxConversationMemberRow] {
        let url = try makeURL(path: "/conversations/\(conversationID)/members")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Conversation members fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ConversationMemberListResponse.self, from: data)
            return payload.items.map {
                InboxConversationMemberRow(
                    id: $0.id,
                    conversationID: $0.conversation_id,
                    userID: $0.user_id,
                    lastReadMessageID: $0.last_read_message_id
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchMessages(conversationID: String) async throws -> [InboxMessageRow] {
        let url = try makeURL(path: "/messages", queryItems: [URLQueryItem(name: "conversation_id", value: conversationID)])
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageListResponse.self, from: data)
            return payload.items.map {
                InboxMessageRow(
                    id: $0.id,
                    senderUserID: $0.sender_user_id,
                    payloadText: $0.payload_text
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createMessage(conversationID: String, senderUserID: String, payloadText: String) async throws -> InboxMessageRow {
        let url = try makeURL(path: "/messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MessageCreateRequest(
                sender_user_id: senderUserID,
                payload_text: payloadText,
                conversation_id: conversationID
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageResponse.self, from: data)
            return InboxMessageRow(
                id: payload.id,
                senderUserID: payload.sender_user_id,
                payloadText: payload.payload_text
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchAttachments(messageID: String) async throws -> [InboxAttachmentRow] {
        let url = try makeURL(path: "/messages/\(messageID)/attachments")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Attachment list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(AttachmentListResponse.self, from: data)
            return payload.items.map {
                InboxAttachmentRow(
                    id: $0.id,
                    attachmentType: $0.attachment_type,
                    storageKey: $0.storage_key
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchMessageDeviceKeys(messageID: String) async throws -> [InboxDeviceKeyRow] {
        let url = try makeURL(path: "/messages/\(messageID)/device-keys")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message device-key list fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageDeviceKeyListResponse.self, from: data)
            return payload.items.map {
                InboxDeviceKeyRow(
                    id: $0.id,
                    messageID: $0.message_id,
                    recipientUserID: $0.recipient_user_id,
                    recipientDeviceID: $0.recipient_device_id
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func createMessageDeviceKey(
        messageID: String,
        recipientUserID: String,
        recipientDeviceID: String,
        wrappedMessageKeyBlob: String
    ) async throws -> InboxDeviceKeyRow {
        let url = try makeURL(path: "/messages/\(messageID)/device-keys")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            MessageDeviceKeyCreateRequest(
                recipient_user_id: recipientUserID,
                recipient_device_id: recipientDeviceID,
                wrapped_message_key_blob: wrappedMessageKeyBlob
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message device-key create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(MessageDeviceKeyResponse.self, from: data)
            return InboxDeviceKeyRow(
                id: payload.id,
                messageID: payload.message_id,
                recipientUserID: payload.recipient_user_id,
                recipientDeviceID: payload.recipient_device_id
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func updateConversationReadCursor(
        conversationID: String,
        userID: String,
        lastReadMessageID: String
    ) async throws -> InboxConversationMemberRow {
        let url = try makeURL(path: "/conversations/\(conversationID)/members/\(userID)/read-cursor")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ConversationReadCursorUpdateRequest(last_read_message_id: lastReadMessageID)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Read cursor update failed"))
        }

        do {
            let payload = try JSONDecoder().decode(ConversationMemberResponse.self, from: data)
            return InboxConversationMemberRow(
                id: payload.id,
                conversationID: payload.conversation_id,
                userID: payload.user_id,
                lastReadMessageID: payload.last_read_message_id
            )
        } catch {
            throw APIError.invalidResponse
        }
    }

    func fetchDevices(userID: String) async throws -> [InboxDeviceOptionRow] {
        let url = try makeURL(path: "/auth/devices/\(userID)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Recipient devices fetch failed"))
        }

        do {
            let payload = try JSONDecoder().decode(DeviceListResponse.self, from: data)
            return payload.items.map {
                InboxDeviceOptionRow(
                    id: $0.id,
                    platform: $0.platform,
                    deviceName: $0.device_name,
                    deviceTrustState: $0.device_trust_state
                )
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    func deleteMessage(messageID: String) async throws {
        let url = try makeURL(path: "/messages/\(messageID)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Message delete failed"))
        }
    }

    func createAttachment(
        messageID: String,
        attachmentType: String,
        encryptedAttachmentBlob: String,
        storageKey: String?
    ) async throws -> InboxAttachmentRow {
        let url = try makeURL(path: "/messages/\(messageID)/attachments")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AttachmentCreateRequest(
                attachment_type: attachmentType,
                encrypted_attachment_blob: encryptedAttachmentBlob,
                storage_key: storageKey
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try requireHTTPResponse(response)

        guard httpResponse.statusCode == 201 else {
            throw APIError.requestFailed(readErrorMessage(from: data, statusCode: httpResponse.statusCode, prefix: "Attachment create failed"))
        }

        do {
            let payload = try JSONDecoder().decode(AttachmentResponse.self, from: data)
            return InboxAttachmentRow(
                id: payload.id,
                attachmentType: payload.attachment_type,
                storageKey: payload.storage_key
            )
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
