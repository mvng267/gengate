import uuid

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.models.message_device_keys import MessageDeviceKey
from app.models.messages import Message
from app.repositories.base import BaseRepository


class MessageRepository(BaseRepository[Message]):
    def __init__(self) -> None:
        super().__init__(Message)

    def list_active(self, db: Session, *, limit: int = 100, offset: int = 0) -> list[Message]:
        statement = (
            select(Message)
            .where(Message.deleted_at.is_(None))
            .order_by(Message.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(db.scalars(statement).all())

    def list_by_conversation(self, db: Session, conversation_id: uuid.UUID) -> list[Message]:
        statement = (
            select(Message)
            .where(
                and_(
                    Message.conversation_id == conversation_id,
                    Message.deleted_at.is_(None),
                )
            )
            .order_by(Message.created_at.asc())
        )
        return list(db.scalars(statement).all())

    def soft_delete(self, db: Session, message: Message) -> Message:
        from datetime import datetime, timezone

        message.deleted_at = datetime.now(timezone.utc)
        db.add(message)
        db.flush()
        return message


class MessageDeviceKeyRepository(BaseRepository[MessageDeviceKey]):
    def __init__(self) -> None:
        super().__init__(MessageDeviceKey)

    def list_by_message(self, db: Session, message_id: uuid.UUID) -> list[MessageDeviceKey]:
        statement = select(MessageDeviceKey).where(MessageDeviceKey.message_id == message_id)
        return list(db.scalars(statement).all())

    def get_by_message_and_recipient_device(
        self,
        db: Session,
        message_id: uuid.UUID,
        recipient_device_id: uuid.UUID,
    ) -> MessageDeviceKey | None:
        statement = select(MessageDeviceKey).where(
            MessageDeviceKey.message_id == message_id,
            MessageDeviceKey.recipient_device_id == recipient_device_id,
        )
        return db.scalar(statement)


message_repository = MessageRepository()
message_device_key_repository = MessageDeviceKeyRepository()
