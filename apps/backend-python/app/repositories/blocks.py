import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.blocks import Block
from app.repositories.base import BaseRepository


class BlockRepository(BaseRepository[Block]):
    def __init__(self) -> None:
        super().__init__(Block)

    def list_by_blocker(self, db: Session, blocker_user_id: uuid.UUID) -> list[Block]:
        statement = select(Block).where(Block.blocker_user_id == blocker_user_id)
        return list(db.scalars(statement).all())


block_repository = BlockRepository()
