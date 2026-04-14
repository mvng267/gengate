import uuid
from datetime import datetime, timezone
from types import SimpleNamespace

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

import app.services.notifications as notifications_module
import app.services.security as security_module
from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base
from app.services.notifications import NotificationService
from app.services.security import SecurityService


def test_notifications_device_keys_and_recovery_material_flow() -> None:
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

    user = client.post("/auth/register", json={"email": "secure-user@example.com", "username": "secure_user"})
    user_id = user.json()["id"]

    device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "iPhone"},
    )
    assert device_response.status_code == 201
    device_id = device_response.json()["id"]
    uuid.UUID(device_id)

    create_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": device_id, "public_key": "pub-key", "key_version": 1},
    )
    assert create_key_response.status_code == 201

    list_keys_response = client.get(f"/auth/device-keys/{device_id}")
    assert list_keys_response.status_code == 200
    assert list_keys_response.json()["count"] == 1

    create_recovery_response = client.post(
        "/auth/recovery-material",
        json={
            "user_id": user_id,
            "encrypted_backup_blob": "ciphertext",
            "recovery_hint": "hint",
            "passphrase_version": 1,
        },
    )
    assert create_recovery_response.status_code == 201

    get_recovery_response = client.get(f"/auth/recovery-material/{user_id}")
    assert get_recovery_response.status_code == 200
    assert get_recovery_response.json()["passphrase_version"] == 1

    create_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"x": 1}},
    )
    assert create_notification_response.status_code == 201
    notification_id = create_notification_response.json()["id"]

    list_notifications_response = client.get(f"/notifications/{user_id}")
    assert list_notifications_response.status_code == 200
    assert list_notifications_response.json()["count"] == 1
    assert list_notifications_response.json()["unread_count"] == 1

    read_notification_response = client.patch(f"/notifications/{notification_id}/read")
    assert read_notification_response.status_code == 200

    app.dependency_overrides.clear()


def test_device_key_lifecycle_list_get_revoke_endpoints() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "device-key-lifecycle@example.com", "username": "device_key_lifecycle"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Lifecycle iPhone"},
    )
    assert device_response.status_code == 201
    device_id = device_response.json()["id"]

    create_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": device_id, "public_key": "lifecycle-pub", "key_version": 7},
    )
    assert create_key_response.status_code == 201
    key_id = create_key_response.json()["id"]

    list_keys_response = client.get(f"/auth/device-keys/{device_id}")
    assert list_keys_response.status_code == 200
    assert list_keys_response.json()["count"] == 1
    assert list_keys_response.json()["items"][0]["id"] == key_id

    get_key_response = client.get(f"/auth/device-keys/item/{key_id}")
    assert get_key_response.status_code == 200
    assert get_key_response.json()["id"] == key_id
    assert get_key_response.json()["device_id"] == device_id
    assert get_key_response.json()["revoked_at"] is None

    revoke_key_response = client.patch(f"/auth/device-keys/{key_id}/revoke")
    assert revoke_key_response.status_code == 200
    assert revoke_key_response.json()["id"] == key_id
    assert revoke_key_response.json()["revoked_at"] is not None

    get_revoked_key_response = client.get(f"/auth/device-keys/item/{key_id}")
    assert get_revoked_key_response.status_code == 200
    assert get_revoked_key_response.json()["revoked_at"] is not None

    missing_get_response = client.get(f"/auth/device-keys/item/{uuid.uuid4()}")
    assert missing_get_response.status_code == 404
    assert missing_get_response.json() == {
        "error": {"code": "device_key_not_found", "message": "device_key_not_found"}
    }

    missing_revoke_response = client.patch(f"/auth/device-keys/{uuid.uuid4()}/revoke")
    assert missing_revoke_response.status_code == 404
    assert missing_revoke_response.json() == {
        "error": {"code": "device_key_not_found", "message": "device_key_not_found"}
    }

    app.dependency_overrides.clear()


def test_security_recovery_and_device_key_missing_parent_parity() -> None:
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

    missing_device_id = str(uuid.uuid4())
    missing_list_device_keys_response = client.get(f"/auth/device-keys/{missing_device_id}")
    assert missing_list_device_keys_response.status_code == 404
    assert missing_list_device_keys_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    missing_user_id = str(uuid.uuid4())
    missing_get_recovery_response = client.get(f"/auth/recovery-material/{missing_user_id}")
    assert missing_get_recovery_response.status_code == 404
    assert missing_get_recovery_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_update_recovery_response = client.patch(
        f"/auth/recovery-material/{missing_user_id}",
        json={
            "encrypted_backup_blob": "missing-blob",
            "recovery_hint": "missing-hint",
            "passphrase_version": 3,
        },
    )
    assert missing_update_recovery_response.status_code == 404
    assert missing_update_recovery_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    user_response = client.post(
        "/auth/register",
        json={"email": "recovery-empty@example.com", "username": "recovery_empty"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    empty_get_recovery_response = client.get(f"/auth/recovery-material/{user_id}")
    assert empty_get_recovery_response.status_code == 404
    assert empty_get_recovery_response.json() == {
        "error": {"code": "recovery_not_found", "message": "recovery_not_found"}
    }

    empty_update_recovery_response = client.patch(
        f"/auth/recovery-material/{user_id}",
        json={
            "encrypted_backup_blob": "empty-blob",
            "recovery_hint": "empty-hint",
            "passphrase_version": 1,
        },
    )
    assert empty_update_recovery_response.status_code == 404
    assert empty_update_recovery_response.json() == {
        "error": {"code": "recovery_not_found", "message": "recovery_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch15_revoke_device_cleans_up_sessions_and_device_keys_consistently() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "batch15-device-revoke@example.com", "username": "batch15_device_revoke"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    primary_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Batch15 Primary"},
    )
    backup_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "android", "device_name": "Batch15 Backup"},
    )
    assert primary_device_response.status_code == 201
    assert backup_device_response.status_code == 201
    primary_device_id = primary_device_response.json()["id"]
    backup_device_id = backup_device_response.json()["id"]

    primary_session_1 = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": primary_device_id,
            "refresh_token_hash": "batch15-primary-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    primary_session_2 = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": primary_device_id,
            "refresh_token_hash": "batch15-primary-2",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    backup_session = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": backup_device_id,
            "refresh_token_hash": "batch15-backup-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert primary_session_1.status_code == 201
    assert primary_session_2.status_code == 201
    assert backup_session.status_code == 201

    primary_key_1 = client.post(
        "/auth/device-keys",
        json={"device_id": primary_device_id, "public_key": "batch15-primary-key-1", "key_version": 1},
    )
    primary_key_2 = client.post(
        "/auth/device-keys",
        json={"device_id": primary_device_id, "public_key": "batch15-primary-key-2", "key_version": 2},
    )
    backup_key = client.post(
        "/auth/device-keys",
        json={"device_id": backup_device_id, "public_key": "batch15-backup-key-1", "key_version": 1},
    )
    assert primary_key_1.status_code == 201
    assert primary_key_2.status_code == 201
    assert backup_key.status_code == 201

    primary_session_1_id = primary_session_1.json()["id"]
    primary_session_2_id = primary_session_2.json()["id"]
    backup_session_id = backup_session.json()["id"]
    primary_key_1_id = primary_key_1.json()["id"]
    primary_key_2_id = primary_key_2.json()["id"]
    backup_key_id = backup_key.json()["id"]

    revoke_device_response = client.patch(f"/auth/devices/{primary_device_id}/revoke")
    assert revoke_device_response.status_code == 200
    assert revoke_device_response.json()["id"] == primary_device_id
    assert revoke_device_response.json()["device_trust_state"] == "revoked"

    get_primary_session_1 = client.get(f"/auth/sessions/item/{primary_session_1_id}")
    get_primary_session_2 = client.get(f"/auth/sessions/item/{primary_session_2_id}")
    get_backup_session = client.get(f"/auth/sessions/item/{backup_session_id}")
    assert get_primary_session_1.status_code == 200
    assert get_primary_session_2.status_code == 200
    assert get_backup_session.status_code == 200
    assert get_primary_session_1.json()["revoked_at"] is not None
    assert get_primary_session_2.json()["revoked_at"] is not None
    assert get_backup_session.json()["revoked_at"] is None

    get_primary_key_1 = client.get(f"/auth/device-keys/item/{primary_key_1_id}")
    get_primary_key_2 = client.get(f"/auth/device-keys/item/{primary_key_2_id}")
    get_backup_key = client.get(f"/auth/device-keys/item/{backup_key_id}")
    assert get_primary_key_1.status_code == 200
    assert get_primary_key_2.status_code == 200
    assert get_backup_key.status_code == 200
    assert get_primary_key_1.json()["revoked_at"] is not None
    assert get_primary_key_2.json()["revoked_at"] is not None
    assert get_backup_key.json()["revoked_at"] is None

    get_primary_device = client.get(f"/auth/devices/item/{primary_device_id}")
    get_backup_device = client.get(f"/auth/devices/item/{backup_device_id}")
    assert get_primary_device.status_code == 200
    assert get_backup_device.status_code == 200
    assert get_primary_device.json()["device_trust_state"] == "revoked"
    assert get_backup_device.json()["device_trust_state"] == "trusted"

    app.dependency_overrides.clear()


def test_batch16_revoke_device_and_key_idempotency_with_missing_parent_parity() -> None:
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

    owner_response = client.post(
        "/auth/register",
        json={"email": "batch16-owner@example.com", "username": "batch16_owner"},
    )
    assert owner_response.status_code == 201
    owner_id = owner_response.json()["id"]

    secondary_user_response = client.post(
        "/auth/register",
        json={"email": "batch16-secondary@example.com", "username": "batch16_secondary"},
    )
    assert secondary_user_response.status_code == 201
    secondary_user_id = secondary_user_response.json()["id"]

    owner_device_response = client.post(
        "/auth/devices",
        json={"user_id": owner_id, "platform": "ios", "device_name": "Batch16 Owner Device"},
    )
    assert owner_device_response.status_code == 201
    owner_device_id = owner_device_response.json()["id"]

    secondary_device_response = client.post(
        "/auth/devices",
        json={"user_id": secondary_user_id, "platform": "android", "device_name": "Batch16 Secondary Device"},
    )
    assert secondary_device_response.status_code == 201
    secondary_device_id = secondary_device_response.json()["id"]

    owner_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": owner_id,
            "device_id": owner_device_id,
            "refresh_token_hash": "batch16-owner-session",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert owner_session_response.status_code == 201
    owner_session_id = owner_session_response.json()["id"]

    owner_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": owner_device_id, "public_key": "batch16-owner-key", "key_version": 1},
    )
    assert owner_key_response.status_code == 201
    owner_key_id = owner_key_response.json()["id"]

    secondary_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": secondary_device_id, "public_key": "batch16-secondary-key", "key_version": 1},
    )
    assert secondary_key_response.status_code == 201
    secondary_key_id = secondary_key_response.json()["id"]

    first_device_revoke_response = client.patch(f"/auth/devices/{owner_device_id}/revoke")
    assert first_device_revoke_response.status_code == 200
    assert first_device_revoke_response.json()["device_trust_state"] == "revoked"

    first_session_state = client.get(f"/auth/sessions/item/{owner_session_id}")
    first_key_state = client.get(f"/auth/device-keys/item/{owner_key_id}")
    assert first_session_state.status_code == 200
    assert first_key_state.status_code == 200
    first_session_revoked_at = first_session_state.json()["revoked_at"]
    first_key_revoked_at = first_key_state.json()["revoked_at"]
    assert first_session_revoked_at is not None
    assert first_key_revoked_at is not None

    second_device_revoke_response = client.patch(f"/auth/devices/{owner_device_id}/revoke")
    assert second_device_revoke_response.status_code == 200
    assert second_device_revoke_response.json()["device_trust_state"] == "revoked"

    second_session_state = client.get(f"/auth/sessions/item/{owner_session_id}")
    second_key_state = client.get(f"/auth/device-keys/item/{owner_key_id}")
    assert second_session_state.status_code == 200
    assert second_key_state.status_code == 200
    assert second_session_state.json()["revoked_at"] == first_session_revoked_at
    assert second_key_state.json()["revoked_at"] == first_key_revoked_at

    secondary_key_state = client.get(f"/auth/device-keys/item/{secondary_key_id}")
    assert secondary_key_state.status_code == 200
    assert secondary_key_state.json()["revoked_at"] is None

    first_key_revoke_response = client.patch(f"/auth/device-keys/{owner_key_id}/revoke")
    assert first_key_revoke_response.status_code == 200
    assert first_key_revoke_response.json()["revoked_at"] == first_key_revoked_at

    second_key_revoke_response = client.patch(f"/auth/device-keys/{owner_key_id}/revoke")
    assert second_key_revoke_response.status_code == 200
    assert second_key_revoke_response.json()["revoked_at"] == first_key_revoked_at

    missing_user_create_device_response = client.post(
        "/auth/devices",
        json={"user_id": str(uuid.uuid4()), "platform": "ios", "device_name": "Batch16 Missing User Device"},
    )
    assert missing_user_create_device_response.status_code == 404
    assert missing_user_create_device_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_device_create_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": str(uuid.uuid4()), "public_key": "batch16-missing-device-key", "key_version": 1},
    )
    assert missing_device_create_key_response.status_code == 404
    assert missing_device_create_key_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch16_revoke_device_repeated_call_skips_parent_write() -> None:
    service = SecurityService()
    now = datetime.now(timezone.utc)

    device = SimpleNamespace(id=uuid.uuid4(), device_trust_state="trusted")
    session = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)
    key = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)

    class FakeDeviceRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def get(self, db, device_id):
            assert device_id == device.id
            return device

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    class FakeSessionRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def list_by_device_id(self, db, device_id):
            assert device_id == device.id
            return [session]

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    class FakeDeviceKeyRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def list_by_device_id(self, db, device_id):
            assert device_id == device.id
            return [key]

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    fake_device_repository = FakeDeviceRepository()
    fake_session_repository = FakeSessionRepository()
    fake_device_key_repository = FakeDeviceKeyRepository()

    original_device_repository = security_module.device_repository
    original_session_repository = security_module.session_repository
    original_device_key_repository = security_module.device_key_repository

    security_module.device_repository = fake_device_repository
    security_module.session_repository = fake_session_repository
    security_module.device_key_repository = fake_device_key_repository

    try:
        first_device = service.revoke_device(db=None, device_id=device.id)
        assert first_device.device_trust_state == "revoked"
        assert fake_device_repository.update_calls == 1
        assert fake_session_repository.update_calls == 1
        assert fake_device_key_repository.update_calls == 1
        first_session_revoked_at = session.revoked_at
        first_key_revoked_at = key.revoked_at

        second_device = service.revoke_device(db=None, device_id=device.id)
        assert second_device.device_trust_state == "revoked"
        assert fake_device_repository.update_calls == 1
        assert fake_session_repository.update_calls == 1
        assert fake_device_key_repository.update_calls == 1
        assert session.revoked_at == first_session_revoked_at
        assert key.revoked_at == first_key_revoked_at
        assert session.revoked_at is not None
        assert key.revoked_at is not None
        assert session.revoked_at >= now
        assert key.revoked_at >= now
    finally:
        security_module.device_repository = original_device_repository
        security_module.session_repository = original_session_repository
        security_module.device_key_repository = original_device_key_repository


def test_batch16_revoke_device_key_repeated_call_skips_second_write() -> None:
    service = SecurityService()
    device_key = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)

    class FakeDeviceKeyRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def get(self, db, key_id):
            assert key_id == device_key.id
            return device_key

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    fake_device_key_repository = FakeDeviceKeyRepository()
    original_device_key_repository = security_module.device_key_repository
    security_module.device_key_repository = fake_device_key_repository

    try:
        first_key = service.revoke_device_key(db=None, key_id=device_key.id)
        assert first_key.revoked_at is not None
        assert fake_device_key_repository.update_calls == 1
        first_revoked_at = first_key.revoked_at

        second_key = service.revoke_device_key(db=None, key_id=device_key.id)
        assert second_key.revoked_at == first_revoked_at
        assert fake_device_key_repository.update_calls == 1
    finally:
        security_module.device_key_repository = original_device_key_repository


def test_batch17_notifications_unread_and_delete_lifecycle_endpoints() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "batch17-notify@example.com", "username": "batch17_notify"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    first_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"x": 1}},
    )
    second_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "moment_like", "payload_json": {"x": 2}},
    )
    assert first_notification_response.status_code == 201
    assert second_notification_response.status_code == 201
    first_notification_id = first_notification_response.json()["id"]
    second_notification_id = second_notification_response.json()["id"]

    read_response = client.patch(f"/notifications/{first_notification_id}/read")
    assert read_response.status_code == 200
    assert read_response.json()["read_at"] is not None

    unread_response = client.patch(f"/notifications/{first_notification_id}/unread")
    assert unread_response.status_code == 200
    assert unread_response.json()["read_at"] is None

    delete_response = client.delete(f"/notifications/{first_notification_id}")
    assert delete_response.status_code == 200
    assert delete_response.json()["id"] == first_notification_id

    get_deleted_response = client.get(f"/notifications/item/{first_notification_id}")
    assert get_deleted_response.status_code == 404
    assert get_deleted_response.json() == {
        "error": {"code": "notification_not_found", "message": "notification_not_found"}
    }

    delete_missing_response = client.delete(f"/notifications/{first_notification_id}")
    assert delete_missing_response.status_code == 200
    assert delete_missing_response.json()["id"] == first_notification_id

    list_notifications_response = client.get(f"/notifications/{user_id}")
    assert list_notifications_response.status_code == 200
    assert list_notifications_response.json()["count"] == 1
    assert list_notifications_response.json()["unread_count"] == 1
    assert list_notifications_response.json()["total_unread_count"] == 1
    assert list_notifications_response.json()["items"][0]["id"] == second_notification_id

    app.dependency_overrides.clear()


def test_batch18_notifications_reread_repeated_unread_delete_and_missing_parent_parity() -> None:
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

    missing_user_id = str(uuid.uuid4())
    missing_user_list_response = client.get(f"/notifications/{missing_user_id}")
    assert missing_user_list_response.status_code == 404
    assert missing_user_list_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_user_create_response = client.post(
        "/notifications",
        json={"user_id": missing_user_id, "notification_type": "friend_request", "payload_json": {"x": 0}},
    )
    assert missing_user_create_response.status_code == 404
    assert missing_user_create_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    user_response = client.post(
        "/auth/register",
        json={"email": "batch18-notify@example.com", "username": "batch18_notify"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"x": 18}},
    )
    assert notification_response.status_code == 201
    notification_id = notification_response.json()["id"]

    first_read_response = client.patch(f"/notifications/{notification_id}/read")
    assert first_read_response.status_code == 200
    first_read_at = first_read_response.json()["read_at"]
    assert first_read_at is not None

    second_read_response = client.patch(f"/notifications/{notification_id}/read")
    assert second_read_response.status_code == 200
    assert second_read_response.json()["read_at"] == first_read_at

    first_unread_response = client.patch(f"/notifications/{notification_id}/unread")
    assert first_unread_response.status_code == 200
    assert first_unread_response.json()["read_at"] is None

    second_unread_response = client.patch(f"/notifications/{notification_id}/unread")
    assert second_unread_response.status_code == 200
    assert second_unread_response.json()["read_at"] is None

    first_delete_response = client.delete(f"/notifications/{notification_id}")
    assert first_delete_response.status_code == 200

    second_delete_response = client.delete(f"/notifications/{notification_id}")
    assert second_delete_response.status_code == 200
    assert second_delete_response.json()["id"] == notification_id

    missing_notification_delete_response = client.delete(f"/notifications/{uuid.uuid4()}")
    assert missing_notification_delete_response.status_code == 404
    assert missing_notification_delete_response.json() == {
        "error": {"code": "notification_not_found", "message": "notification_not_found"}
    }

    read_after_delete_response = client.patch(f"/notifications/{notification_id}/read")
    assert read_after_delete_response.status_code == 404
    assert read_after_delete_response.json() == {
        "error": {"code": "notification_not_found", "message": "notification_not_found"}
    }

    unread_after_delete_response = client.patch(f"/notifications/{notification_id}/unread")
    assert unread_after_delete_response.status_code == 404
    assert unread_after_delete_response.json() == {
        "error": {"code": "notification_not_found", "message": "notification_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch18_notification_mark_read_unread_repeated_calls_skip_second_write() -> None:
    service = NotificationService()
    notification = SimpleNamespace(id=uuid.uuid4(), read_at=None)

    class FakeNotificationRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def get(self, db, notification_id):
            assert notification_id == notification.id
            return notification

        def get_active(self, db, notification_id):
            assert notification_id == notification.id
            return notification

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    fake_notification_repository = FakeNotificationRepository()
    original_notification_repository = notifications_module.notification_repository
    notifications_module.notification_repository = fake_notification_repository

    try:
        first_read = service.mark_read(db=None, notification_id=notification.id)
        assert first_read.read_at is not None
        first_read_at = first_read.read_at
        assert fake_notification_repository.update_calls == 1

        second_read = service.mark_read(db=None, notification_id=notification.id)
        assert second_read.read_at == first_read_at
        assert fake_notification_repository.update_calls == 1

        first_unread = service.mark_unread(db=None, notification_id=notification.id)
        assert first_unread.read_at is None
        assert fake_notification_repository.update_calls == 2

        second_unread = service.mark_unread(db=None, notification_id=notification.id)
        assert second_unread.read_at is None
        assert fake_notification_repository.update_calls == 2
    finally:
        notifications_module.notification_repository = original_notification_repository


def test_notifications_list_unread_only_query_parity() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "batch237-notify@example.com", "username": "batch237_notify"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    first_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"x": 1}},
    )
    second_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "moment_like", "payload_json": {"x": 2}},
    )
    assert first_notification_response.status_code == 201
    assert second_notification_response.status_code == 201

    first_notification_id = first_notification_response.json()["id"]
    second_notification_id = second_notification_response.json()["id"]

    mark_read_response = client.patch(f"/notifications/{first_notification_id}/read")
    assert mark_read_response.status_code == 200

    all_notifications_response = client.get(f"/notifications/{user_id}")
    assert all_notifications_response.status_code == 200
    assert all_notifications_response.json()["count"] == 2
    assert all_notifications_response.json()["unread_count"] == 1
    assert all_notifications_response.json()["total_unread_count"] == 1

    unread_only_response = client.get(f"/notifications/{user_id}?unread_only=true")
    assert unread_only_response.status_code == 200
    unread_items = unread_only_response.json()["items"]
    assert unread_only_response.json()["count"] == 1
    assert unread_only_response.json()["unread_count"] == 1
    assert unread_only_response.json()["total_unread_count"] == 1
    assert unread_items[0]["id"] == second_notification_id
    assert unread_items[0]["read_at"] is None

    mark_unread_response = client.patch(f"/notifications/{first_notification_id}/unread")
    assert mark_unread_response.status_code == 200

    unread_only_after_toggle_response = client.get(f"/notifications/{user_id}?unread_only=true")
    assert unread_only_after_toggle_response.status_code == 200
    unread_after_toggle_ids = {item["id"] for item in unread_only_after_toggle_response.json()["items"]}
    assert unread_only_after_toggle_response.json()["count"] == 2
    assert unread_only_after_toggle_response.json()["unread_count"] == 2
    assert unread_only_after_toggle_response.json()["total_unread_count"] == 2
    assert unread_after_toggle_ids == {first_notification_id, second_notification_id}

    app.dependency_overrides.clear()


def test_notifications_list_unread_count_stays_zero_when_all_are_read() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "batch238-notify@example.com", "username": "batch238_notify"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    first_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"x": 1}},
    )
    second_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "moment_like", "payload_json": {"x": 2}},
    )
    assert first_notification_response.status_code == 201
    assert second_notification_response.status_code == 201

    first_notification_id = first_notification_response.json()["id"]
    second_notification_id = second_notification_response.json()["id"]

    first_read_response = client.patch(f"/notifications/{first_notification_id}/read")
    second_read_response = client.patch(f"/notifications/{second_notification_id}/read")
    assert first_read_response.status_code == 200
    assert second_read_response.status_code == 200

    all_notifications_response = client.get(f"/notifications/{user_id}")
    assert all_notifications_response.status_code == 200
    assert all_notifications_response.json()["count"] == 2
    assert all_notifications_response.json()["unread_count"] == 0
    assert all_notifications_response.json()["total_unread_count"] == 0

    unread_only_response = client.get(f"/notifications/{user_id}?unread_only=true")
    assert unread_only_response.status_code == 200
    assert unread_only_response.json()["count"] == 0
    assert unread_only_response.json()["unread_count"] == 0
    assert unread_only_response.json()["total_unread_count"] == 0

    app.dependency_overrides.clear()


def test_notifications_list_pagination_and_sorting_parity() -> None:
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

    user_response = client.post(
        "/auth/register",
        json={"email": "batch239-notify@example.com", "username": "batch239_notify"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    first_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "friend_request", "payload_json": {"order": 1}},
    )
    second_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "moment_like", "payload_json": {"order": 2}},
    )
    third_notification_response = client.post(
        "/notifications",
        json={"user_id": user_id, "notification_type": "system", "payload_json": {"order": 3}},
    )
    assert first_notification_response.status_code == 201
    assert second_notification_response.status_code == 201
    assert third_notification_response.status_code == 201

    first_notification_id = first_notification_response.json()["id"]
    second_notification_id = second_notification_response.json()["id"]
    third_notification_id = third_notification_response.json()["id"]

    mark_read_response = client.patch(f"/notifications/{second_notification_id}/read")
    assert mark_read_response.status_code == 200

    page_one_response = client.get(f"/notifications/{user_id}?limit=2&offset=0")
    assert page_one_response.status_code == 200
    assert page_one_response.json()["count"] == 2
    assert page_one_response.json()["unread_count"] == 1
    assert page_one_response.json()["total_unread_count"] == 2
    page_one_ids = [item["id"] for item in page_one_response.json()["items"]]
    assert page_one_ids == [third_notification_id, second_notification_id]

    page_two_response = client.get(f"/notifications/{user_id}?limit=2&offset=2")
    assert page_two_response.status_code == 200
    assert page_two_response.json()["count"] == 1
    assert page_two_response.json()["unread_count"] == 1
    assert page_two_response.json()["total_unread_count"] == 2
    page_two_ids = [item["id"] for item in page_two_response.json()["items"]]
    assert page_two_ids == [first_notification_id]

    unread_page_one_response = client.get(f"/notifications/{user_id}?unread_only=true&limit=1&offset=0")
    assert unread_page_one_response.status_code == 200
    assert unread_page_one_response.json()["count"] == 1
    assert unread_page_one_response.json()["unread_count"] == 1
    assert unread_page_one_response.json()["total_unread_count"] == 2
    unread_page_one_ids = [item["id"] for item in unread_page_one_response.json()["items"]]
    assert unread_page_one_ids == [third_notification_id]

    unread_page_two_response = client.get(f"/notifications/{user_id}?unread_only=true&limit=1&offset=1")
    assert unread_page_two_response.status_code == 200
    assert unread_page_two_response.json()["count"] == 1
    assert unread_page_two_response.json()["unread_count"] == 1
    assert unread_page_two_response.json()["total_unread_count"] == 2
    unread_page_two_ids = [item["id"] for item in unread_page_two_response.json()["items"]]
    assert unread_page_two_ids == [first_notification_id]

    app.dependency_overrides.clear()
