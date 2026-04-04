import uuid

from pydantic import BaseModel


class MessageCreateRequest(BaseModel):
    sender_user_id: uuid.UUID
    payload_text: str


class MessageDeviceKeyCreateRequest(BaseModel):
    recipient_user_id: uuid.UUID
    recipient_device_id: uuid.UUID
    wrapped_message_key_blob: str


class MessageDeviceKeyResponse(BaseModel):
    id: uuid.UUID
    message_id: uuid.UUID
    recipient_user_id: uuid.UUID
    recipient_device_id: uuid.UUID
    wrapped_message_key_blob: str


class MessageDeviceKeyListResponse(BaseModel):
    count: int
    items: list[MessageDeviceKeyResponse]


class MessageResponse(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    sender_user_id: uuid.UUID
    payload_text: str


class MessageListResponse(BaseModel):
    count: int
    items: list[MessageResponse]
