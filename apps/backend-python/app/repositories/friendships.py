import uuid

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.models.friend_requests import FriendRequest
from app.models.friendships import Friendship
from app.repositories.base import BaseRepository


class FriendRequestRepository(BaseRepository[FriendRequest]):
    def __init__(self) -> None:
        super().__init__(FriendRequest)


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


friend_request_repository = FriendRequestRepository()
friendship_repository = FriendshipRepository()
