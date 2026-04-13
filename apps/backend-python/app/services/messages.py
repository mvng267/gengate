import uuid

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.models.devices import Device
from app.models.message_device_keys import MessageDeviceKey
from app.models.messages import Message
from app.repositories.conversations import conversation_member_repository, conversation_repository
from app.repositories.messages import message_device_key_repository, message_repository
from app.repositories.security import device_repository
from app.repositories.users import user_repository


class MessageService:
    def _is_message_device_key_duplicate_integrity_error(self, exc: IntegrityError) -> bool:
        message = str(exc).lower()
        if (
            "uq_message_device_keys_message_recipient_device" in message
            or "message_device_keys.message_id, message_device_keys.recipient_device_id" in message
        ):
            return True

        original_error = getattr(exc, "orig", None)
        if original_error is None:
            return False

        if str(getattr(original_error, "pgcode", "")) != "23505":
            return False

        diag = getattr(original_error, "diag", None)
        if diag is None:
            return False

        if str(getattr(diag, "constraint_name", "")) == "uq_message_device_keys_message_recipient_device":
            return True

        return (
            str(getattr(diag, "table_name", "")) == "message_device_keys"
            and "message_id" in str(getattr(diag, "message_detail", "")).lower()
            and "recipient_device_id" in str(getattr(diag, "message_detail", "")).lower()
        )

    def _get_or_create_sender_device(self, db: Session, sender_user_id: uuid.UUID) -> Device:
        existing_devices = device_repository.list_by_user_id(db, sender_user_id)
        for existing_device in existing_devices:
            trust_state = getattr(existing_device, "device_trust_state", None)
            normalized_trust_state = trust_state.lower() if isinstance(trust_state, str) else trust_state
            if normalized_trust_state == "trusted":
                return existing_device

        device = Device(
            user_id=sender_user_id,
            platform="local",
            device_name="default-device",
            device_trust_state="trusted",
            push_token=None,
        )
        db.add(device)
        db.flush()
        return device

    def create_message(
        self,
        db: Session,
        sender_user_id: uuid.UUID,
        payload_text: str,
        conversation_id: uuid.UUID | None = None,
    ) -> Message:
        sender = user_repository.get(db, sender_user_id)
        if sender is None:
            raise ValueError("user_not_found")

        device = self._get_or_create_sender_device(db, sender_user_id)

        if conversation_id is None:
            conversation = Conversation(conversation_type="direct")
            db.add(conversation)
            db.flush()
        else:
            conversation = conversation_repository.get(db, conversation_id)
            if conversation is None:
                raise ValueError("conversation_not_found")

            member = conversation_member_repository.get_by_conversation_and_user(db, conversation_id, sender_user_id)
            if member is None:
                raise ValueError("conversation_member_not_found")

        return message_repository.create(
            db,
            conversation_id=conversation.id,
            sender_user_id=sender_user_id,
            sender_device_id=device.id,
            payload_type="text",
            encrypted_payload_blob=payload_text.encode("utf-8"),
            message_key_version=1,
            edited_at=None,
            deleted_at=None,
        )

    def create_message_device_key(
        self,
        db: Session,
        message_id: uuid.UUID,
        recipient_user_id: uuid.UUID,
        recipient_device_id: uuid.UUID,
        wrapped_message_key_blob: str,
    ) -> MessageDeviceKey:
        message = message_repository.get(db, message_id)
        if message is None:
            raise ValueError("message_not_found")

        recipient_user = user_repository.get(db, recipient_user_id)
        if recipient_user is None:
            raise ValueError("user_not_found")

        recipient_device = device_repository.get(db, recipient_device_id)
        if recipient_device is None:
            raise ValueError("device_not_found")

        if recipient_device.user_id != recipient_user_id:
            raise ValueError("device_user_mismatch")

        existing_device_key = message_device_key_repository.get_by_message_and_recipient_device(
            db,
            message_id=message_id,
            recipient_device_id=recipient_device_id,
        )
        if existing_device_key is not None:
            raise ValueError("message_device_key_exists")

        try:
            return message_device_key_repository.create(
                db,
                message_id=message_id,
                recipient_user_id=recipient_user_id,
                recipient_device_id=recipient_device_id,
                wrapped_message_key_blob=wrapped_message_key_blob.encode("utf-8"),
            )
        except IntegrityError as exc:
            if self._is_message_device_key_duplicate_integrity_error(exc):
                raise ValueError("message_device_key_exists") from exc
            raise

    def list_message_device_keys(self, db: Session, message_id: uuid.UUID) -> list[MessageDeviceKey]:
        message = message_repository.get(db, message_id)
        if message is None:
            raise ValueError("message_not_found")
        return message_device_key_repository.list_by_message(db, message_id)

    def get_message(self, db: Session, message_id: uuid.UUID) -> Message | None:
        return message_repository.get(db, message_id)

    def list_messages(self, db: Session, conversation_id: uuid.UUID | None) -> list[Message]:
        if conversation_id is None:
            return message_repository.list(db, limit=200, offset=0)

        conversation = conversation_repository.get(db, conversation_id)
        if conversation is None:
            raise ValueError("conversation_not_found")

        return message_repository.list_by_conversation(db, conversation_id)


message_service = MessageService()
