from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.users import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self) -> None:
        super().__init__(User)

    def get_by_email(self, db: Session, email: str) -> User | None:
        return db.scalar(select(User).where(User.email == email))

    def get_by_username(self, db: Session, username: str) -> User | None:
        return db.scalar(select(User).where(User.username == username))


user_repository = UserRepository()
