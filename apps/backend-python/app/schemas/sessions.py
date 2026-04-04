import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class SessionCreateRequest(BaseModel):
    user_id: uuid.UUID
    device_id: uuid.UUID
    refresh_token_hash: str
    expires_at: datetime


class SessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    device_id: uuid.UUID
    refresh_token_hash: str
    expires_at: datetime
    revoked_at: datetime | None = None


class SessionListResponse(BaseModel):
    count: int
    items: list[SessionResponse]
