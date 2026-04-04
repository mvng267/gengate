import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_batch6_contracts_and_missing_endpoints() -> None:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    testing_session_local = sessionmaker(bind=engine, autocommit=False, autoflush=False, class_=Session)

    def override_db_session():
        db = testing_session_local()
        try:
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

    app.dependency_overrides[get_db_session] = override_db_session
    client = TestClient(app)

    first_register = client.post("/auth/register", json={"email": "batch6@example.com", "username": "batch6"})
    assert first_register.status_code == 201
    user_id = first_register.json()["id"]
    uuid.UUID(user_id)

    duplicate_register = client.post("/auth/register", json={"email": "batch6@example.com", "username": "batch6_dup"})
    assert duplicate_register.status_code == 409
    assert duplicate_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    create_device = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "iPhone"},
    )
    assert create_device.status_code == 201
    device_id = create_device.json()["id"]

    create_key = client.post(
        "/auth/device-keys",
        json={"device_id": device_id, "public_key": "pub", "key_version": 1},
    )
    assert create_key.status_code == 201
    key_id = create_key.json()["id"]

    revoke_key = client.patch(f"/auth/device-keys/{key_id}/revoke")
    assert revoke_key.status_code == 200

    create_recovery = client.post(
        "/auth/recovery-material",
        json={
            "user_id": user_id,
            "encrypted_backup_blob": "blob-v1",
            "recovery_hint": "h1",
            "passphrase_version": 1,
        },
    )
    assert create_recovery.status_code == 201

    update_recovery = client.patch(
        f"/auth/recovery-material/{user_id}",
        json={
            "encrypted_backup_blob": "blob-v2",
            "recovery_hint": "h2",
            "passphrase_version": 2,
        },
    )
    assert update_recovery.status_code == 200
    assert update_recovery.json()["passphrase_version"] == 2

    create_notification = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "system", "payload_json": {"x": 1}},
    )
    assert create_notification.status_code == 201
    notification_id = create_notification.json()["id"]

    get_notification = client.get(f"/notifications/item/{notification_id}")
    assert get_notification.status_code == 200

    create_share = client.post(
        "/locations/shares",
        json={"owner_user_id": user_id, "is_active": True, "sharing_mode": "custom_list"},
    )
    assert create_share.status_code == 201
    share_id = create_share.json()["id"]

    friend_register = client.post("/auth/register", json={"email": "batch6-friend@example.com", "username": "batch6_friend"})
    friend_id = friend_register.json()["id"]

    add_audience = client.post(
        f"/locations/shares/{share_id}/audience",
        json={"allowed_user_id": friend_id},
    )
    assert add_audience.status_code == 201
    audience_id = add_audience.json()["id"]

    remove_audience = client.delete(f"/locations/shares/{share_id}/audience/{audience_id}")
    assert remove_audience.status_code == 200

    list_audience = client.get(f"/locations/shares/{share_id}/audience")
    assert list_audience.status_code == 200
    assert list_audience.json()["count"] == 0

    app.dependency_overrides.clear()
