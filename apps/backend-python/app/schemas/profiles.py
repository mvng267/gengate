import uuid

from pydantic import BaseModel, ConfigDict, Field


class ProfileUpsertRequest(BaseModel):
    user_id: uuid.UUID
    display_name: str | None = Field(default=None, max_length=120)
    bio: str | None = None
    avatar_url: str | None = None


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str | None
    bio: str | None
    avatar_url: str | None
