import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.moment_media import MomentMedia
from app.models.moment_reactions import MomentReaction
from app.repositories.base import BaseRepository


class MomentMediaRepository(BaseRepository[MomentMedia]):
    def __init__(self) -> None:
        super().__init__(MomentMedia)

    def list_by_moment(self, db: Session, moment_id: uuid.UUID) -> list[MomentMedia]:
        statement = select(MomentMedia).where(MomentMedia.moment_id == moment_id)
        return list(db.scalars(statement).all())


class MomentReactionRepository(BaseRepository[MomentReaction]):
    def __init__(self) -> None:
        super().__init__(MomentReaction)

    def get_by_moment_and_user(self, db: Session, moment_id: uuid.UUID, user_id: uuid.UUID) -> MomentReaction | None:
        statement = select(MomentReaction).where(
            MomentReaction.moment_id == moment_id,
            MomentReaction.user_id == user_id,
        )
        return db.scalar(statement)

    def list_by_moment(self, db: Session, moment_id: uuid.UUID) -> list[MomentReaction]:
        statement = select(MomentReaction).where(MomentReaction.moment_id == moment_id)
        return list(db.scalars(statement).all())


moment_media_repository = MomentMediaRepository()
moment_reaction_repository = MomentReactionRepository()
