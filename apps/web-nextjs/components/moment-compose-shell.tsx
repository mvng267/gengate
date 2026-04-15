"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createMomentWithImage,
  deleteMoment,
  listMomentsForAuthor,
  listPrivateFeed,
  type MomentDeleteResult,
  type MomentListItem,
} from "@/lib/moments/client";
type MomentComposeShellProps = {
  initialAuthorUserId?: string;
  initialViewerUserId?: string;
};

type FeedGateSnapshotSource = "create_flow" | "reload_flow";
type DeleteSnapshotSource = "manual_input" | "preset_row" | "first_authored_quick_pick";

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
  const [items, setItems] = useState<MomentListItem[]>([]);
  const [feedItems, setFeedItems] = useState<MomentListItem[]>([]);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const [lastCreateFeedVisibilityDeltaLine, setLastCreateFeedVisibilityDeltaLine] = useState<string | null>(null);
  const [lastDeletedMomentSummaryLine, setLastDeletedMomentSummaryLine] = useState<string | null>(null);
  const [deleteMomentIdDraft, setDeleteMomentIdDraft] = useState("");
  const [lastCopiedFeedVisibilityDeltaLine, setLastCopiedFeedVisibilityDeltaLine] = useState<string | null>(null);
  const [lastCopiedDeleteSummaryLine, setLastCopiedDeleteSummaryLine] = useState<string | null>(null);
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
  const quickFeedVisibilityGateSummaryLine = quickFeedVisibilityGate.summaryLine;
  const deleteMomentQuickCopyLine =
    `delete_moment_id=${deleteMomentId || "(empty)"}` +
    ` / authored_count=${items.length}` +
    ` / feed_count=${feedItems.length}` +
    ` / gate_snapshot_source=${feedVisibilityGateSnapshotSource}` +
    ` / delete_snapshot_source=${deleteSnapshotSource}`;

  useEffect(() => {
    setForm((current) => ({
      ...current,
      authorUserId: initialAuthorUserId,
      viewerUserId: initialViewerUserId,
    }));
    setItems([]);
    setFeedItems([]);
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

  async function applyCurrentSessionUserAsViewerAndLoad() {
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
    setStatus(`${viewerStatus} Reloading private friend feed...`);

    try {
      const nextItems = await listPrivateFeed(sessionUserId);
      setFeedItems(nextItems);
      setFeedVisibilityGateSnapshotSource("reload_flow");
      const gateSummary = buildFeedVisibilityGateSummary(sessionUserId, nextItems, "reload_flow").summaryLine;
      setStatus(`${viewerStatus} Loaded ${nextItems.length} private feed moment(s) for viewer ${sessionUserId}. Gate summary: ${gateSummary}.`);
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
      setStatus(`${statusPrefix} (${normalizedText}).`);
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

  async function handleCopyLastCreateFeedVisibilityDelta() {
    await copyToClipboard(
      lastCreateFeedVisibilityDeltaLine ?? "",
      "Copied last create feed-visibility delta to clipboard",
      "last_create_feed_visibility_delta_missing",
      "last_create_feed_visibility_delta_copy_failed",
      setLastCopiedFeedVisibilityDeltaLine,
    );
  }

  async function handleCopyQuickDeleteParitySummary() {
    await copyToClipboard(
      deleteMomentQuickCopyLine,
      "Copied quick delete parity summary to clipboard",
      "quick_delete_parity_summary_empty",
      "quick_delete_parity_summary_copy_failed",
      setLastCopiedDeleteSummaryLine,
    );
  }

  async function handleCopyLastDeleteResultSummary() {
    await copyToClipboard(
      lastDeletedMomentSummaryLine ?? "",
      "Copied last delete result summary to clipboard",
      "last_delete_result_summary_missing",
      "last_delete_result_summary_copy_failed",
      setLastCopiedDeleteSummaryLine,
    );
  }

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setStatus("Creating moment + image shell...");

    try {
      const created = await createMomentWithImage({
        authorUserId: form.authorUserId.trim(),
        captionText: form.captionText.trim(),
        imageStorageKey: form.imageStorageKey.trim(),
        imageMimeType: form.imageMimeType.trim(),
        imageWidth: Number(form.imageWidth),
        imageHeight: Number(form.imageHeight),
      });
      setItems((current) => [created, ...current.filter((item) => item.id !== created.id)]);

      const viewerUserId = form.viewerUserId.trim();
      if (!viewerUserId) {
        const deltaLine = `created_moment_id=${created.id} / viewer=(empty) / feed_count=(not_loaded) / first_moment_id=(not_loaded)`;
        setLastCreateFeedVisibilityDeltaLine(deltaLine);
        setFeedVisibilityGateSnapshotSource("create_flow");
        const gateSummary = buildFeedVisibilityGateSummary("", [], "create_flow");
        setStatus(
          `Created moment ${created.id} with ${created.media_items.length} image item(s). ` +
            "Set feed viewer UUID, then reload private friend feed to verify visibility delta. " +
            `Gate summary: ${gateSummary.summaryLine}.`,
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
          setStatus(
            `Created moment ${created.id} with ${created.media_items.length} image item(s). ` +
              `Feed visibility delta: viewer=${viewerUserId} / feed_count=${nextFeedItems.length} / first_moment_id=${firstMomentId}. ` +
              `Feed visibility gate summary: ${gateSummary}.`,
          );
        } catch (error) {
          const deltaLine =
            `created_moment_id=${created.id} / viewer=${viewerUserId} / ` +
            "feed_count=(feed_reload_failed) / first_moment_id=(feed_reload_failed)";
          setLastCreateFeedVisibilityDeltaLine(deltaLine);
          setStatus(error instanceof Error ? error.message : "private_feed_failed_after_moment_create");
        }
      }
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_shell_create_failed");
    }

    setIsSubmitting(false);
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

      setDeleteMomentIdDraft(deleted.id);
      setDeleteSnapshotSource("manual_input");
      setLastDeletedMomentSummaryLine(deletedSummary);
      setItems((current) => current.filter((item) => item.id !== deleted.id));
      setFeedItems((current) => current.filter((item) => item.id !== deleted.id));

      setStatus(`Deleted moment ${deleted.id}. ${deletedSummary}.`);
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
        <strong>Status:</strong> moment posting shell now wires caption + image metadata to backend contracts.
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
        <button type="button" onClick={() => void handleCopyQuickFeedVisibilityDelta()}>
          Copy quick feed-visibility delta
        </button>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickFeedVisibilityGateSummary()}>
          Copy quick feed visibility gate summary
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
        </>
      ) : null}
      {lastCopiedFeedVisibilityDeltaLine ? (
        <p>
          Last copied feed delta: <code>{lastCopiedFeedVisibilityDeltaLine}</code>
        </p>
      ) : null}
      {lastCopiedDeleteSummaryLine ? (
        <p>
          Last copied delete summary: <code>{lastCopiedDeleteSummaryLine}</code>
        </p>
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
          onClick={() => void applyCurrentSessionUserAsViewerAndLoad()}
          disabled={isLoadingFeed || currentSessionUserId.trim().length === 0}
        >
          Use current session user as viewer + load
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
    </section>
  );
}
