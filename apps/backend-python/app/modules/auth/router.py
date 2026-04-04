import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.auth import RegisterRequest, RegisterResponse
from app.schemas.security import (
    DeviceCreateRequest,
    DeviceKeyCreateRequest,
    DeviceKeyListResponse,
    DeviceKeyResponse,
    DeviceListResponse,
    DeviceResponse,
    RecoveryMaterialCreateRequest,
    RecoveryMaterialResponse,
    RecoveryMaterialUpdateRequest,
)
from app.schemas.sessions import SessionCreateRequest, SessionListResponse, SessionResponse
from app.services.auth import auth_service
from app.services.security import security_service
from app.services.sessions import session_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db_session)) -> RegisterResponse:
    user, created = auth_service.register_user(db, payload.email, payload.username)
    if not created:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="user_exists")

    return RegisterResponse(
        id=str(user.id),
        email=user.email,
        username=user.username,
        status=user.status,
    )


@router.post("/devices", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
def create_device(payload: DeviceCreateRequest, db: Session = Depends(get_db_session)) -> DeviceResponse:
    try:
        device = security_service.create_device(db, payload.user_id, payload.platform, payload.device_name)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceResponse.model_validate(device)


@router.get("/devices/{user_id}", response_model=DeviceListResponse)
def list_devices(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceListResponse:
    try:
        devices = security_service.list_devices(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [DeviceResponse.model_validate(device) for device in devices]
    return DeviceListResponse(count=len(items), items=items)


@router.get("/devices/item/{device_id}", response_model=DeviceResponse)
def get_device(device_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceResponse:
    try:
        device = security_service.get_device(db, device_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceResponse.model_validate(device)


@router.patch("/devices/{device_id}/revoke", response_model=DeviceResponse)
def revoke_device(device_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceResponse:
    try:
        device = security_service.revoke_device(db, device_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceResponse.model_validate(device)


@router.post("/device-keys", response_model=DeviceKeyResponse, status_code=status.HTTP_201_CREATED)
def create_device_key(payload: DeviceKeyCreateRequest, db: Session = Depends(get_db_session)) -> DeviceKeyResponse:
    try:
        device_key = security_service.create_device_key(db, payload.device_id, payload.public_key, payload.key_version)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceKeyResponse.model_validate(device_key)


@router.get("/device-keys/{device_id}", response_model=DeviceKeyListResponse)
def list_device_keys(device_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceKeyListResponse:
    try:
        keys = security_service.list_device_keys(db, device_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [DeviceKeyResponse.model_validate(key) for key in keys]
    return DeviceKeyListResponse(count=len(items), items=items)


@router.get("/device-keys/item/{key_id}", response_model=DeviceKeyResponse)
def get_device_key(key_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceKeyResponse:
    try:
        device_key = security_service.get_device_key(db, key_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceKeyResponse.model_validate(device_key)


@router.patch("/device-keys/{key_id}/revoke", response_model=DeviceKeyResponse)
def revoke_device_key(key_id: uuid.UUID, db: Session = Depends(get_db_session)) -> DeviceKeyResponse:
    try:
        device_key = security_service.revoke_device_key(db, key_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return DeviceKeyResponse.model_validate(device_key)


@router.post("/sessions", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
def create_session(payload: SessionCreateRequest, db: Session = Depends(get_db_session)) -> SessionResponse:
    try:
        session = session_service.create_session(
            db,
            user_id=payload.user_id,
            device_id=payload.device_id,
            refresh_token_hash=payload.refresh_token_hash,
            expires_at=payload.expires_at,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return SessionResponse.model_validate(session)


@router.get("/sessions/{user_id}", response_model=SessionListResponse)
def list_sessions(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> SessionListResponse:
    try:
        sessions = session_service.list_sessions(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [SessionResponse.model_validate(session) for session in sessions]
    return SessionListResponse(count=len(items), items=items)


@router.get("/sessions/item/{session_id}", response_model=SessionResponse)
def get_session(session_id: uuid.UUID, db: Session = Depends(get_db_session)) -> SessionResponse:
    try:
        session = session_service.get_session(db, session_id=session_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return SessionResponse.model_validate(session)


@router.patch("/sessions/{session_id}/revoke", response_model=SessionResponse)
def revoke_session(session_id: uuid.UUID, db: Session = Depends(get_db_session)) -> SessionResponse:
    try:
        session = session_service.revoke_session(db, session_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return SessionResponse.model_validate(session)


@router.patch("/sessions/{user_id}/revoke-all", response_model=SessionListResponse)
def revoke_all_sessions_for_user(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> SessionListResponse:
    try:
        sessions = session_service.revoke_all_sessions_for_user(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [SessionResponse.model_validate(session) for session in sessions]
    return SessionListResponse(count=len(items), items=items)


@router.patch("/sessions/device/{device_id}/revoke-all", response_model=SessionListResponse)
def revoke_all_sessions_for_device(
    device_id: uuid.UUID,
    db: Session = Depends(get_db_session),
) -> SessionListResponse:
    try:
        sessions = session_service.revoke_all_sessions_for_device(db, device_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [SessionResponse.model_validate(session) for session in sessions]
    return SessionListResponse(count=len(items), items=items)


@router.post("/recovery-material", response_model=RecoveryMaterialResponse, status_code=status.HTTP_201_CREATED)
def upsert_recovery_material(
    payload: RecoveryMaterialCreateRequest,
    db: Session = Depends(get_db_session),
) -> RecoveryMaterialResponse:
    try:
        recovery = security_service.upsert_recovery_material(
            db,
            user_id=payload.user_id,
            encrypted_backup_blob=payload.encrypted_backup_blob,
            recovery_hint=payload.recovery_hint,
            passphrase_version=payload.passphrase_version,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return RecoveryMaterialResponse.model_validate(recovery)


@router.patch("/recovery-material/{user_id}", response_model=RecoveryMaterialResponse)
def update_recovery_material(
    user_id: uuid.UUID,
    payload: RecoveryMaterialUpdateRequest,
    db: Session = Depends(get_db_session),
) -> RecoveryMaterialResponse:
    try:
        recovery = security_service.update_recovery_material(
            db,
            user_id=user_id,
            encrypted_backup_blob=payload.encrypted_backup_blob,
            recovery_hint=payload.recovery_hint,
            passphrase_version=payload.passphrase_version,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return RecoveryMaterialResponse.model_validate(recovery)


@router.get("/recovery-material/{user_id}", response_model=RecoveryMaterialResponse)
def get_recovery_material(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> RecoveryMaterialResponse:
    try:
        recovery = security_service.get_recovery_material(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    if recovery is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="recovery_not_found")
    return RecoveryMaterialResponse.model_validate(recovery)
