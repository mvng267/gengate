import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.device_keys import DeviceKey
from app.models.devices import Device
from app.models.user_recovery_material import UserRecoveryMaterial
from app.repositories.security import (
    device_key_repository,
    device_repository,
    recovery_material_repository,
)
from app.repositories.sessions import session_repository
from app.repositories.users import user_repository


class SecurityService:
    def create_device(
        self,
        db: Session,
        user_id: uuid.UUID,
        platform: str,
        device_name: str,
    ) -> Device:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        return device_repository.create(
            db,
            user_id=user_id,
            platform=platform,
            device_name=device_name,
            device_trust_state="trusted",
            push_token=None,
        )

    def list_devices(self, db: Session, user_id: uuid.UUID) -> list[Device]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return device_repository.list_by_user_id(db, user_id)

    def get_device(self, db: Session, device_id: uuid.UUID) -> Device:
        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")
        return device

    def revoke_device(self, db: Session, device_id: uuid.UUID) -> Device:
        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")

        now = datetime.now(timezone.utc)
        sessions = session_repository.list_by_device_id(db, device_id)
        for session in sessions:
            if session.revoked_at is None:
                session_repository.update(db, session, revoked_at=now)

        keys = device_key_repository.list_by_device_id(db, device_id)
        for key in keys:
            if key.revoked_at is None:
                device_key_repository.update(db, key, revoked_at=now)

        if device.device_trust_state == "revoked":
            return device

        return device_repository.update(db, device, device_trust_state="revoked")

    def create_device_key(
        self,
        db: Session,
        device_id: uuid.UUID,
        public_key: str,
        key_version: int,
    ) -> DeviceKey:
        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")

        return device_key_repository.create(
            db,
            device_id=device_id,
            public_key=public_key,
            key_version=key_version,
            revoked_at=None,
        )

    def list_device_keys(self, db: Session, device_id: uuid.UUID) -> list[DeviceKey]:
        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")
        return device_key_repository.list_by_device_id(db, device_id)

    def get_device_key(self, db: Session, key_id: uuid.UUID) -> DeviceKey:
        device_key = device_key_repository.get(db, key_id)
        if device_key is None:
            raise ValueError("device_key_not_found")
        return device_key

    def revoke_device_key(self, db: Session, key_id: uuid.UUID) -> DeviceKey:
        device_key = device_key_repository.get(db, key_id)
        if device_key is None:
            raise ValueError("device_key_not_found")
        if device_key.revoked_at is not None:
            return device_key

        return device_key_repository.update(db, device_key, revoked_at=datetime.now(timezone.utc))

    def upsert_recovery_material(
        self,
        db: Session,
        user_id: uuid.UUID,
        encrypted_backup_blob: str,
        recovery_hint: str | None,
        passphrase_version: int,
    ) -> UserRecoveryMaterial:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        existing = recovery_material_repository.get_by_user_id(db, user_id)
        blob = encrypted_backup_blob.encode("utf-8")
        if existing is None:
            return recovery_material_repository.create(
                db,
                user_id=user_id,
                encrypted_backup_blob=blob,
                recovery_hint=recovery_hint,
                passphrase_version=passphrase_version,
            )

        return recovery_material_repository.update(
            db,
            existing,
            encrypted_backup_blob=blob,
            recovery_hint=recovery_hint,
            passphrase_version=passphrase_version,
        )

    def update_recovery_material(
        self,
        db: Session,
        user_id: uuid.UUID,
        encrypted_backup_blob: str,
        recovery_hint: str | None,
        passphrase_version: int,
    ) -> UserRecoveryMaterial:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        existing = recovery_material_repository.get_by_user_id(db, user_id)
        if existing is None:
            raise ValueError("recovery_not_found")

        return recovery_material_repository.update(
            db,
            existing,
            encrypted_backup_blob=encrypted_backup_blob.encode("utf-8"),
            recovery_hint=recovery_hint,
            passphrase_version=passphrase_version,
        )

    def get_recovery_material(self, db: Session, user_id: uuid.UUID) -> UserRecoveryMaterial | None:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return recovery_material_repository.get_by_user_id(db, user_id)


security_service = SecurityService()
