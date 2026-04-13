import uuid

from pydantic import BaseModel, ConfigDict


class FriendUserSummary(BaseModel):
    id: uuid.UUID
    email: str
    username: str | None


class FriendRequestCreateRequest(BaseModel):
    requester_user_id: uuid.UUID
    receiver_user_id: uuid.UUID


class FriendRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    requester_user_id: uuid.UUID
    receiver_user_id: uuid.UUID
    status: str


class FriendRequestItem(BaseModel):
    id: uuid.UUID
    status: str
    requester: FriendUserSummary
    receiver: FriendUserSummary


class FriendRequestListResponse(BaseModel):
    count: int
    items: list[FriendRequestItem]


class FriendshipResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_a_id: uuid.UUID
    user_b_id: uuid.UUID
    state: str


class FriendshipItem(BaseModel):
    id: uuid.UUID
    state: str
    user_a: FriendUserSummary
    user_b: FriendUserSummary


class FriendshipListResponse(BaseModel):
    count: int
    items: list[FriendshipItem]


class BlockCreateRequest(BaseModel):
    blocker_user_id: uuid.UUID
    blocked_user_id: uuid.UUID


class BlockResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    blocker_user_id: uuid.UUID
    blocked_user_id: uuid.UUID


class BlockListResponse(BaseModel):
    count: int
    items: list[BlockResponse]
