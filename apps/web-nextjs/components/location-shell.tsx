"use client";

import { useEffect, useState } from "react";

import { readPersistedAuthSession } from "@/lib/auth/client";
import {
  createAudience,
  createShare,
  createSnapshot,
  getAudienceCount,
  getSnapshotCount,
  removeAudience,
  updateShare,
  type LocationShareItem,
} from "@/lib/location/client";

type LocationShellProps = {
  initialOwnerUserId?: string;
  initialAllowedUserId?: string;
  initialShareId?: string;
};

const initialForm = {
  ownerUserId: "",
  allowedUserId: "",
  sharingMode: "custom_list",
  lat: "10.7769",
  lng: "106.7009",
  accuracyMeters: "20",
};

export function LocationShell({
  initialOwnerUserId = "",
  initialAllowedUserId = "",
  initialShareId = "",
}: LocationShellProps) {
  const [form, setForm] = useState({
    ...initialForm,
    ownerUserId: initialOwnerUserId,
    allowedUserId: initialAllowedUserId,
  });
  const [share, setShare] = useState<LocationShareItem | null>(initialShareId ? {
    id: initialShareId,
    owner_user_id: initialOwnerUserId,
    sharing_mode: initialForm.sharingMode,
    is_active: true,
  } : null);
  const [audienceCount, setAudienceCount] = useState(0);
  const [snapshotCount, setSnapshotCount] = useState(0);
  const [status, setStatus] = useState(
    "Provide a real owner UUID to create/load a location sharing state shell. Optional friend UUID can be added to the allowed audience.",
  );
  const [isCreatingShare, setIsCreatingShare] = useState(false);
  const [isTogglingShare, setIsTogglingShare] = useState(false);
  const [isAddingAudience, setIsAddingAudience] = useState(false);
  const [isCreatingSnapshot, setIsCreatingSnapshot] = useState(false);
  const [isRemovingAudience, setIsRemovingAudience] = useState(false);
  const [isReloadingCounts, setIsReloadingCounts] = useState(false);
  const [lastCopiedLocationStateSummary, setLastCopiedLocationStateSummary] = useState<string | null>(null);
  const [lastRemovedAudienceId, setLastRemovedAudienceId] = useState<string | null>(null);
  const [currentSessionUserId, setCurrentSessionUserId] = useState("");

  const draftSharingMode = form.sharingMode.trim();
  const resolvedSharingMode = share?.sharing_mode ?? (draftSharingMode || "(unknown)");

  const quickLocationStateSummary =
    `owner=${form.ownerUserId.trim() || "(empty)"} / ` +
    `share_id=${share?.id ?? "(none)"} / ` +
    `is_active=${share ? String(share.is_active) : "(unknown)"} / ` +
    `sharing_mode=${resolvedSharingMode} / ` +
    `audience_count=${share ? audienceCount : 0} / ` +
    `snapshot_count=${snapshotCount}`;

  const quickAudienceRemoveParitySummary =
    `share_id=${share?.id ?? "(none)"} / ` +
    `removed_audience_id=${lastRemovedAudienceId ?? "(none)"} / ` +
    `audience_count=${share ? audienceCount : 0}`;

  useEffect(() => {
    setForm((current) => ({
      ...current,
      ownerUserId: initialOwnerUserId,
      allowedUserId: initialAllowedUserId,
    }));
    setShare(
      initialShareId
        ? {
            id: initialShareId,
            owner_user_id: initialOwnerUserId,
            sharing_mode: initialForm.sharingMode,
            is_active: true,
          }
        : null,
    );
    setAudienceCount(0);
    setSnapshotCount(0);
  }, [initialAllowedUserId, initialOwnerUserId, initialShareId]);

  useEffect(() => {
    const persistedSession = readPersistedAuthSession();
    setCurrentSessionUserId(persistedSession?.session.user_id?.trim() ?? "");
  }, []);

  async function reloadCounts(input?: {
    shareIdOverride?: string;
    ownerUserIdOverride?: string;
    statusPrefix?: string;
  }) {
    const ownerUserId = (input?.ownerUserIdOverride ?? form.ownerUserId).trim();
    const currentShareId = input?.shareIdOverride ?? share?.id;
    const statusPrefix = input?.statusPrefix?.trim();

    if (!ownerUserId) {
      setStatus("owner_user_id_required");
      return;
    }

    setIsReloadingCounts(true);
    setStatus(statusPrefix ? `${statusPrefix} Reloading location share counts...` : "Reloading location share counts...");

    try {
      const nextSnapshotCount = await getSnapshotCount(ownerUserId);
      setSnapshotCount(nextSnapshotCount);

      if (currentShareId) {
        const nextAudienceCount = await getAudienceCount(currentShareId);
        setAudienceCount(nextAudienceCount);
        const summaryStatus = `Reloaded counts: ${nextAudienceCount} audience member(s), ${nextSnapshotCount} snapshot(s).`;
        setStatus(statusPrefix ? `${statusPrefix} ${summaryStatus}` : summaryStatus);
      } else {
        setAudienceCount(0);
        const summaryStatus = `Reloaded counts: 0 audience member(s), ${nextSnapshotCount} snapshot(s).`;
        setStatus(statusPrefix ? `${statusPrefix} ${summaryStatus}` : summaryStatus);
      }
    } catch (error) {
      const failureStatus = error instanceof Error ? error.message : "location_counts_reload_failed";
      setStatus(statusPrefix ? `${statusPrefix} ${failureStatus}` : failureStatus);
    }

    setIsReloadingCounts(false);
  }

  async function applyCurrentSessionUserAsOwnerAndReloadCounts() {
    const sessionUserId = currentSessionUserId.trim();
    if (!sessionUserId) {
      setStatus("session_owner_missing_for_quick_apply");
      return;
    }

    const ownerStatus =
      form.ownerUserId.trim() === sessionUserId
        ? "Owner already matches current session user (owner_source=session_user)."
        : "Applied current session user as owner (owner_source=session_user).";

    setForm((current) => ({
      ...current,
      ownerUserId: sessionUserId,
    }));

    await reloadCounts({
      ownerUserIdOverride: sessionUserId,
      statusPrefix: ownerStatus,
    });
  }

  async function handleCreateShare() {
    setIsCreatingShare(true);
    setStatus("Creating location share shell...");

    try {
      const created = await createShare({
        ownerUserId: form.ownerUserId.trim(),
        isActive: true,
        sharingMode: form.sharingMode.trim(),
      });
      setShare(created);
      setAudienceCount(0);
      await reloadCounts({ shareIdOverride: created.id });
      setStatus(`Created location share ${created.id} in ${created.sharing_mode} mode.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_share_create_failed");
    }

    setIsCreatingShare(false);
  }

  async function handleToggleShare() {
    if (!share) {
      setStatus("create_share_first");
      return;
    }

    setIsTogglingShare(true);
    setStatus(share.is_active ? "Disabling location sharing..." : "Enabling location sharing...");

    try {
      const updated = await updateShare(share.id, !share.is_active);
      setShare(updated);
      setStatus(`Location sharing is now ${updated.is_active ? "active" : "inactive"}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_share_update_failed");
    }

    setIsTogglingShare(false);
  }

  async function handleAddAudience() {
    if (!share) {
      setStatus("create_share_first");
      return;
    }

    setIsAddingAudience(true);
    setStatus("Adding location audience member...");

    try {
      await createAudience(share.id, form.allowedUserId.trim());
      const nextAudienceCount = await getAudienceCount(share.id);
      setAudienceCount(nextAudienceCount);
      setStatus(`Added audience member. Share now has ${nextAudienceCount} allowed user(s).`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_audience_create_failed");
    }

    setIsAddingAudience(false);
  }

  async function handleRemoveAudience() {
    if (!share) {
      setStatus("create_share_first");
      return;
    }

    const trimmedAudienceId = form.allowedUserId.trim();
    if (!trimmedAudienceId) {
      setStatus("location_audience_id_required_for_remove");
      return;
    }

    setIsRemovingAudience(true);
    setStatus("Removing location audience member...");

    try {
      await removeAudience(share.id, trimmedAudienceId);
      const nextAudienceCount = await getAudienceCount(share.id);
      setAudienceCount(nextAudienceCount);
      setLastRemovedAudienceId(trimmedAudienceId);
      setStatus(`Removed audience member ${trimmedAudienceId}. Share now has ${nextAudienceCount} allowed user(s).`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_audience_remove_failed");
    }

    setIsRemovingAudience(false);
  }

  async function handleCopyQuickLocationStateSummary() {
    const normalizedSummary = quickLocationStateSummary.trim();
    if (!normalizedSummary) {
      setStatus("quick_location_state_summary_empty");
      return;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      setLastCopiedLocationStateSummary("");
      return;
    }

    try {
      await navigator.clipboard.writeText(normalizedSummary);
      setLastCopiedLocationStateSummary(normalizedSummary);
      setStatus(`Copied quick location state summary to clipboard (${normalizedSummary}).`);
    } catch {
      setStatus("quick_location_state_summary_copy_failed");
      setLastCopiedLocationStateSummary("");
    }
  }

  async function handleCopyQuickAudienceRemoveParitySummary() {
    const normalizedSummary = quickAudienceRemoveParitySummary.trim();
    if (!normalizedSummary) {
      setStatus("quick_audience_remove_parity_summary_empty");
      return;
    }

    if (typeof navigator === "undefined" || typeof navigator.clipboard?.writeText !== "function") {
      setStatus("quick_copy_clipboard_unavailable");
      return;
    }

    if (!share) {
      setStatus("quick_audience_remove_parity_summary_missing_share");
      return;
    }

    if (!lastRemovedAudienceId) {
      setStatus("quick_audience_remove_parity_summary_missing_removed_audience");
      return;
    }

    try {
      await navigator.clipboard.writeText(normalizedSummary);
      setStatus(`Copied quick audience remove parity summary to clipboard (${normalizedSummary}).`);
    } catch {
      setStatus("quick_audience_remove_parity_summary_copy_failed");
    }
  }

  async function handleCreateSnapshot() {
    setIsCreatingSnapshot(true);
    setStatus("Creating location snapshot...");

    try {
      await createSnapshot({
        ownerUserId: form.ownerUserId.trim(),
        lat: Number(form.lat),
        lng: Number(form.lng),
        accuracyMeters: form.accuracyMeters.trim() ? Number(form.accuracyMeters) : null,
      });
      const nextSnapshotCount = await getSnapshotCount(form.ownerUserId.trim());
      setSnapshotCount(nextSnapshotCount);
      setStatus(`Created location snapshot. Owner now has ${nextSnapshotCount} snapshot(s).`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_snapshot_create_failed");
    }

    setIsCreatingSnapshot(false);
  }

  return (
    <section>
      <p>
        <strong>Status:</strong> location sharing state shell now wires share activation, audience count, and snapshot count to backend contracts.
      </p>
      <p>{status}</p>
      <p>
        Quick location state summary: <code>{quickLocationStateSummary}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickLocationStateSummary()}>
          Copy quick location state summary
        </button>
      </p>
      {lastCopiedLocationStateSummary ? (
        <p>
          Last copied location state summary: <code>{lastCopiedLocationStateSummary}</code>
        </p>
      ) : null}
      <p>
        Quick audience remove parity summary: <code>{quickAudienceRemoveParitySummary}</code>
      </p>
      <p>
        <button type="button" onClick={() => void handleCopyQuickAudienceRemoveParitySummary()}>
          Copy quick audience remove parity summary
        </button>
      </p>

      <div>
        <label>
          Owner user UUID
          <input
            value={form.ownerUserId}
            onChange={(event) => setForm((current) => ({ ...current, ownerUserId: event.target.value }))}
            placeholder="paste registered owner uuid"
          />
        </label>
        <label>
          Sharing mode
          <input
            value={form.sharingMode}
            onChange={(event) => setForm((current) => ({ ...current, sharingMode: event.target.value }))}
          />
        </label>
        <button type="button" onClick={() => void handleCreateShare()} disabled={isCreatingShare}>
          {isCreatingShare ? "Creating..." : "Create location share"}
        </button>
        <button
          type="button"
          onClick={() => void applyCurrentSessionUserAsOwnerAndReloadCounts()}
          disabled={isReloadingCounts || currentSessionUserId.trim().length === 0}
        >
          {isReloadingCounts
            ? "Applying session owner + reloading..."
            : "Use current session user as owner + reload counts"}
        </button>
        <button type="button" onClick={() => void handleToggleShare()} disabled={isTogglingShare || !share}>
          {isTogglingShare ? "Saving..." : share?.is_active ? "Disable sharing" : "Enable sharing"}
        </button>
        <button type="button" onClick={() => void reloadCounts()} disabled={isReloadingCounts}>
          {isReloadingCounts ? "Reloading..." : "Reload counts"}
        </button>
      </div>

      <div>
        <label>
          Allowed user UUID
          <input
            value={form.allowedUserId}
            onChange={(event) => setForm((current) => ({ ...current, allowedUserId: event.target.value }))}
            placeholder="optional friend uuid for audience"
          />
        </label>
        <button
          type="button"
          onClick={() => void handleAddAudience()}
          disabled={isAddingAudience || isRemovingAudience || !share}
        >
          {isAddingAudience ? "Adding..." : "Add audience member"}
        </button>
        <button
          type="button"
          onClick={() => void handleRemoveAudience()}
          disabled={isRemovingAudience || isAddingAudience || !share}
        >
          {isRemovingAudience ? "Removing..." : "Remove audience member"}
        </button>
      </div>

      <div>
        <label>
          Latitude
          <input
            value={form.lat}
            onChange={(event) => setForm((current) => ({ ...current, lat: event.target.value }))}
          />
        </label>
        <label>
          Longitude
          <input
            value={form.lng}
            onChange={(event) => setForm((current) => ({ ...current, lng: event.target.value }))}
          />
        </label>
        <label>
          Accuracy meters
          <input
            value={form.accuracyMeters}
            onChange={(event) => setForm((current) => ({ ...current, accuracyMeters: event.target.value }))}
          />
        </label>
        <button type="button" onClick={() => void handleCreateSnapshot()} disabled={isCreatingSnapshot}>
          {isCreatingSnapshot ? "Saving..." : "Create location snapshot"}
        </button>
      </div>

      <h2>Current share state</h2>
      {!share ? (
        <p>No share created in this shell yet.</p>
      ) : (
        <ul>
          <li>
            <strong>{share.id}</strong>
            {" · mode: "}
            {share.sharing_mode}
            {" · active: "}
            {share.is_active ? "yes" : "no"}
            {" · audience count: "}
            {audienceCount}
            {" · snapshot count: "}
            {snapshotCount}
          </li>
        </ul>
      )}
    </section>
  );
}
