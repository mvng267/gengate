"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createMomentReaction,
  createMomentWithImage,
  deleteMoment,
  listMomentReactions,
  listMomentsForAuthor,
  listPrivateFeed,
  type MomentDeleteResult,
  type MomentListItem,
  type MomentReactionItem,
} from "@/lib/moments/client";
type MomentComposeShellProps = {
  initialAuthorUserId?: string;
  initialViewerUserId?: string;
};

type FeedGateSnapshotSource = "create_flow" | "reload_flow" | "delete_flow";
type DeleteSnapshotSource = "manual_input" | "preset_row" | "first_authored_quick_pick";
type DeleteSummaryCopySource = "quick_delete_parity" | "last_delete_result" | "copied_feedback";
type ReactionQuickCopySource = "create_reaction" | "list_reactions";

const deleteSummaryCopySources: DeleteSummaryCopySource[] = [
  "quick_delete_parity",
  "last_delete_result",
  "copied_feedback",
];

const initialForm = {
  authorUserId: "",
  viewerUserId: "",
  captionText: "",
  imageStorageKey: "moments/demo-image.jpg",
  imageMimeType: "image/jpeg",
  imageWidth: "1080",
  imageHeight: "1350",
};

export function MomentComposeShell({ initialAuthorUserId = "", initialViewerUserId = "" }: MomentComposeShellProps) {
  const [form, setForm] = useState({
    ...initialForm,
    authorUserId: initialAuthorUserId,
    viewerUserId: initialViewerUserId,
  });
  const [status, setStatus] = useState("Provide a real user UUID, caption, and image storage key to test the moment shell.");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isLoadingList, setIsLoadingList] = useState(false);
  const [isLoadingFeed, setIsLoadingFeed] = useState(false);
  const [isCreatingReaction, setIsCreatingReaction] = useState(false);
  const [isLoadingReactions, setIsLoadingReactions] = useState(false);
  const [items, setItems] = useState<MomentListItem[]>([]);
  const [feedItems, setFeedItems] = useState<MomentListItem[]>([]);
  const [reactionItems, setReactionItems] = useState<MomentReactionItem[]>([]);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const [lastCreateFeedVisibilityDeltaLine, setLastCreateFeedVisibilityDeltaLine] = useState<string | null>(null);
  const [lastCreateFeedGateSummaryLine, setLastCreateFeedGateSummaryLine] = useState<string | null>(null);
  const [lastDeletedMomentSummaryLine, setLastDeletedMomentSummaryLine] = useState<string | null>(null);
  const [deleteMomentIdDraft, setDeleteMomentIdDraft] = useState("");
  const [reactionMomentIdDraft, setReactionMomentIdDraft] = useState("");
  const [reactionUserIdDraft, setReactionUserIdDraft] = useState("");
  const [reactionTypeDraft, setReactionTypeDraft] = useState("heart");
  const [lastCopiedFeedVisibilityDeltaLine, setLastCopiedFeedVisibilityDeltaLine] = useState<string | null>(null);
  const [lastCopiedCreateFeedGateBundleLine, setLastCopiedCreateFeedGateBundleLine] = useState<string | null>(null);
  const [lastCopiedLastCreateFeedGateBundleLine, setLastCopiedLastCreateFeedGateBundleLine] = useState<string | null>(null);
  const [lastCopiedLastDeleteFeedGateBundleLine, setLastCopiedLastDeleteFeedGateBundleLine] = useState<string | null>(null);
  const [lastCopiedDeleteSummaryLine, setLastCopiedDeleteSummaryLine] = useState<string | null>(null);
  const [lastDeleteCopyAuditLine, setLastDeleteCopyAuditLine] = useState<string | null>(null);
  const [lastDeleteCopyAuditFirstReadySourceLine, setLastDeleteCopyAuditFirstReadySourceLine] = useState<string | null>(null);
  const [lastDeleteCopyAuditSourceStateSnapshotLine, setLastDeleteCopyAuditSourceStateSnapshotLine] =
    useState<string | null>(null);
  const [lastDeleteCopyAuditSourceStateSnapshotSourceLine, setLastDeleteCopyAuditSourceStateSnapshotSourceLine] =
    useState<string | null>(null);
  const [lastReactionQuickCopyLine, setLastReactionQuickCopyLine] = useState<string | null>(null);
  const [lastReactionQuickCopySource, setLastReactionQuickCopySource] = useState<ReactionQuickCopySource | null>(null);
  const [deleteCopyAuditSourceDraft, setDeleteCopyAuditSourceDraft] = useState<DeleteSummaryCopySource>("quick_delete_parity");
  const [feedVisibilityGateSnapshotSource, setFeedVisibilityGateSnapshotSource] =
    useState<FeedGateSnapshotSource>("reload_flow");
  const [deleteSnapshotSource, setDeleteSnapshotSource] = useState<DeleteSnapshotSource>("manual_input");
  const buildFeedVisibilityGateSummary = (
    viewerRawId: string,
    nextFeedItems: MomentListItem[],
    snapshotSource: FeedGateSnapshotSource,
  ) => {
    const normalizedViewerId = viewerRawId.trim();
    const viewerAccessReason = !normalizedViewerId
      ? "viewer_missing"
      : nextFeedItems.length > 0
        ? "granted"
        : "empty_or_blocked";
    const viewerAccess = viewerAccessReason === "granted" ? "granted" : "not_granted";
    const visibleCount = nextFeedItems.length;
    const firstMomentId = nextFeedItems[0]?.id ?? "(none)";

    return {
      viewerAccess,
      viewerAccessReason,
      visibleCount,
      firstMomentId,
      summaryLine:
        `viewer_access=${viewerAccess}` +
        ` / viewer_access_reason=${viewerAccessReason}` +
        ` / gate_snapshot_source=${snapshotSource}` +
        ` / visible_count=${visibleCount}` +
        ` / first_moment_id=${firstMomentId}`,
    };
  };

  const momentPayloadQuickCopy = `author=${form.authorUserId.trim() || "(empty)"} | image_url=${form.imageStorageKey.trim() || "(empty)"} | caption=${form.captionText.trim() || "(empty)"}`;
  const viewerUserId = form.viewerUserId.trim();
  const deleteMomentId = deleteMomentIdDraft.trim();
  const quickFeedVisibilityGate = buildFeedVisibilityGateSummary(viewerUserId, feedItems, feedVisibilityGateSnapshotSource);
  const quickFeedVisibilityDeltaLine = `viewer=${viewerUserId || "(empty)"} / feed_count=${feedItems.length} / first_moment_id=${feedItems[0]?.id ?? "(none)"}`;
  const reactionMomentId = reactionMomentIdDraft.trim();
  const reactionUserId = reactionUserIdDraft.trim();
  const reactionType = reactionTypeDraft.trim();
  const quickReactionSummaryLine =
    `reaction_target_moment_id=${reactionMomentId || "(empty)"}` +
    ` / reaction_user_id=${reactionUserId || "(empty)"}` +
    ` / reaction_type=${reactionType || "(empty)"}` +
    ` / loaded_reaction_count=${reactionItems.length}`;
  const quickFeedVisibilityGateSummaryLine = quickFeedVisibilityGate.summaryLine;
  const quickCreateFeedGateBundleLine =
    `moment_create_marker={${momentPayloadQuickCopy}} | ` +
    `feed_gate_summary={${quickFeedVisibilityGateSummaryLine}}`;
  const lastCreateFeedGateBundleLine =
    lastCreateFeedVisibilityDeltaLine && lastCreateFeedGateSummaryLine
      ? `last_create_feed_visibility_delta={${lastCreateFeedVisibilityDeltaLine}} | ` +
        `feed_gate_summary={${lastCreateFeedGateSummaryLine}}`
      : "";
  const lastDeleteFeedGateBundleLine =
    lastDeletedMomentSummaryLine && quickFeedVisibilityGateSummaryLine
      ? `last_delete_result={${lastDeletedMomentSummaryLine}} | feed_gate_summary={${quickFeedVisibilityGateSummaryLine}}`
      : "";
  const deleteMomentQuickCopyLine =
    `delete_moment_id=${deleteMomentId || "(empty)"}` +
    ` / authored_count=${items.length}` +
    ` / feed_count=${feedItems.length}` +
    ` / gate_snapshot_source=${feedVisibilityGateSnapshotSource}` +
    ` / delete_snapshot_source=${deleteSnapshotSource}`;
  const lastCopiedDeleteSummaryFeedbackLine =
    lastCopiedDeleteSummaryLine ? `Last copied delete summary: ${lastCopiedDeleteSummaryLine}` : "";
  const buildDeleteCopyAuditLine = (source: DeleteSummaryCopySource, value: string) => {
    const normalizedValue = value.trim();
    return `delete_copy_audit=source:${source}/value:${normalizedValue}`;
  };
  const buildDeleteCopyAuditFirstReadySourceLine = (source: DeleteSummaryCopySource | "none") =>
    `delete_copy_audit_first_ready_source=${source}`;
  const resolveDeleteCopyAuditSourceValue = (source: DeleteSummaryCopySource) => {
    switch (source) {
      case "quick_delete_parity":
        return deleteMomentQuickCopyLine;
      case "last_delete_result":
        return lastDeletedMomentSummaryLine ?? "";
      case "copied_feedback":
        return lastCopiedDeleteSummaryFeedbackLine;
      default:
        return "";
    }
  };
  const deleteCopyAuditSourceReadiness = deleteSummaryCopySources.map((source) => ({
    source,
    hasValue: resolveDeleteCopyAuditSourceValue(source).trim().length > 0,
  }));
  const deleteCopyAuditReadyCount = deleteCopyAuditSourceReadiness.filter(({ hasValue }) => hasValue).length;
  const deleteCopyAuditSourceStateLine =
    "delete_copy_audit_source_state=" +
    deleteCopyAuditSourceReadiness
      .map(({ source, hasValue }) => `${source}:${hasValue ? "ready" : "missing"}`)
      .join("/") +
    `/ready_count=${deleteCopyAuditReadyCount}/total=${deleteSummaryCopySources.length}`;
  const lastReactionQuickCopyFeedbackLine =
    lastReactionQuickCopyLine && lastReactionQuickCopySource
      ? `Last copied reaction quick summary (${lastReactionQuickCopySource}): ${lastReactionQuickCopyLine}`
      : "";

  useEffect(() => {
    setForm((current) => ({
      ...current,
      authorUserId: initialAuthorUserId,
      viewerUserId: initialViewerUserId,
    }));
    setItems([]);
    setFeedItems([]);
    setReactionItems([]);
    setReactionMomentIdDraft("");
    setReactionUserIdDraft("");
    setReactionTypeDraft("heart");
    setLastReactionQuickCopyLine(null);
    setLastReactionQuickCopySource(null);
    setFeedVisibilityGateSnapshotSource("reload_flow");
  }, [initialAuthorUserId, initialViewerUserId]);

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  function applyCurrentSessionUserAsAuthor() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_author_missing_for_quick_apply");
      return;
    }

    const draftAuthorUserId = form.authorUserId.trim();
    if (draftAuthorUserId === sessionUserId) {
      setStatus("Create author already matches current session user (author_source=session_user).");
      return;
    }

    setForm((current) => ({
      ...current,
      authorUserId: sessionUserId,
    }));
    setStatus("Applied current session user as create author (author_source=session_user).");
  }

  async function handleApplyCurrentSessionUserAsAuthorCreateAndReloadFeed() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_author_missing_for_quick_apply");
      return;
    }

    const draftAuthorUserId = form.authorUserId.trim();
    const sourceStatus =
      draftAuthorUserId === sessionUserId
        ? "Create author already matches current session user (author_source=session_user)."
        : "Applied current session user as create author (author_source=session_user).";

    setForm((current) => ({
      ...current,
      authorUserId: sessionUserId,
    }));

    await submitMomentCreateFlow(sessionUserId, sourceStatus);
  }

  async function handleApplyCurrentSessionUserAsViewerAuthorCreateAndReloadFeed() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_user_missing_for_quick_apply");
      return;
    }

    const draftAuthorUserId = form.authorUserId.trim();
    const draftViewerUserId = form.viewerUserId.trim();

    const authorStatus =
      draftAuthorUserId === sessionUserId
        ? "Create author already matches current session user (author_source=session_user)."
        : "Applied current session user as create author (author_source=session_user).";
    const viewerStatus =
      draftViewerUserId === sessionUserId
        ? "Viewer already matches current session user (viewer_source=session_user)."
        : "Applied current session user as feed viewer (viewer_source=session_user).";

    setForm((current) => ({
      ...current,
      authorUserId: sessionUserId,
      viewerUserId: sessionUserId,
    }));

    await submitMomentCreateFlow(sessionUserId, `${authorStatus} ${viewerStatus}`, sessionUserId);
  }

  async function applyCurrentSessionUserAsViewerKeepAuthorAndLoadPrivateFeed() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_viewer_missing_for_quick_apply");
      return;
    }

    const draftViewerUserId = form.viewerUserId.trim();
    const viewerStatus =
      draftViewerUserId === sessionUserId
        ? "Viewer already matches current session user (viewer_source=session_user)."
        : "Applied current session user as feed viewer (viewer_source=session_user).";

    setForm((current) => ({
      ...current,
      viewerUserId: sessionUserId,
    }));

    setIsLoadingFeed(true);
    setStatus(`${viewerStatus} Kept create author as-is. Reloading private friend feed...`);

    try {
      const nextItems = await listPrivateFeed(sessionUserId);
      setFeedItems(nextItems);
      setFeedVisibilityGateSnapshotSource("reload_flow");
      const gateSummary = buildFeedVisibilityGateSummary(sessionUserId, nextItems, "reload_flow").summaryLine;
      setStatus(
        `${viewerStatus} Kept create author as-is. Loaded ${nextItems.length} private feed moment(s) for viewer ${sessionUserId}. Gate summary: ${gateSummary}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "private_feed_failed");
    }

    setIsLoadingFeed(false);
  }

  async function copyToClipboard(
    text: string,
    statusPrefix: string,
    emptyCode: string,
    failedCode: string,
    onCopied?: (normalizedText: string) => void,
    successSource?: DeleteSummaryCopySource,
  ) {
    const normalizedText = text.trim();
    if (!normalizedText) {
      setStatus(emptyCode);
      return;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      return;
    }

    try {
      await navigator.clipboard.writeText(normalizedText);
      onCopied?.(normalizedText);
      if (successSource) {
        const deleteCopyAuditLine = buildDeleteCopyAuditLine(successSource, normalizedText);
        setLastDeleteCopyAuditLine(deleteCopyAuditLine);
        setDeleteCopyAuditSourceDraft(successSource);
        setStatus(`${statusPrefix} (delete_summary_copy_source=${successSource} / ${normalizedText}).`);
      } else {
        setStatus(`${statusPrefix} (${normalizedText}).`);
      }
    } catch {
      setStatus(failedCode);
    }
  }

  async function handleCopyQuickFeedVisibilityDelta() {
    await copyToClipboard(
      quickFeedVisibilityDeltaLine,
      "Copied quick feed-visibility delta to clipboard",
      "quick_feed_visibility_delta_empty",
      "quick_feed_visibility_delta_copy_failed",
      setLastCopiedFeedVisibilityDeltaLine,
    );
  }

  async function handleCopyQuickFeedVisibilityGateSummary() {
    await copyToClipboard(
      quickFeedVisibilityGateSummaryLine,
      "Copied quick feed-visibility gate summary to clipboard",
      "quick_feed_visibility_gate_summary_empty",
      "quick_feed_visibility_gate_summary_copy_failed",
      setLastCopiedFeedVisibilityDeltaLine,
    );
  }

  async function handleCopyQuickCreateFeedGateBundle() {
    await copyToClipboard(
      quickCreateFeedGateBundleLine,
      "Copied quick create + feed-gate bundle to clipboard",
      "quick_create_feed_gate_bundle_empty",
      "quick_create_feed_gate_bundle_copy_failed",
      setLastCopiedCreateFeedGateBundleLine,
    );
  }

  async function handleCopyLastCreateFeedVisibilityDelta() {
    await copyToClipboard(
      lastCreateFeedVisibilityDeltaLine ?? "",
      "Copied last create feed-visibility delta to clipboard",
      "last_create_feed_visibility_delta_missing",
      "last_create_feed_visibility_delta_copy_failed",
      setLastCopiedFeedVisibilityDeltaLine,
    );
  }

  async function handleCopyLastCreateFeedGateBundle() {
    await copyToClipboard(
      lastCreateFeedGateBundleLine,
      "Copied last create + feed-gate bundle to clipboard",
      "last_create_feed_gate_bundle_missing",
      "last_create_feed_gate_bundle_copy_failed",
      setLastCopiedLastCreateFeedGateBundleLine,
    );
  }

  async function handleCopyQuickDeleteParitySummary() {
    await copyToClipboard(
      deleteMomentQuickCopyLine,
      "Copied quick delete parity summary to clipboard",
      "quick_delete_parity_summary_empty",
      "quick_delete_parity_summary_copy_failed",
      setLastCopiedDeleteSummaryLine,
      "quick_delete_parity",
    );
  }

  async function handleCopyLastDeleteFeedGateBundle() {
    await copyToClipboard(
      lastDeleteFeedGateBundleLine,
      "Copied last delete + feed-gate bundle to clipboard",
      "last_delete_feed_gate_bundle_missing",
      "last_delete_feed_gate_bundle_copy_failed",
      setLastCopiedLastDeleteFeedGateBundleLine,
    );
  }

  async function handleCopyLastDeleteResultSummary() {
    await copyToClipboard(
      lastDeletedMomentSummaryLine ?? "",
      "Copied last delete result summary to clipboard",
      "last_delete_result_summary_missing",
      "last_delete_result_summary_copy_failed",
      setLastCopiedDeleteSummaryLine,
      "last_delete_result",
    );
  }

  async function handleCopyLastCopiedDeleteSummaryFeedback() {
    await copyToClipboard(
      lastCopiedDeleteSummaryFeedbackLine,
      "Copied last copied delete summary feedback to clipboard",
      "last_copied_delete_summary_missing",
      "last_copied_delete_summary_copy_failed",
      undefined,
      "copied_feedback",
    );
  }

  async function handleCopyDeleteCopyAuditLine() {
    await copyToClipboard(
      lastDeleteCopyAuditLine ?? "",
      "Copied delete copy audit line to clipboard",
      "delete_copy_audit_missing",
      "delete_copy_audit_copy_failed",
    );
  }

  async function handleCopyDeleteCopyAuditSourceStateLine() {
    await copyToClipboard(
      deleteCopyAuditSourceStateLine,
      "Copied delete copy audit source-state line to clipboard",
      "delete_copy_audit_source_state_missing",
      "delete_copy_audit_source_state_copy_failed",
    );
  }

  async function handleCopyDeleteCopyAuditFirstReadySourceLine() {
    await copyToClipboard(
      lastDeleteCopyAuditFirstReadySourceLine ?? "",
      "Copied delete copy audit first-ready source line to clipboard",
      "delete_copy_audit_first_ready_source_line_missing",
      "delete_copy_audit_first_ready_source_line_copy_failed",
    );
  }

  async function handleCopyDeleteCopyAuditSourceStateSnapshotLine() {
    await copyToClipboard(
      deleteCopyAuditSourceStateLine,
      "Copied delete copy audit source-state snapshot line to clipboard",
      "delete_copy_audit_source_state_missing",
      "delete_copy_audit_source_state_snapshot_copy_failed",
      (normalizedText) => {
        setLastDeleteCopyAuditSourceStateSnapshotLine(`last_source_state_snapshot=${normalizedText}`);
        setLastDeleteCopyAuditSourceStateSnapshotSourceLine(
          "last_source_state_snapshot_source=source_state_snapshot_copy",
        );
      },
    );
  }

  async function handleCopyLastDeleteCopyAuditSourceStateSnapshotLine() {
    await copyToClipboard(
      lastDeleteCopyAuditSourceStateSnapshotLine ?? "",
      "Copied last source-state snapshot line to clipboard",
      "delete_copy_audit_source_state_snapshot_line_missing",
      "delete_copy_audit_source_state_snapshot_line_copy_failed",
      () => {
        setLastDeleteCopyAuditSourceStateSnapshotSourceLine("last_source_state_snapshot_source=manual_recopy");
      },
    );
  }

  async function handleCopyLastDeleteCopyAuditSourceStateSnapshotSourceLine() {
    await copyToClipboard(
      lastDeleteCopyAuditSourceStateSnapshotSourceLine ?? "",
      "Copied last source-state snapshot source line to clipboard / last_source_state_snapshot_source_line_copied",
      "delete_copy_audit_source_state_snapshot_source_line_missing",
      "delete_copy_audit_source_state_snapshot_source_line_copy_failed",
    );
  }

  async function handleCopyDeleteCopyAuditFirstReadySource() {
    const firstReadySource = deleteSummaryCopySources.find(
      (source) => resolveDeleteCopyAuditSourceValue(source).trim().length > 0,
    );
    if (!firstReadySource) {
      const sourceLine = buildDeleteCopyAuditFirstReadySourceLine("none");
      setLastDeleteCopyAuditFirstReadySourceLine(sourceLine);
      setStatus(`${sourceLine} / delete_copy_audit_first_ready_source_missing`);
      return;
    }

    const sourceLine = buildDeleteCopyAuditFirstReadySourceLine(firstReadySource);
    setLastDeleteCopyAuditFirstReadySourceLine(sourceLine);
    await handleCopyDeleteCopyAuditSourceValue(firstReadySource);
    setStatus((currentStatus) => `${currentStatus} / ${sourceLine}`);
  }

  async function handleCopyDeleteCopyAuditSourceValue(source: DeleteSummaryCopySource) {
    const sourceValue = resolveDeleteCopyAuditSourceValue(source);
    const normalizedSourceValue = sourceValue.trim();
    if (!normalizedSourceValue) {
      setStatus(`delete_copy_audit_source_value_missing:${source}`);
      return;
    }

    const auditLine = buildDeleteCopyAuditLine(source, normalizedSourceValue);
    setDeleteCopyAuditSourceDraft(source);
    setLastDeleteCopyAuditLine(auditLine);

    await copyToClipboard(
      auditLine,
      "Copied delete copy audit line to clipboard",
      "delete_copy_audit_missing",
      "delete_copy_audit_copy_failed",
    );
  }

  async function handleCopyQuickReactionSummary() {
    await copyToClipboard(
      quickReactionSummaryLine,
      "Copied quick reaction summary to clipboard",
      "quick_reaction_summary_empty",
      "quick_reaction_summary_copy_failed",
      (normalizedText) => {
        setLastReactionQuickCopyLine(normalizedText);
        setLastReactionQuickCopySource("list_reactions");
      },
    );
  }

  async function handleCopyLastReactionQuickSummaryFeedback() {
    await copyToClipboard(
      lastReactionQuickCopyFeedbackLine,
      "Copied last reaction quick summary feedback to clipboard",
      "last_reaction_quick_summary_feedback_missing",
      "last_reaction_quick_summary_feedback_copy_failed",
    );
  }

  async function handleUseCurrentSessionUserAsReactionUser() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_reaction_user_missing_for_quick_apply");
      return;
    }

    setReactionUserIdDraft(sessionUserId);
    setStatus("Applied current session user as reaction user (reaction_user_source=session_user).");
  }

  async function handleCreateReaction() {
    const trimmedMomentId = reactionMomentIdDraft.trim();
    const trimmedUserId = reactionUserIdDraft.trim();
    const trimmedReactionType = reactionTypeDraft.trim();

    if (!trimmedMomentId) {
      setStatus("moment_reaction_target_required");
      return;
    }

    if (!trimmedUserId) {
      setStatus("moment_reaction_user_required");
      return;
    }

    if (!trimmedReactionType) {
      setStatus("moment_reaction_type_required");
      return;
    }

    setIsCreatingReaction(true);
    setStatus(`Creating reaction \"${trimmedReactionType}\" on moment ${trimmedMomentId}...`);

    try {
      const createdReaction = await createMomentReaction({
        momentId: trimmedMomentId,
        userId: trimmedUserId,
        reactionType: trimmedReactionType,
      });

      setReactionMomentIdDraft(createdReaction.moment_id);
      setReactionUserIdDraft(createdReaction.user_id);
      setReactionTypeDraft(createdReaction.reaction_type);

      const loadedReactions = await listMomentReactions(createdReaction.moment_id);
      setReactionItems(loadedReactions);

      const reactionSummaryLine =
        `reaction_target_moment_id=${createdReaction.moment_id}` +
        ` / reaction_user_id=${createdReaction.user_id}` +
        ` / reaction_type=${createdReaction.reaction_type}` +
        ` / loaded_reaction_count=${loadedReactions.length}`;

      setLastReactionQuickCopyLine(reactionSummaryLine);
      setLastReactionQuickCopySource("create_reaction");
      setStatus(
        `Created moment reaction ${createdReaction.id}. Reloaded ${loadedReactions.length} reaction(s). Quick summary: ${reactionSummaryLine}.`,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_reaction_create_failed");
    }

    setIsCreatingReaction(false);
  }

  async function handleLoadReactions() {
    const trimmedMomentId = reactionMomentIdDraft.trim();
    if (!trimmedMomentId) {
      setStatus("moment_reaction_target_required");
      return;
    }

    setIsLoadingReactions(true);
    setStatus(`Loading reactions for moment ${trimmedMomentId}...`);

    try {
      const loadedReactions = await listMomentReactions(trimmedMomentId);
      setReactionItems(loadedReactions);
      const reactionSummaryLine =
        `reaction_target_moment_id=${trimmedMomentId}` +
        ` / reaction_user_id=${reactionUserIdDraft.trim() || "(empty)"}` +
        ` / reaction_type=${reactionTypeDraft.trim() || "(empty)"}` +
        ` / loaded_reaction_count=${loadedReactions.length}`;
      setLastReactionQuickCopyLine(reactionSummaryLine);
      setLastReactionQuickCopySource("list_reactions");
      setStatus(`Loaded ${loadedReactions.length} reaction(s) for moment ${trimmedMomentId}. Quick summary: ${reactionSummaryLine}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_reaction_list_failed");
    }

    setIsLoadingReactions(false);
  }

  async function submitMomentCreateFlow(
    authorUserId: string,
    sourceStatusPrefix?: string,
    viewerUserIdOverride?: string,
  ) {
    const composeStatus = (message: string) =>
      sourceStatusPrefix ? `${sourceStatusPrefix} ${message}` : message;

    setIsSubmitting(true);
    setStatus(composeStatus("Creating moment + image shell..."));

    try {
      const created = await createMomentWithImage({
        authorUserId,
        captionText: form.captionText.trim(),
        imageStorageKey: form.imageStorageKey.trim(),
        imageMimeType: form.imageMimeType.trim(),
        imageWidth: Number(form.imageWidth),
        imageHeight: Number(form.imageHeight),
      });
      setItems((current) => [created, ...current.filter((item) => item.id !== created.id)]);

      const viewerUserId = viewerUserIdOverride?.trim() ?? form.viewerUserId.trim();
      if (!viewerUserId) {
        const deltaLine = `created_moment_id=${created.id} / viewer=(empty) / feed_count=(not_loaded) / first_moment_id=(not_loaded)`;
        setLastCreateFeedVisibilityDeltaLine(deltaLine);
        setFeedVisibilityGateSnapshotSource("create_flow");
        const gateSummary = buildFeedVisibilityGateSummary("", [], "create_flow");
        setLastCreateFeedGateSummaryLine(gateSummary.summaryLine);
        setStatus(
          composeStatus(
            `Created moment ${created.id} with ${created.media_items.length} image item(s). ` +
              "Set feed viewer UUID, then reload private friend feed to verify visibility delta. " +
              `Gate summary: ${gateSummary.summaryLine}.`,
          ),
        );
      } else {
        try {
          const nextFeedItems = await listPrivateFeed(viewerUserId);
          setFeedItems(nextFeedItems);

          const firstMomentId = nextFeedItems[0]?.id ?? "(none)";
          const deltaLine =
            `created_moment_id=${created.id} / viewer=${viewerUserId} / ` +
            `feed_count=${nextFeedItems.length} / first_moment_id=${firstMomentId}`;
          setLastCreateFeedVisibilityDeltaLine(deltaLine);

          setFeedVisibilityGateSnapshotSource("create_flow");
          const gateSummary = buildFeedVisibilityGateSummary(viewerUserId, nextFeedItems, "create_flow").summaryLine;
          setLastCreateFeedGateSummaryLine(gateSummary);
          setStatus(
            composeStatus(
              `Created moment ${created.id} with ${created.media_items.length} image item(s). ` +
                `Feed visibility delta: viewer=${viewerUserId} / feed_count=${nextFeedItems.length} / first_moment_id=${firstMomentId}. ` +
                `Feed visibility gate summary: ${gateSummary}.`,
            ),
          );
        } catch (error) {
          const deltaLine =
            `created_moment_id=${created.id} / viewer=${viewerUserId} / ` +
            "feed_count=(feed_reload_failed) / first_moment_id=(feed_reload_failed)";
          const failedGateSummary =
            "viewer_access=unknown / viewer_access_reason=feed_reload_failed / gate_snapshot_source=create_flow / visible_count=(unknown) / first_moment_id=(unknown)";
          setLastCreateFeedVisibilityDeltaLine(deltaLine);
          setLastCreateFeedGateSummaryLine(failedGateSummary);
          const fallbackStatus = error instanceof Error ? error.message : "private_feed_failed_after_moment_create";
          setStatus(composeStatus(fallbackStatus));
        }
      }
    } catch (error) {
      const fallbackStatus = error instanceof Error ? error.message : "moment_shell_create_failed";
      setStatus(composeStatus(fallbackStatus));
    }

    setIsSubmitting(false);
  }

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await submitMomentCreateFlow(form.authorUserId.trim());
  }

  async function handleReload() {
    setIsLoadingList(true);
    setStatus("Reloading authored moments...");

    try {
      const nextItems = await listMomentsForAuthor(form.authorUserId.trim());
      setItems(nextItems);
      setStatus(`Loaded ${nextItems.length} authored moment(s) for ${form.authorUserId.trim() || "unknown-user"}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_shell_list_failed");
    }

    setIsLoadingList(false);
  }

  function buildDeleteMomentSummary(deleted: MomentDeleteResult) {
    const normalizedDeletedAt = deleted.deleted_at ?? "(none)";
    const authorMatchCount = items.filter((item) => item.author.id === deleted.author_user_id).length;
    const feedMatchCount = feedItems.filter((item) => item.id === deleted.id).length;

    return (
      `delete_result=deleted` +
      ` / moment_id=${deleted.id}` +
      ` / author_user_id=${deleted.author_user_id}` +
      ` / deleted_at=${normalizedDeletedAt}` +
      ` / author_loaded_count=${authorMatchCount}` +
      ` / feed_match_count=${feedMatchCount}`
    );
  }

  async function handleDeleteMoment() {
    const normalizedDeleteMomentId = deleteMomentIdDraft.trim();
    if (!normalizedDeleteMomentId) {
      setStatus("delete_moment_id_required");
      return;
    }

    setIsDeleting(true);
    setStatus(`Deleting moment ${normalizedDeleteMomentId}...`);

    try {
      const deleted = await deleteMoment(normalizedDeleteMomentId);
      const deletedSummary = buildDeleteMomentSummary(deleted);
      const nextFeedItems = feedItems.filter((item) => item.id !== deleted.id);
      const deleteGateSummary = buildFeedVisibilityGateSummary(form.viewerUserId.trim(), nextFeedItems, "delete_flow").summaryLine;

      setDeleteMomentIdDraft(deleted.id);
      if (reactionMomentIdDraft.trim() === deleted.id) {
        setReactionMomentIdDraft("");
        setReactionItems([]);
      }
      setDeleteSnapshotSource("manual_input");
      setFeedVisibilityGateSnapshotSource("delete_flow");
      setLastDeletedMomentSummaryLine(deletedSummary);
      setItems((current) => current.filter((item) => item.id !== deleted.id));
      setFeedItems(nextFeedItems);

      setStatus(`Deleted moment ${deleted.id}. ${deletedSummary}. Feed visibility gate summary: ${deleteGateSummary}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_shell_delete_failed");
    }

    setIsDeleting(false);
  }

  async function handleReloadFeed() {
    setIsLoadingFeed(true);
    setStatus("Reloading private friend feed...");

    try {
      const normalizedViewerUserId = form.viewerUserId.trim();
      const nextItems = await listPrivateFeed(normalizedViewerUserId);
      setFeedItems(nextItems);
      setFeedVisibilityGateSnapshotSource("reload_flow");
      const gateSummary = buildFeedVisibilityGateSummary(normalizedViewerUserId, nextItems, "reload_flow").summaryLine;
      setStatus(`Loaded ${nextItems.length} private feed moment(s) for viewer ${normalizedViewerUserId || "unknown-user"}. Gate summary: ${gateSummary}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "private_feed_failed");
    }

    setIsLoadingFeed(false);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> moment posting shell now wires caption + image metadata + reaction create/list to backend contracts.
      </p>
      <p>{status}</p>
      <p>
        Quick copy payload: <code>{momentPayloadQuickCopy}</code>
      </p>
      <p>
        Quick feed-visibility delta: <code>{quickFeedVisibilityDeltaLine}</code>
      </p>
      <p>
        Quick feed visibility gate summary: <code>{quickFeedVisibilityGateSummaryLine}</code>
      </p>
      <p>
        Quick create + feed-gate bundle: <code>{quickCreateFeedGateBundleLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickFeedVisibilityDelta()}>
          Copy quick feed-visibility delta
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickFeedVisibilityGateSummary()}>
          Copy quick feed visibility gate summary
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickCreateFeedGateBundle()}>
          Copy quick create + feed-gate bundle
        </button>
      </p>
      {lastCreateFeedVisibilityDeltaLine ? (
        <>
          <p>
            Last create feed-visibility delta: <code>{lastCreateFeedVisibilityDeltaLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyLastCreateFeedVisibilityDelta()}>
              Copy last create feed-visibility delta
            </button>
          </p>
          {lastCreateFeedGateBundleLine ? (
            <>
              <p>
                Last create + feed-gate bundle: <code>{lastCreateFeedGateBundleLine}</code>
              </p>
              <p>
                <button type="button" onClick={() => void handleCopyLastCreateFeedGateBundle()}>
                  Copy last create + feed-gate bundle
                </button>
              </p>
            </>
          ) : null}
        </>
      ) : null}
      <p>
        Quick delete parity summary: <code>{deleteMomentQuickCopyLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickDeleteParitySummary()}>
          Copy quick delete parity summary
        </button>
      </p>
      {lastDeletedMomentSummaryLine ? (
        <>
          <p>
            Last delete result summary: <code>{lastDeletedMomentSummaryLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyLastDeleteResultSummary()}>
              Copy last delete result summary
            </button>
          </p>
          <p>
            Last delete + feed-gate bundle: <code>{lastDeleteFeedGateBundleLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyLastDeleteFeedGateBundle()}>
              Copy last delete + feed-gate bundle
            </button>
          </p>
        </>
      ) : null}
      {lastCopiedFeedVisibilityDeltaLine ? (
        <p>
          Last copied feed delta: <code>{lastCopiedFeedVisibilityDeltaLine}</code>
        </p>
      ) : null}
      {lastCopiedCreateFeedGateBundleLine ? (
        <p>
          Last copied create + feed-gate bundle: <code>{lastCopiedCreateFeedGateBundleLine}</code>
        </p>
      ) : null}
      {lastCopiedLastCreateFeedGateBundleLine ? (
        <p>
          Last copied last create + feed-gate bundle: <code>{lastCopiedLastCreateFeedGateBundleLine}</code>
        </p>
      ) : null}
      {lastCopiedLastDeleteFeedGateBundleLine ? (
        <p>
          Last copied last delete + feed-gate bundle: <code>{lastCopiedLastDeleteFeedGateBundleLine}</code>
        </p>
      ) : null}
      {lastCopiedDeleteSummaryLine ? (
        <>
          <p>
            Last copied delete summary: <code>{lastCopiedDeleteSummaryLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyLastCopiedDeleteSummaryFeedback()}>
              Copy last copied delete summary feedback
            </button>
          </p>
        </>
      ) : null}
      <p>
        Delete copy audit source-state: <code>{deleteCopyAuditSourceStateLine}</code>
      </p>
      <p>
        Delete copy audit first-ready source:{" "}
        <code>{lastDeleteCopyAuditFirstReadySourceLine ?? "delete_copy_audit_first_ready_source=(not_run)"}</code>
      </p>
      <p>
        Last source-state snapshot:{" "}
        <code>{lastDeleteCopyAuditSourceStateSnapshotLine ?? "last_source_state_snapshot=(not_run)"}</code>
      </p>
      <p>
        Last source-state snapshot source:{" "}
        <code>{lastDeleteCopyAuditSourceStateSnapshotSourceLine ?? "last_source_state_snapshot_source=(not_run)"}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyDeleteCopyAuditSourceStateLine()}>
          Copy delete copy audit source-state line
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyDeleteCopyAuditSourceStateSnapshotLine()}>
          Copy delete copy audit source-state snapshot line
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyLastDeleteCopyAuditSourceStateSnapshotLine()}>
          Copy last source-state snapshot line
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyLastDeleteCopyAuditSourceStateSnapshotSourceLine()}>
          Copy last source-state snapshot source line
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyDeleteCopyAuditFirstReadySourceLine()}>
          Copy delete copy audit first-ready source line
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyDeleteCopyAuditFirstReadySource()}>
          Copy delete copy audit for first ready source
        </button>
      </p>
      <p>
        Delete copy audit source:
        {" "}
        {deleteSummaryCopySources.map((source) => {
          const isActiveSource = deleteCopyAuditSourceDraft === source;
          return (
            <button
              key={source}
              type="button"
              onClick={() => void handleCopyDeleteCopyAuditSourceValue(source)}
              style={{
                marginLeft: 8,
                padding: "2px 8px",
                borderRadius: 999,
                border: "1px solid",
                borderColor: isActiveSource ? "currentColor" : "#c7c7c7",
                background: isActiveSource ? "#f4f4f5" : "transparent",
              }}
            >
              {source}
            </button>
          );
        })}
      </p>
      {lastDeleteCopyAuditLine ? (
        <>
          <p>
            Delete copy audit: <code>{lastDeleteCopyAuditLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyDeleteCopyAuditLine()}>
              Copy delete copy audit line
            </button>
          </p>
        </>
      ) : null}

      <p>
        Quick reaction summary: <code>{quickReactionSummaryLine}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickReactionSummary()}>
          Copy quick reaction summary
        </button>
      </p>
      {lastReactionQuickCopyLine ? (
        <>
          <p>
            Last reaction quick summary ({lastReactionQuickCopySource ?? "unknown"}): <code>{lastReactionQuickCopyLine}</code>
          </p>
          <p>
            <button type="button" onClick={() => void handleCopyLastReactionQuickSummaryFeedback()}>
              Copy last reaction quick summary feedback
            </button>
          </p>
        </>
      ) : null}

      <form onSubmit={(event) => void handleCreate(event)}>
        <label>
          Author user UUID
          <input
            value={form.authorUserId}
            onChange={(event) => setForm((current) => ({ ...current, authorUserId: event.target.value }))}
            placeholder="paste registered user uuid"
          />
        </label>
        <button type="button" onClick={applyCurrentSessionUserAsAuthor} disabled={currentSessionUserId.trim().length === 0 || isSubmitting}>
          Use current session user as create author
        </button>
        <button
          type="button"
          onClick={() => void handleApplyCurrentSessionUserAsAuthorCreateAndReloadFeed()}
          disabled={currentSessionUserId.trim().length === 0 || isSubmitting || isDeleting || isLoadingFeed}
        >
          Use current session user as author + create moment + reload feed
        </button>
        <button
          type="button"
          onClick={() => void handleApplyCurrentSessionUserAsViewerAuthorCreateAndReloadFeed()}
          disabled={currentSessionUserId.trim().length === 0 || isSubmitting || isDeleting || isLoadingFeed}
        >
          Use current session user as viewer + author + create moment + reload feed
        </button>
        <label>
          Feed viewer UUID
          <input
            value={form.viewerUserId}
            onChange={(event) => setForm((current) => ({ ...current, viewerUserId: event.target.value }))}
            placeholder="paste viewer uuid to load private feed"
          />
        </label>
        <label>
          Caption
          <textarea
            value={form.captionText}
            onChange={(event) => setForm((current) => ({ ...current, captionText: event.target.value }))}
            placeholder="Quick moment caption"
          />
        </label>
        <label>
          Image storage key
          <input
            value={form.imageStorageKey}
            onChange={(event) => setForm((current) => ({ ...current, imageStorageKey: event.target.value }))}
          />
        </label>
        <label>
          Image MIME type
          <input
            value={form.imageMimeType}
            onChange={(event) => setForm((current) => ({ ...current, imageMimeType: event.target.value }))}
          />
        </label>
        <label>
          Width
          <input
            value={form.imageWidth}
            onChange={(event) => setForm((current) => ({ ...current, imageWidth: event.target.value }))}
          />
        </label>
        <label>
          Height
          <input
            value={form.imageHeight}
            onChange={(event) => setForm((current) => ({ ...current, imageHeight: event.target.value }))}
          />
        </label>
        <button type="submit" disabled={isSubmitting || isDeleting}>
          {isSubmitting ? "Creating..." : "Create moment + image shell"}
        </button>
        <button type="button" onClick={() => void handleReload()} disabled={isLoadingList || isDeleting}>
          {isLoadingList ? "Reloading..." : "Reload authored moments"}
        </button>
        <button
          type="button"
          onClick={() => void applyCurrentSessionUserAsViewerKeepAuthorAndLoadPrivateFeed()}
          disabled={isLoadingFeed || currentSessionUserId.trim().length === 0}
        >
          Use current session user as viewer + keep author + load private feed
        </button>
        <button type="button" onClick={() => void handleReloadFeed()} disabled={isLoadingFeed || isDeleting}>
          {isLoadingFeed ? "Reloading feed..." : "Reload private friend feed"}
        </button>
        <label>
          Moment ID to delete
          <input
            value={deleteMomentIdDraft}
            onChange={(event) => {
              setDeleteMomentIdDraft(event.target.value);
              setDeleteSnapshotSource("manual_input");
            }}
            placeholder="paste moment id for DELETE /moments/{id}"
          />
        </label>
        <button type="button" onClick={() => void handleDeleteMoment()} disabled={isDeleting || deleteMomentId.length === 0}>
          {isDeleting ? "Deleting moment..." : "Delete moment (web parity)"}
        </button>

        <label>
          Reaction target moment UUID
          <input
            value={reactionMomentIdDraft}
            onChange={(event) => setReactionMomentIdDraft(event.target.value)}
            placeholder="paste moment id for /moments/{id}/reactions"
          />
        </label>
        <label>
          Reaction user UUID
          <input
            value={reactionUserIdDraft}
            onChange={(event) => setReactionUserIdDraft(event.target.value)}
            placeholder="paste user uuid for reaction actor"
          />
        </label>
        <button
          type="button"
          onClick={() => void handleUseCurrentSessionUserAsReactionUser()}
          disabled={currentSessionUserId.trim().length === 0 || isCreatingReaction || isLoadingReactions}
        >
          Use current session user for reaction user
        </button>
        <label>
          Reaction type
          <input
            value={reactionTypeDraft}
            onChange={(event) => setReactionTypeDraft(event.target.value)}
            placeholder="heart"
          />
        </label>
        <button
          type="button"
          onClick={() => void handleCreateReaction()}
          disabled={isCreatingReaction || isLoadingReactions || reactionMomentId.length === 0 || reactionUserId.length === 0 || reactionType.length === 0}
        >
          {isCreatingReaction ? "Creating reaction..." : "Create reaction"}
        </button>
        <button
          type="button"
          onClick={() => void handleLoadReactions()}
          disabled={isCreatingReaction || isLoadingReactions || reactionMomentId.length === 0}
        >
          {isLoadingReactions ? "Loading reactions..." : "Load reactions"}
        </button>
      </form>

      <h2>Authored moments</h2>
      {items.length === 0 ? (
        <p>No moments loaded yet.</p>
      ) : (
        <>
          <p>
            <button
              type="button"
              onClick={() => {
                setDeleteMomentIdDraft(items[0]?.id ?? "");
                setDeleteSnapshotSource("first_authored_quick_pick");
              }}
              disabled={!items[0] || isDeleting}
            >
              Use first authored moment as delete target
            </button>
            <button
              type="button"
              onClick={() => {
                setReactionMomentIdDraft(items[0]?.id ?? "");
                setStatus("Applied first authored moment as reaction target (reaction_target_source=first_authored_quick_pick).");
              }}
              disabled={!items[0] || isCreatingReaction || isLoadingReactions}
            >
              Use first authored moment as reaction target
            </button>
          </p>
          <ul>
            {items.map((item) => (
              <li key={item.id}>
                <strong>{item.caption_text ?? "(no caption)"}</strong>
                {" · author: "}
                {item.author.username ?? item.author.email}
                {" · media: "}
                {item.media_items.length}
                {item.media_items[0] ? ` · first image: ${item.media_items[0].storage_key}` : ""}
              </li>
            ))}
          </ul>
        </>
      )}

      <h2>Private friend feed</h2>
      {feedItems.length === 0 ? (
        <p>No private feed moments loaded yet.</p>
      ) : (
        <ul>
          {feedItems.map((item) => (
            <li key={item.id}>
              <strong>{item.caption_text ?? "(no caption)"}</strong>
              {" · friend author: "}
              {item.author.username ?? item.author.email}
              {" · media: "}
              {item.media_items.length}
              {item.media_items[0] ? ` · first image: ${item.media_items[0].storage_key}` : ""}
            </li>
          ))}
        </ul>
      )}

      <h2>Moment reactions</h2>
      {reactionItems.length === 0 ? (
        <p>No reactions loaded for this moment yet.</p>
      ) : (
        <ul>
          {reactionItems.map((reaction) => (
            <li key={reaction.id}>
              <strong>{reaction.reaction_type}</strong>
              {" · user: "}
              {reaction.user_id}
              {" · reaction_id: "}
              {reaction.id}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
