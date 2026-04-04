import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.device_keys import DeviceKey
from app.models.devices import Device
from app.models.user_recovery_material import UserRecoveryMaterial
from app.repositories.base import BaseRepository


class DeviceRepository(BaseRepository[Device]):
    def __init__(self) -> None:
        super().__init__(Device)

    def list_by_user_id(self, db: Session, user_id: uuid.UUID) -> list[Device]:
        statement = select(Device).where(Device.user_id == user_id)
        return list(db.scalars(statement).all())


class DeviceKeyRepository(BaseRepository[DeviceKey]):
    def __init__(self) -> None:
        super().__init__(DeviceKey)

    def list_by_device_id(self, db: Session, device_id: uuid.UUID) -> list[DeviceKey]:
        statement = select(DeviceKey).where(DeviceKey.device_id == device_id)
        return list(db.scalars(statement).all())


class RecoveryMaterialRepository(BaseRepository[UserRecoveryMaterial]):
    def __init__(self) -> None:
        super().__init__(UserRecoveryMaterial)

    def get_by_user_id(self, db: Session, user_id: uuid.UUID) -> UserRecoveryMaterial | None:
        statement = select(UserRecoveryMaterial).where(UserRecoveryMaterial.user_id == user_id)
        return db.scalar(statement)


device_repository = DeviceRepository()
device_key_repository = DeviceKeyRepository()
recovery_material_repository = RecoveryMaterialRepository()
