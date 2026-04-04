from __future__ import annotations

import uuid

from sqlalchemy import CheckConstraint, ForeignKey, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class Block(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "blocks"
    __table_args__ = (
        UniqueConstraint("blocker_user_id", "blocked_user_id", name="uq_blocks_blocker_blocked"),
        CheckConstraint("blocker_user_id <> blocked_user_id", name="ck_blocks_distinct_users"),
    )

    blocker_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    blocked_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
