import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DeviceCreateRequest(BaseModel):
    user_id: uuid.UUID
    platform: str
    device_name: str


class DeviceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    platform: str
    device_name: str
    device_trust_state: str


class DeviceListResponse(BaseModel):
    count: int
    items: list[DeviceResponse]


class DeviceKeyCreateRequest(BaseModel):
    device_id: uuid.UUID
    public_key: str
    key_version: int


class DeviceKeyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    device_id: uuid.UUID
    public_key: str
    key_version: int
    revoked_at: datetime | None = None


class DeviceKeyListResponse(BaseModel):
    count: int
    items: list[DeviceKeyResponse]


class RecoveryMaterialCreateRequest(BaseModel):
    user_id: uuid.UUID
    encrypted_backup_blob: str
    recovery_hint: str | None = None
    passphrase_version: int


class RecoveryMaterialUpdateRequest(BaseModel):
    encrypted_backup_blob: str
    recovery_hint: str | None = None
    passphrase_version: int


class RecoveryMaterialResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    recovery_hint: str | None
    passphrase_version: int
