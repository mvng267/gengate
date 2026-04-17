import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator


class MomentAuthorSummary(BaseModel):
    id: uuid.UUID
    email: str
    username: str | None


class MomentCreateRequest(BaseModel):
    author_user_id: uuid.UUID
    caption_text: str | None = None


class MomentUpdateRequest(BaseModel):
    caption_text: str | None = None


class MomentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    author_user_id: uuid.UUID
    caption_text: str | None
    visibility_scope: str
    deleted_at: datetime | None


class MomentMediaCreateRequest(BaseModel):
    media_type: str
    storage_key: str
    mime_type: str
    width: int | None = None
    height: int | None = None

    @field_validator("width", "height")
    @classmethod
    def validate_non_negative_dimension(cls, value: int | None) -> int | None:
        if value is not None and value < 0:
            raise ValueError("validation_error")
        return value


class MomentMediaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    moment_id: uuid.UUID
    media_type: str
    storage_key: str
    mime_type: str
    width: int | None
    height: int | None


class MomentMediaListResponse(BaseModel):
    count: int
    items: list[MomentMediaResponse]


class MomentListItem(BaseModel):
    id: uuid.UUID
    caption_text: str | None
    visibility_scope: str
    deleted_at: datetime | None
    author: MomentAuthorSummary
    media_items: list[MomentMediaResponse]


class MomentListResponse(BaseModel):
    count: int
    items: list[MomentListItem]


class MomentReactionCreateRequest(BaseModel):
    user_id: uuid.UUID
    reaction_type: str = "heart"


class MomentReactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    moment_id: uuid.UUID
    user_id: uuid.UUID
    reaction_type: str


class MomentReactionListResponse(BaseModel):
    count: int
    items: list[MomentReactionResponse]
