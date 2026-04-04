from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, LargeBinary, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class MessageAttachment(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "message_attachments"

    message_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
    )
    attachment_type: Mapped[str] = mapped_column(String(32), nullable=False)
    encrypted_attachment_blob: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
    storage_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
