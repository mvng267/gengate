import uuid

from sqlalchemy.orm import Session

from app.models.blocks import Block
from app.repositories.blocks import block_repository
from app.repositories.users import user_repository


class BlockService:
    def create_block(self, db: Session, blocker_user_id: uuid.UUID, blocked_user_id: uuid.UUID) -> Block:
        if blocker_user_id == blocked_user_id:
            raise ValueError("invalid_block")

        blocker = user_repository.get(db, blocker_user_id)
        blocked = user_repository.get(db, blocked_user_id)
        if blocker is None or blocked is None:
            raise ValueError("user_not_found")

        existing = self.get_block_by_pair(db, blocker_user_id, blocked_user_id)
        if existing is not None:
            return existing

        return block_repository.create(
            db,
            blocker_user_id=blocker_user_id,
            blocked_user_id=blocked_user_id,
        )

    def get_block_by_pair(self, db: Session, blocker_user_id: uuid.UUID, blocked_user_id: uuid.UUID) -> Block | None:
        blocks = block_repository.list_by_blocker(db, blocker_user_id)
        for block in blocks:
            if block.blocked_user_id == blocked_user_id:
                return block
        return None

    def list_blocks(self, db: Session, blocker_user_id: uuid.UUID) -> list[Block]:
        return block_repository.list_by_blocker(db, blocker_user_id)


block_service = BlockService()
