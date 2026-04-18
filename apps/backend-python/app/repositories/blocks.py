import uuid

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.models.blocks import Block
from app.repositories.base import BaseRepository


class BlockRepository(BaseRepository[Block]):
    def __init__(self) -> None:
        super().__init__(Block)

    def list_by_blocker(self, db: Session, blocker_user_id: uuid.UUID) -> list[Block]:
        statement = select(Block).where(Block.blocker_user_id == blocker_user_id)
        return list(db.scalars(statement).all())

    def exists_between_users(self, db: Session, user_a_id: uuid.UUID, user_b_id: uuid.UUID) -> bool:
        statement = (
            select(Block.id)
            .where(
                or_(
                    and_(Block.blocker_user_id == user_a_id, Block.blocked_user_id == user_b_id),
                    and_(Block.blocker_user_id == user_b_id, Block.blocked_user_id == user_a_id),
                )
            )
            .limit(1)
        )
        return db.scalar(statement) is not None


block_repository = BlockRepository()
