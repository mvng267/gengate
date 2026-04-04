import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.locations import (
    LocationShareAudienceCreateRequest,
    LocationShareAudienceResponse,
    LocationShareCreateRequest,
    LocationShareResponse,
    LocationShareUpdateRequest,
    LocationSnapshotCreateRequest,
    LocationSnapshotResponse,
)
from app.services.locations import location_service

router = APIRouter(prefix="/locations", tags=["locations"])


@router.post("/shares", response_model=LocationShareResponse, status_code=status.HTTP_201_CREATED)
def create_share(payload: LocationShareCreateRequest, db: Session = Depends(get_db_session)) -> LocationShareResponse:
    try:
        share = location_service.create_share(
            db,
            owner_user_id=payload.owner_user_id,
            is_active=payload.is_active,
            sharing_mode=payload.sharing_mode,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return LocationShareResponse.model_validate(share)


@router.patch("/shares/{share_id}", response_model=LocationShareResponse)
def update_share(
    share_id: uuid.UUID,
    payload: LocationShareUpdateRequest,
    db: Session = Depends(get_db_session),
) -> LocationShareResponse:
    try:
        share = location_service.update_share(db, share_id, payload.is_active)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return LocationShareResponse.model_validate(share)


@router.get("/shares", response_model=dict)
def list_location_shares(db: Session = Depends(get_db_session)) -> dict[str, int]:
    shares = location_service.list_shares(db)
    return {"count": len(shares)}


@router.post("/shares/{share_id}/audience", response_model=LocationShareAudienceResponse, status_code=status.HTTP_201_CREATED)
def create_location_share_audience(
    share_id: uuid.UUID,
    payload: LocationShareAudienceCreateRequest,
    db: Session = Depends(get_db_session),
) -> LocationShareAudienceResponse:
    try:
        audience = location_service.create_share_audience(db, share_id, payload.allowed_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return LocationShareAudienceResponse.model_validate(audience)


@router.get("/shares/{share_id}/audience", response_model=dict)
def list_location_share_audience(share_id: uuid.UUID, db: Session = Depends(get_db_session)) -> dict[str, int]:
    try:
        audience = location_service.list_share_audience(db, share_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return {"count": len(audience)}


@router.delete("/shares/{share_id}/audience/{audience_id}", response_model=dict)
def remove_location_share_audience(
    share_id: uuid.UUID,
    audience_id: uuid.UUID,
    db: Session = Depends(get_db_session),
) -> dict[str, str]:
    try:
        location_service.remove_share_audience(db, share_id, audience_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return {"status": "removed"}


@router.post("/snapshots", response_model=LocationSnapshotResponse, status_code=status.HTTP_201_CREATED)
def create_snapshot(
    payload: LocationSnapshotCreateRequest,
    db: Session = Depends(get_db_session),
) -> LocationSnapshotResponse:
    try:
        snapshot = location_service.create_snapshot(
            db,
            owner_user_id=payload.owner_user_id,
            lat=payload.lat,
            lng=payload.lng,
            accuracy_meters=payload.accuracy_meters,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return LocationSnapshotResponse.model_validate(snapshot)


@router.get("/snapshots/{owner_user_id}", response_model=dict)
def list_snapshots(owner_user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> dict[str, int]:
    snapshots = location_service.list_snapshots(db, owner_user_id)
    return {"count": len(snapshots)}
