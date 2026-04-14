"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import { createMomentWithImage, listMomentsForAuthor, listPrivateFeed, type MomentListItem } from "@/lib/moments/client";

type MomentComposeShellProps = {
  initialAuthorUserId?: string;
  initialViewerUserId?: string;
};

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
  const [isLoadingList, setIsLoadingList] = useState(false);
  const [isLoadingFeed, setIsLoadingFeed] = useState(false);
  const [items, setItems] = useState<MomentListItem[]>([]);
  const [feedItems, setFeedItems] = useState<MomentListItem[]>([]);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");
  const momentPayloadQuickCopy = `author=${form.authorUserId.trim() || "(empty)"} | image_url=${form.imageStorageKey.trim() || "(empty)"} | caption=${form.captionText.trim() || "(empty)"}`;
  const privateFeedQuickCopy = `viewer=${form.viewerUserId.trim() || "(empty)"} | feed_count=${feedItems.length} | first_moment_id=${feedItems[0]?.id ?? "(none)"}`;

  useEffect(() => {
    setForm((current) => ({
      ...current,
      authorUserId: initialAuthorUserId,
      viewerUserId: initialViewerUserId,
    }));
    setItems([]);
    setFeedItems([]);
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
      setStatus(`Created moment ${created.id} with ${created.media_items.length} image item(s).`);
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

  async function handleReloadFeed() {
    setIsLoadingFeed(true);
    setStatus("Reloading private friend feed...");

    try {
      const nextItems = await listPrivateFeed(form.viewerUserId.trim());
      setFeedItems(nextItems);
      setStatus(`Loaded ${nextItems.length} private feed moment(s) for viewer ${form.viewerUserId.trim() || "unknown-user"}.`);
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
        Quick copy feed: <code>{privateFeedQuickCopy}</code>
      </p>

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
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Creating..." : "Create moment + image shell"}
        </button>
        <button type="button" onClick={() => void handleReload()} disabled={isLoadingList}>
          {isLoadingList ? "Reloading..." : "Reload authored moments"}
        </button>
        <button type="button" onClick={() => void handleReloadFeed()} disabled={isLoadingFeed}>
          {isLoadingFeed ? "Reloading feed..." : "Reload private friend feed"}
        </button>
      </form>

      <h2>Authored moments</h2>
      {items.length === 0 ? (
        <p>No moments loaded yet.</p>
      ) : (
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
