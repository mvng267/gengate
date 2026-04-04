import uuid

from pydantic import BaseModel


class ConversationCreateRequest(BaseModel):
    conversation_type: str = "direct"


class ConversationResponse(BaseModel):
    id: uuid.UUID
    conversation_type: str


class ConversationListResponse(BaseModel):
    count: int
    items: list[ConversationResponse]


class ConversationMemberCreateRequest(BaseModel):
    user_id: uuid.UUID


class ConversationMemberResponse(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    user_id: uuid.UUID


class ConversationMemberListResponse(BaseModel):
    count: int
    items: list[ConversationMemberResponse]
