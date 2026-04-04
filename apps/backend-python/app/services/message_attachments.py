import uuid

from sqlalchemy.orm import Session

from app.models.message_attachments import MessageAttachment
from app.repositories.message_attachments import message_attachment_repository
from app.repositories.messages import message_repository


class MessageAttachmentService:
    def create_attachment(
        self,
        db: Session,
        message_id: uuid.UUID,
        attachment_type: str,
        encrypted_attachment_blob: str,
        storage_key: str | None,
    ) -> MessageAttachment:
        message = message_repository.get(db, message_id)
        if message is None:
            raise ValueError("message_not_found")

        return message_attachment_repository.create(
            db,
            message_id=message_id,
            attachment_type=attachment_type,
            encrypted_attachment_blob=encrypted_attachment_blob.encode("utf-8"),
            storage_key=storage_key,
        )

    def list_attachments(self, db: Session, message_id: uuid.UUID) -> list[MessageAttachment]:
        message = message_repository.get(db, message_id)
        if message is None:
            raise ValueError("message_not_found")
        return message_attachment_repository.list_by_message(db, message_id)


message_attachment_service = MessageAttachmentService()
