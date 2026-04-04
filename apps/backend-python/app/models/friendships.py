from __future__ import annotations

import uuid

from sqlalchemy import CheckConstraint, ForeignKey, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class Friendship(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "friendships"
    __table_args__ = (
        UniqueConstraint("user_a_id", "user_b_id", name="uq_friendships_user_pair"),
        CheckConstraint("user_a_id <> user_b_id", name="ck_friendships_distinct_users"),
    )

    user_a_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_b_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    state: Mapped[str] = mapped_column(String(32), nullable=False, default="accepted")
