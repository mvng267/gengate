import uuid

from pydantic import BaseModel, ConfigDict


class ProfileUpsertRequest(BaseModel):
    user_id: uuid.UUID
    display_name: str | None = None
    bio: str | None = None
    avatar_url: str | None = None


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str | None
    bio: str | None
    avatar_url: str | None
