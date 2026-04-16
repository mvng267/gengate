import { apiRequest } from "@/lib/api/client";

export type LocationShareItem = {
  id: string;
  owner_user_id: string;
  is_active: boolean;
  sharing_mode: string;
};

export type LocationSnapshotItem = {
  id: string;
  owner_user_id: string;
  lat: number;
  lng: number;
  accuracy_meters: number | null;
};

export type AudienceItem = {
  id: string;
  location_share_id: string;
  allowed_user_id: string;
};

export async function createShare(input: {
  ownerUserId: string;
  isActive: boolean;
  sharingMode: string;
}): Promise<LocationShareItem> {
  const response = await apiRequest("/locations/shares", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      owner_user_id: input.ownerUserId,
      is_active: input.isActive,
      sharing_mode: input.sharingMode,
    }),
  });

  if (!response.ok) {
    throw new Error(`location_share_create_failed:${response.status}`);
  }

  return (await response.json()) as LocationShareItem;
}

export async function updateShare(shareId: string, isActive: boolean): Promise<LocationShareItem> {
  const response = await apiRequest(`/locations/shares/${encodeURIComponent(shareId)}`, {
    method: "PATCH",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({ is_active: isActive }),
  });

  if (!response.ok) {
    throw new Error(`location_share_update_failed:${response.status}`);
  }

  return (await response.json()) as LocationShareItem;
}

export async function createAudience(shareId: string, allowedUserId: string): Promise<AudienceItem> {
  const response = await apiRequest(`/locations/shares/${encodeURIComponent(shareId)}/audience`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({ allowed_user_id: allowedUserId }),
  });

  if (!response.ok) {
    throw new Error(`location_audience_create_failed:${response.status}`);
  }

  return (await response.json()) as AudienceItem;
}

export async function removeAudience(shareId: string, audienceId: string): Promise<{ status: string }> {
  const response = await apiRequest(
    `/locations/shares/${encodeURIComponent(shareId)}/audience/${encodeURIComponent(audienceId)}`,
    {
      method: "DELETE",
    },
  );

  if (!response.ok) {
    throw new Error(`location_audience_remove_failed:${response.status}`);
  }

  return (await response.json()) as { status: string };
}

export async function getAudienceCount(shareId: string): Promise<number> {
  const response = await apiRequest(`/locations/shares/${encodeURIComponent(shareId)}/audience`);
  if (!response.ok) {
    throw new Error(`location_audience_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as { count: number };
  return payload.count;
}

export async function createSnapshot(input: {
  ownerUserId: string;
  lat: number;
  lng: number;
  accuracyMeters: number | null;
}): Promise<LocationSnapshotItem> {
  const response = await apiRequest("/locations/snapshots", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      owner_user_id: input.ownerUserId,
      lat: input.lat,
      lng: input.lng,
      accuracy_meters: input.accuracyMeters,
    }),
  });

  if (!response.ok) {
    throw new Error(`location_snapshot_create_failed:${response.status}`);
  }

  return (await response.json()) as LocationSnapshotItem;
}

export async function getSnapshotCount(ownerUserId: string): Promise<number> {
  const response = await apiRequest(`/locations/snapshots/${encodeURIComponent(ownerUserId)}`);
  if (!response.ok) {
    throw new Error(`location_snapshot_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as { count: number };
  return payload.count;
}
