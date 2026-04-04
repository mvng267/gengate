from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, Integer, LargeBinary, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin, UpdatedAtMixin


class UserRecoveryMaterial(UUIDPrimaryKeyMixin, CreatedAtMixin, UpdatedAtMixin, Base):
    __tablename__ = "user_recovery_material"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    encrypted_backup_blob: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
    recovery_hint: Mapped[str | None] = mapped_column(String(255), nullable=True)
    passphrase_version: Mapped[int] = mapped_column(Integer, nullable=False)
