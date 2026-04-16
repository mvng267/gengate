import uuid

from sqlalchemy.orm import Session

from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.repositories.conversations import conversation_member_repository, conversation_repository
from app.repositories.messages import message_repository
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

        existing_member = conversation_member_repository.get_by_conversation_and_user(db, conversation_id, user_id)
        if existing_member is not None:
            return existing_member

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

    def get_or_create_direct_conversation(
        self,
        db: Session,
        user_a_id: uuid.UUID,
        user_b_id: uuid.UUID,
    ) -> tuple[Conversation, list[ConversationMember]]:
        if user_a_id == user_b_id:
            raise ValueError("invalid_direct_members")

        user_a = user_repository.get(db, user_a_id)
        user_b = user_repository.get(db, user_b_id)
        if user_a is None or user_b is None:
            raise ValueError("user_not_found")

        existing = conversation_repository.find_direct_by_members(db, user_a_id, user_b_id)
        if existing is not None:
            return existing, conversation_member_repository.list_by_conversation(db, existing.id)

        conversation = conversation_repository.create(db, conversation_type="direct")
        members = [
            conversation_member_repository.create(
                db,
                conversation_id=conversation.id,
                user_id=user_a_id,
                last_read_message_id=None,
            ),
            conversation_member_repository.create(
                db,
                conversation_id=conversation.id,
                user_id=user_b_id,
                last_read_message_id=None,
            ),
        ]
        return conversation, members

    def list_direct_conversations_for_user(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> list[tuple[Conversation, list[ConversationMember]]]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        memberships = conversation_member_repository.list_by_user(db, user_id)
        if not memberships:
            return []

        results: list[tuple[Conversation, list[ConversationMember]]] = []
        seen_conversation_ids: set[uuid.UUID] = set()
        for membership in memberships:
            conversation_id = membership.conversation_id
            if conversation_id in seen_conversation_ids:
                continue

            conversation = conversation_repository.get(db, conversation_id)
            if conversation is None or conversation.conversation_type != "direct":
                continue

            members = conversation_member_repository.list_by_conversation(db, conversation_id)
            if len(members) != 2:
                continue

            seen_conversation_ids.add(conversation_id)
            results.append((conversation, members))

        latest_activity_by_conversation_id: dict[uuid.UUID, object] = {}
        for conversation, _ in results:
            messages = message_repository.list_by_conversation(db, conversation.id)
            latest_activity_by_conversation_id[conversation.id] = (
                messages[-1].created_at if messages else conversation.created_at
            )

        results.sort(
            key=lambda row: latest_activity_by_conversation_id[row[0].id],
            reverse=True,
        )
        return results

    def update_direct_member_read_cursor(
        self,
        db: Session,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
        last_read_message_id: uuid.UUID,
    ) -> ConversationMember:
        conversation = conversation_repository.get(db, conversation_id)
        if conversation is None:
            raise ValueError("conversation_not_found")

        if conversation.conversation_type != "direct":
            raise ValueError("conversation_not_direct")

        member = conversation_member_repository.get_by_conversation_and_user(db, conversation_id, user_id)
        if member is None:
            raise ValueError("conversation_member_not_found")

        message = message_repository.get(db, last_read_message_id)
        if message is None or message.deleted_at is not None:
            raise ValueError("message_not_found")

        if message.conversation_id != conversation_id:
            raise ValueError("message_conversation_mismatch")

        return conversation_member_repository.update_last_read_message(
            db,
            member,
            last_read_message_id=last_read_message_id,
        )


conversation_service = ConversationService()
