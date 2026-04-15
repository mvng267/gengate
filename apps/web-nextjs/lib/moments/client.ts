import { apiRequest } from "@/lib/api/client";

export type MomentComposeInput = {
  authorUserId: string;
  captionText: string;
  imageStorageKey: string;
  imageMimeType: string;
  imageWidth?: number;
  imageHeight?: number;
};

export type MomentListItem = {
  id: string;
  caption_text: string | null;
  visibility_scope: string;
  deleted_at: string | null;
  author: {
    id: string;
    email: string;
    username: string | null;
  };
  media_items: Array<{
    id: string;
    moment_id: string;
    media_type: string;
    storage_key: string;
    mime_type: string;
    width: number | null;
    height: number | null;
  }>;
};

export type MomentDeleteResult = {
  id: string;
  author_user_id: string;
  caption_text: string | null;
  visibility_scope: string;
  deleted_at: string | null;
};

export async function createMomentWithImage(input: MomentComposeInput): Promise<MomentListItem> {
  const createMomentResponse = await apiRequest("/moments", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      author_user_id: input.authorUserId,
      caption_text: input.captionText,
    }),
  });

  if (!createMomentResponse.ok) {
    throw new Error(`moment_create_failed:${createMomentResponse.status}`);
  }

  const createdMoment = (await createMomentResponse.json()) as { id: string };

  const createMediaResponse = await apiRequest(`/moments/${createdMoment.id}/media`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      media_type: "image",
      storage_key: input.imageStorageKey,
      mime_type: input.imageMimeType,
      width: input.imageWidth ?? null,
      height: input.imageHeight ?? null,
    }),
  });

  if (!createMediaResponse.ok) {
    throw new Error(`moment_media_create_failed:${createMediaResponse.status}`);
  }

  const listResponse = await apiRequest(`/moments?author_user_id=${encodeURIComponent(input.authorUserId)}`);
  if (!listResponse.ok) {
    throw new Error(`moment_list_failed:${listResponse.status}`);
  }

  const listPayload = (await listResponse.json()) as {
    count: number;
    items: MomentListItem[];
  };

  const createdItem = listPayload.items.find((item) => item.id === createdMoment.id);
  if (!createdItem) {
    throw new Error("moment_created_but_not_listed");
  }

  return createdItem;
}

export async function listMomentsForAuthor(authorUserId: string): Promise<MomentListItem[]> {
  const response = await apiRequest(`/moments?author_user_id=${encodeURIComponent(authorUserId)}`);
  if (!response.ok) {
    throw new Error(`moment_list_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: MomentListItem[];
  };

  return payload.items;
}

export async function listPrivateFeed(viewerUserId: string): Promise<MomentListItem[]> {
  const response = await apiRequest(`/moments/feed?viewer_user_id=${encodeURIComponent(viewerUserId)}`);
  if (!response.ok) {
    throw new Error(`private_feed_failed:${response.status}`);
  }

  const payload = (await response.json()) as {
    count: number;
    items: MomentListItem[];
  };

  return payload.items;
}

export async function deleteMoment(momentId: string): Promise<MomentDeleteResult> {
  const response = await apiRequest(`/moments/${encodeURIComponent(momentId)}`, {
    method: "DELETE",
  });

  if (!response.ok) {
    throw new Error(`moment_delete_failed:${response.status}`);
  }

  return (await response.json()) as MomentDeleteResult;
}
