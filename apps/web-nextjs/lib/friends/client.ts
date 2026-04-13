import { apiRequest } from "@/lib/api/client";

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

export async function fetchFriendGraphSnapshot(userId: string): Promise<FriendGraphSnapshot> {
  const [requestsResponse, friendshipsResponse] = await Promise.all([
    apiRequest(`/friends/requests?user_id=${encodeURIComponent(userId)}`),
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
