import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.profiles import Profile
from app.repositories.base import BaseRepository


class ProfileRepository(BaseRepository[Profile]):
    def __init__(self) -> None:
        super().__init__(Profile)

    def get_by_user_id(self, db: Session, user_id: uuid.UUID) -> Profile | None:
        return db.scalar(select(Profile).where(Profile.user_id == user_id))


profile_repository = ProfileRepository()
