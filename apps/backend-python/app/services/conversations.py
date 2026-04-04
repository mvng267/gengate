import uuid

from sqlalchemy.orm import Session

from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.repositories.conversations import conversation_member_repository, conversation_repository
from app.repositories.users import user_repository


class ConversationService:
    def create_conversation(self, db: Session, conversation_type: str) -> Conversation:
        return conversation_repository.create(db, conversation_type=conversation_type)

    def list_conversations(self, db: Session) -> list[Conversation]:
        return conversation_repository.list(db, limit=200, offset=0)

    def create_member(self, db: Session, conversation_id: uuid.UUID, user_id: uuid.UUID) -> ConversationMember:
        conversation = conversation_repository.get(db, conversation_id)
        if conversation is None:
            raise ValueError("conversation_not_found")

        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        return conversation_member_repository.create(
            db,
            conversation_id=conversation_id,
            user_id=user_id,
            last_read_message_id=None,
        )

    def list_members(self, db: Session, conversation_id: uuid.UUID) -> list[ConversationMember]:
        conversation = conversation_repository.get(db, conversation_id)
        if conversation is None:
            raise ValueError("conversation_not_found")
        return conversation_member_repository.list_by_conversation(db, conversation_id)


conversation_service = ConversationService()
