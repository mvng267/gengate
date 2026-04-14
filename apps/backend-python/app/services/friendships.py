import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.friend_requests import FriendRequest
from app.models.friendships import Friendship
from app.repositories.friendships import friend_request_repository, friendship_repository
from app.repositories.users import user_repository


class FriendshipService:
    def create_request(self, db: Session, requester_user_id: uuid.UUID, receiver_user_id: uuid.UUID) -> FriendRequest:
        if requester_user_id == receiver_user_id:
            raise ValueError("invalid_request")

        requester = user_repository.get(db, requester_user_id)
        receiver = user_repository.get(db, receiver_user_id)
        if requester is None or receiver is None:
            raise ValueError("user_not_found")

        existing_friendship = friendship_repository.get_by_pair(db, requester_user_id, receiver_user_id)
        if existing_friendship is not None:
            raise ValueError("friendship_already_exists")

        existing_pending_request = friend_request_repository.get_pending_between_users(
            db,
            requester_user_id,
            receiver_user_id,
        )
        if existing_pending_request is not None:
            raise ValueError("friend_request_already_pending")

        return friend_request_repository.create(
            db,
            requester_user_id=requester_user_id,
            receiver_user_id=receiver_user_id,
            status="pending",
            responded_at=None,
        )

    def accept_request(self, db: Session, request_id: uuid.UUID) -> Friendship:
        friend_request = friend_request_repository.get(db, request_id)
        if friend_request is None:
            raise ValueError("request_not_found")

        if friend_request.status == "accepted":
            existing = friendship_repository.get_by_pair(
                db,
                friend_request.requester_user_id,
                friend_request.receiver_user_id,
            )
            if existing is not None:
                return existing
            raise ValueError("request_not_pending")

        if friend_request.status != "pending":
            raise ValueError("request_not_pending")

        existing = friendship_repository.get_by_pair(
            db,
            friend_request.requester_user_id,
            friend_request.receiver_user_id,
        )
        if existing is not None:
            friend_request.status = "accepted"
            if friend_request.responded_at is None:
                friend_request.responded_at = datetime.now(timezone.utc)
            db.flush()
            return existing

        user_a_id, user_b_id = sorted(
            [friend_request.requester_user_id, friend_request.receiver_user_id],
            key=lambda user_id: str(user_id),
        )

        friendship = friendship_repository.create(
            db,
            user_a_id=user_a_id,
            user_b_id=user_b_id,
            state="accepted",
        )
        friend_request.status = "accepted"
        friend_request.responded_at = datetime.now(timezone.utc)
        db.flush()
        return friendship

    def reject_request(self, db: Session, request_id: uuid.UUID) -> FriendRequest:
        friend_request = friend_request_repository.get(db, request_id)
        if friend_request is None:
            raise ValueError("request_not_found")

        if friend_request.status == "rejected":
            return friend_request

        if friend_request.status != "pending":
            raise ValueError("request_not_pending")

        friend_request.status = "rejected"
        friend_request.responded_at = datetime.now(timezone.utc)
        db.flush()
        return friend_request

    def list_friendships(self, db: Session, user_id: uuid.UUID | None = None) -> list[Friendship]:
        if user_id is None:
            return friendship_repository.list(db, limit=1000, offset=0)
        return friendship_repository.list_for_user(db, user_id=user_id, limit=100, offset=0)

    def list_friend_requests(self, db: Session, user_id: uuid.UUID) -> list[FriendRequest]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return friend_request_repository.list_for_user(db, user_id=user_id, limit=100, offset=0)


friendship_service = FriendshipService()
