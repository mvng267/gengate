import uuid

from pydantic import BaseModel, ConfigDict


class LocationShareCreateRequest(BaseModel):
    owner_user_id: uuid.UUID
    is_active: bool
    sharing_mode: str


class LocationShareUpdateRequest(BaseModel):
    is_active: bool | None = None


class LocationShareResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_user_id: uuid.UUID
    is_active: bool
    sharing_mode: str


class LocationShareAudienceCreateRequest(BaseModel):
    allowed_user_id: uuid.UUID


class LocationShareAudienceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    location_share_id: uuid.UUID
    allowed_user_id: uuid.UUID


class LocationSnapshotCreateRequest(BaseModel):
    owner_user_id: uuid.UUID
    lat: float
    lng: float
    accuracy_meters: float | None = None


class LocationSnapshotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_user_id: uuid.UUID
    lat: float
    lng: float
    accuracy_meters: float | None
