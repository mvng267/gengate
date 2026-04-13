import uuid

from pydantic import BaseModel


class ConversationCreateRequest(BaseModel):
    conversation_type: str = "direct"


class DirectConversationGetOrCreateRequest(BaseModel):
    user_a_id: uuid.UUID
    user_b_id: uuid.UUID


class ConversationResponse(BaseModel):
    id: uuid.UUID
    conversation_type: str


class DirectConversationResponse(BaseModel):
    id: uuid.UUID
    conversation_type: str
    member_user_ids: list[uuid.UUID]


class ConversationListResponse(BaseModel):
    count: int
    items: list[ConversationResponse]


class ConversationMemberCreateRequest(BaseModel):
    user_id: uuid.UUID


class ConversationMemberReadCursorUpdateRequest(BaseModel):
    last_read_message_id: uuid.UUID


class ConversationMemberResponse(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    user_id: uuid.UUID
    last_read_message_id: uuid.UUID | None = None


class ConversationMemberListResponse(BaseModel):
    count: int
    items: list[ConversationMemberResponse]
