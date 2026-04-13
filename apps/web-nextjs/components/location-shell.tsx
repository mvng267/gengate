"use client";

import { useState } from "react";

import {
  createAudience,
  createShare,
  createSnapshot,
  getAudienceCount,
  getSnapshotCount,
  updateShare,
  type LocationShareItem,
} from "@/lib/location/client";

const initialForm = {
  ownerUserId: "",
  allowedUserId: "",
  sharingMode: "custom_list",
  lat: "10.7769",
  lng: "106.7009",
  accuracyMeters: "20",
};

export function LocationShell() {
  const [form, setForm] = useState(initialForm);
  const [share, setShare] = useState<LocationShareItem | null>(null);
  const [audienceCount, setAudienceCount] = useState(0);
  const [snapshotCount, setSnapshotCount] = useState(0);
  const [status, setStatus] = useState(
    "Provide a real owner UUID to create/load a location sharing state shell. Optional friend UUID can be added to the allowed audience.",
  );
  const [isCreatingShare, setIsCreatingShare] = useState(false);
  const [isTogglingShare, setIsTogglingShare] = useState(false);
  const [isAddingAudience, setIsAddingAudience] = useState(false);
  const [isCreatingSnapshot, setIsCreatingSnapshot] = useState(false);
  const [isReloadingCounts, setIsReloadingCounts] = useState(false);

  async function reloadCounts(currentShareId?: string) {
    const ownerUserId = form.ownerUserId.trim();
    if (!ownerUserId) {
      setStatus("owner_user_id_required");
      return;
    }

    setIsReloadingCounts(true);
    setStatus("Reloading location share counts...");

    try {
      const nextSnapshotCount = await getSnapshotCount(ownerUserId);
      setSnapshotCount(nextSnapshotCount);

      if (currentShareId) {
        const nextAudienceCount = await getAudienceCount(currentShareId);
        setAudienceCount(nextAudienceCount);
        setStatus(`Reloaded counts: ${nextAudienceCount} audience member(s), ${nextSnapshotCount} snapshot(s).`);
      } else {
        setAudienceCount(0);
        setStatus(`Reloaded counts: 0 audience member(s), ${nextSnapshotCount} snapshot(s).`);
      }
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "location_counts_reload_failed");
    }

    setIsReloadingCounts(false);
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
      await reloadCounts(created.id);
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
        <button type="button" onClick={() => void handleToggleShare()} disabled={isTogglingShare || !share}>
          {isTogglingShare ? "Saving..." : share?.is_active ? "Disable sharing" : "Enable sharing"}
        </button>
        <button
          type="button"
          onClick={() => void reloadCounts(share?.id)}
          disabled={isReloadingCounts}
        >
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
        <button type="button" onClick={() => void handleAddAudience()} disabled={isAddingAudience || !share}>
          {isAddingAudience ? "Adding..." : "Add audience member"}
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
