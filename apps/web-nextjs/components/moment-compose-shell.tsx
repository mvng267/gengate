"use client";

import { useState } from "react";

import { createMomentWithImage, listMomentsForAuthor, type MomentListItem } from "@/lib/moments/client";

const initialForm = {
  authorUserId: "",
  captionText: "",
  imageStorageKey: "moments/demo-image.jpg",
  imageMimeType: "image/jpeg",
  imageWidth: "1080",
  imageHeight: "1350",
};

export function MomentComposeShell() {
  const [form, setForm] = useState(initialForm);
  const [status, setStatus] = useState("Provide a real user UUID, caption, and image storage key to test the moment shell.");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoadingList, setIsLoadingList] = useState(false);
  const [items, setItems] = useState<MomentListItem[]>([]);

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
      setStatus(`Loaded ${nextItems.length} moment(s) for ${form.authorUserId.trim() || "unknown-user"}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "moment_shell_list_failed");
    }

    setIsLoadingList(false);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> moment posting shell now wires caption + image metadata to backend contracts.
      </p>
      <p>{status}</p>

      <form onSubmit={(event) => void handleCreate(event)}>
        <label>
          Author user UUID
          <input
            value={form.authorUserId}
            onChange={(event) => setForm((current) => ({ ...current, authorUserId: event.target.value }))}
            placeholder="paste registered user uuid"
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
    </section>
  );
}
