import uuid

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.repositories.base import BaseRepository


class ConversationRepository(BaseRepository[Conversation]):
    def __init__(self) -> None:
        super().__init__(Conversation)

    def find_direct_by_members(
        self,
        db: Session,
        user_a_id: uuid.UUID,
        user_b_id: uuid.UUID,
    ) -> Conversation | None:
        member_match_subquery = (
            select(ConversationMember.conversation_id)
            .where(ConversationMember.user_id.in_([user_a_id, user_b_id]))
            .group_by(ConversationMember.conversation_id)
            .having(func.count(func.distinct(ConversationMember.user_id)) == 2)
            .subquery()
        )

        direct_pair_subquery = (
            select(ConversationMember.conversation_id)
            .group_by(ConversationMember.conversation_id)
            .having(func.count() == 2)
            .subquery()
        )

        statement = (
            select(Conversation)
            .where(Conversation.conversation_type == "direct")
            .where(Conversation.id.in_(select(member_match_subquery.c.conversation_id)))
            .where(Conversation.id.in_(select(direct_pair_subquery.c.conversation_id)))
            .order_by(Conversation.created_at.desc())
        )
        return db.scalar(statement)


class ConversationMemberRepository(BaseRepository[ConversationMember]):
    def __init__(self) -> None:
        super().__init__(ConversationMember)

    def list_by_conversation(self, db: Session, conversation_id: uuid.UUID) -> list[ConversationMember]:
        statement = select(ConversationMember).where(ConversationMember.conversation_id == conversation_id)
        return list(db.scalars(statement).all())

    def list_by_user(self, db: Session, user_id: uuid.UUID) -> list[ConversationMember]:
        statement = select(ConversationMember).where(ConversationMember.user_id == user_id)
        return list(db.scalars(statement).all())

    def get_by_conversation_and_user(
        self,
        db: Session,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> ConversationMember | None:
        statement = select(ConversationMember).where(
            ConversationMember.conversation_id == conversation_id,
            ConversationMember.user_id == user_id,
        )
        return db.scalar(statement)

    def update_last_read_message(
        self,
        db: Session,
        member: ConversationMember,
        *,
        last_read_message_id: uuid.UUID,
    ) -> ConversationMember:
        member.last_read_message_id = last_read_message_id
        db.add(member)
        db.flush()
        return member

    def clear_last_read_message_references(
        self,
        db: Session,
        *,
        message_id: uuid.UUID,
    ) -> None:
        statement = update(ConversationMember).where(
            ConversationMember.last_read_message_id == message_id
        ).values(last_read_message_id=None)
        db.execute(statement)


conversation_repository = ConversationRepository()
conversation_member_repository = ConversationMemberRepository()
