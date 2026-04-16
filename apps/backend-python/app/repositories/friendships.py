import uuid

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.models.friend_requests import FriendRequest
from app.models.friendships import Friendship
from app.repositories.base import BaseRepository


class FriendRequestRepository(BaseRepository[FriendRequest]):
    def __init__(self) -> None:
        super().__init__(FriendRequest)

    def list_for_user(
        self,
        db: Session,
        user_id: uuid.UUID,
        status: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[FriendRequest]:
        statement = select(FriendRequest).where(
            or_(FriendRequest.requester_user_id == user_id, FriendRequest.receiver_user_id == user_id)
        )

        if status is not None:
            statement = statement.where(FriendRequest.status == status)

        statement = statement.order_by(FriendRequest.created_at.desc()).offset(offset).limit(limit)
        return list(db.scalars(statement).all())

    def get_pending_between_users(
        self,
        db: Session,
        user_a_id: uuid.UUID,
        user_b_id: uuid.UUID,
    ) -> FriendRequest | None:
        statement = select(FriendRequest).where(
            FriendRequest.status == "pending",
            or_(
                and_(FriendRequest.requester_user_id == user_a_id, FriendRequest.receiver_user_id == user_b_id),
                and_(FriendRequest.requester_user_id == user_b_id, FriendRequest.receiver_user_id == user_a_id),
            ),
        )
        return db.scalar(statement)


class FriendshipRepository(BaseRepository[Friendship]):
    def __init__(self) -> None:
        super().__init__(Friendship)

    def get_by_pair(self, db: Session, user_a_id: uuid.UUID, user_b_id: uuid.UUID) -> Friendship | None:
        statement = select(Friendship).where(
            or_(
                and_(Friendship.user_a_id == user_a_id, Friendship.user_b_id == user_b_id),
                and_(Friendship.user_a_id == user_b_id, Friendship.user_b_id == user_a_id),
            )
        )
        return db.scalar(statement)

    def list_for_user(self, db: Session, user_id: uuid.UUID, limit: int = 100, offset: int = 0) -> list[Friendship]:
        statement = (
            select(Friendship)
            .where(or_(Friendship.user_a_id == user_id, Friendship.user_b_id == user_id))
            .order_by(Friendship.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(db.scalars(statement).all())


friend_request_repository = FriendRequestRepository()
friendship_repository = FriendshipRepository()
