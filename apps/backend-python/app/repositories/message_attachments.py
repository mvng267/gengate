import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.message_attachments import MessageAttachment
from app.repositories.base import BaseRepository


class MessageAttachmentRepository(BaseRepository[MessageAttachment]):
    def __init__(self) -> None:
        super().__init__(MessageAttachment)

    def list_by_message(self, db: Session, message_id: uuid.UUID) -> list[MessageAttachment]:
        statement = select(MessageAttachment).where(MessageAttachment.message_id == message_id)
        return list(db.scalars(statement).all())


message_attachment_repository = MessageAttachmentRepository()
