import uuid

from pydantic import BaseModel


class MessageAttachmentCreateRequest(BaseModel):
    attachment_type: str
    encrypted_attachment_blob: str
    storage_key: str | None = None


class MessageAttachmentResponse(BaseModel):
    id: uuid.UUID
    message_id: uuid.UUID
    attachment_type: str
    encrypted_attachment_blob: str
    storage_key: str | None


class MessageAttachmentListResponse(BaseModel):
    count: int
    items: list[MessageAttachmentResponse]
