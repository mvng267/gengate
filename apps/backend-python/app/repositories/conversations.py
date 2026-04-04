import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.repositories.base import BaseRepository


class ConversationRepository(BaseRepository[Conversation]):
    def __init__(self) -> None:
        super().__init__(Conversation)


class ConversationMemberRepository(BaseRepository[ConversationMember]):
    def __init__(self) -> None:
        super().__init__(ConversationMember)

    def list_by_conversation(self, db: Session, conversation_id: uuid.UUID) -> list[ConversationMember]:
        statement = select(ConversationMember).where(ConversationMember.conversation_id == conversation_id)
        return list(db.scalars(statement).all())


conversation_repository = ConversationRepository()
conversation_member_repository = ConversationMemberRepository()
