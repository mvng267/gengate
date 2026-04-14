import uuid
from datetime import datetime

from pydantic import BaseModel


class NotificationCreateRequest(BaseModel):
    user_id: uuid.UUID
    notification_type: str
    payload_json: dict


class NotificationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    notification_type: str
    payload_json: dict
    read_at: datetime | None


class NotificationListResponse(BaseModel):
    count: int
    unread_count: int
    items: list[NotificationResponse]
