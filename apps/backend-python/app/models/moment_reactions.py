from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class MomentReaction(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "moment_reactions"
    __table_args__ = (
        UniqueConstraint("moment_id", "user_id", name="uq_moment_reactions_moment_user"),
    )

    moment_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("moments.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    reaction_type: Mapped[str] = mapped_column(String(32), nullable=False, default="heart")
