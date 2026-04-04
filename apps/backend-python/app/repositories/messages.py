import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.message_device_keys import MessageDeviceKey
from app.models.messages import Message
from app.repositories.base import BaseRepository


class MessageRepository(BaseRepository[Message]):
    def __init__(self) -> None:
        super().__init__(Message)

    def list_by_conversation(self, db: Session, conversation_id: uuid.UUID) -> list[Message]:
        statement = select(Message).where(Message.conversation_id == conversation_id)
        return list(db.scalars(statement).all())


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
