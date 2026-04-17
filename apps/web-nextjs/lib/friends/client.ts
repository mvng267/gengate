import { apiRequest } from "@/lib/api/client";

type ApiErrorCodePayload = {
  error?: {
    code?: string;
  };
};

type FriendUserSummary = {
  id: string;
  email: string;
  username: string | null;
};

type FriendRequestItem = {
  id: string;
  status: string;
  requester: FriendUserSummary;
  receiver: FriendUserSummary;
};

type FriendshipItem = {
  id: string;
  state: string;
  user_a: FriendUserSummary;
  user_b: FriendUserSummary;
};

export type FriendGraphSnapshot = {
  userId: string;
  requestCount: number;
  friendshipCount: number;
  pendingRequests: FriendRequestItem[];
  friendships: FriendshipItem[];
};

export type FriendRequestRecord = {
  id: string;
  requester_user_id: string;
  receiver_user_id: string;
  status: string;
};

export type FriendshipRecord = {
  id: string;
  user_a_id: string;
  user_b_id: string;
  state: string;
};

export async function fetchFriendGraphSnapshot(userId: string): Promise<FriendGraphSnapshot> {
  const [requestsResponse, friendshipsResponse] = await Promise.all([
    apiRequest(`/friends/requests?user_id=${encodeURIComponent(userId)}&status=pending`),
    apiRequest(`/friends?user_id=${encodeURIComponent(userId)}`),
  ]);

  if (!requestsResponse.ok) {
    throw new Error(`friend_requests_fetch_failed:${requestsResponse.status}`);
  }

  if (!friendshipsResponse.ok) {
    throw new Error(`friendships_fetch_failed:${friendshipsResponse.status}`);
  }

  const requestsPayload = (await requestsResponse.json()) as {
    count: number;
    items: FriendRequestItem[];
  };
  const friendshipsPayload = (await friendshipsResponse.json()) as {
    count: number;
    items: FriendshipItem[];
  };

  return {
    userId,
    requestCount: requestsPayload.count,
    friendshipCount: friendshipsPayload.count,
    pendingRequests: requestsPayload.items,
    friendships: friendshipsPayload.items,
  };
}

async function readApiErrorCode(response: Response): Promise<string | null> {
  try {
    const payload = (await response.json()) as ApiErrorCodePayload;
    return payload.error?.code ?? null;
  } catch {
    return null;
  }
}

export async function createFriendRequest(input: {
  requesterUserId: string;
  receiverUserId: string;
}): Promise<FriendRequestRecord> {
  const response = await apiRequest("/friends/requests", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      requester_user_id: input.requesterUserId,
      receiver_user_id: input.receiverUserId,
    }),
  });

  if (!response.ok) {
    throw new Error(`friend_request_create_failed:${response.status}`);
  }

  return (await response.json()) as FriendRequestRecord;
}

export async function acceptFriendRequest(requestId: string): Promise<FriendshipRecord> {
  const response = await apiRequest(`/friends/requests/${encodeURIComponent(requestId)}/accept`, {
    method: "POST",
  });

  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode === "request_not_pending") {
      throw new Error(errorCode);
    }
    throw new Error(`friend_request_accept_failed:${response.status}`);
  }

  return (await response.json()) as FriendshipRecord;
}

export async function rejectFriendRequest(requestId: string): Promise<FriendRequestRecord> {
  const response = await apiRequest(`/friends/requests/${encodeURIComponent(requestId)}/reject`, {
    method: "POST",
  });

  if (!response.ok) {
    const errorCode = await readApiErrorCode(response);
    if (errorCode === "request_not_pending") {
      throw new Error(errorCode);
    }
    throw new Error(`friend_request_reject_failed:${response.status}`);
  }

  return (await response.json()) as FriendRequestRecord;
}
