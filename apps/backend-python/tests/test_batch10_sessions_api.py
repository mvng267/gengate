import uuid
from types import SimpleNamespace

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

import app.services.sessions as sessions_module
from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base
from app.services.sessions import SessionService


def test_batch10_sessions_api_flow() -> None:
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
        json={"email": "batch10-session-user@example.com", "username": "batch10_session_user"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]
    uuid.UUID(user_id)

    device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Batch10 iPhone"},
    )
    assert device_response.status_code == 201
    device_id = device_response.json()["id"]
    uuid.UUID(device_id)

    create_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": device_id,
            "refresh_token_hash": "refresh-hash-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert create_session_response.status_code == 201
    session_id = create_session_response.json()["id"]
    uuid.UUID(session_id)
    assert create_session_response.json()["user_id"] == user_id
    assert create_session_response.json()["device_id"] == device_id

    list_devices_response = client.get(f"/auth/devices/{user_id}")
    assert list_devices_response.status_code == 200
    assert list_devices_response.json()["count"] == 1
    assert list_devices_response.json()["items"][0]["id"] == device_id

    get_device_response = client.get(f"/auth/devices/item/{device_id}")
    assert get_device_response.status_code == 200
    assert get_device_response.json()["id"] == device_id
    assert get_device_response.json()["user_id"] == user_id

    list_sessions_response = client.get(f"/auth/sessions/{user_id}")
    assert list_sessions_response.status_code == 200
    assert list_sessions_response.json()["count"] == 1
    assert list_sessions_response.json()["items"][0]["id"] == session_id

    get_session_response = client.get(f"/auth/sessions/item/{session_id}")
    assert get_session_response.status_code == 200
    assert get_session_response.json()["id"] == session_id
    assert get_session_response.json()["user_id"] == user_id
    assert get_session_response.json()["device_id"] == device_id
    assert get_session_response.json()["revoked_at"] is None

    revoke_session_response = client.patch(f"/auth/sessions/{session_id}/revoke")
    assert revoke_session_response.status_code == 200
    assert revoke_session_response.json()["id"] == session_id
    assert revoke_session_response.json()["revoked_at"] is not None

    get_revoked_session_response = client.get(f"/auth/sessions/item/{session_id}")
    assert get_revoked_session_response.status_code == 200
    assert get_revoked_session_response.json()["revoked_at"] is not None

    app.dependency_overrides.clear()


def test_batch10_sessions_device_user_mismatch() -> None:
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

    user_a_response = client.post(
        "/auth/register",
        json={"email": "batch10-a@example.com", "username": "batch10_a"},
    )
    user_b_response = client.post(
        "/auth/register",
        json={"email": "batch10-b@example.com", "username": "batch10_b"},
    )
    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]

    device_response = client.post(
        "/auth/devices",
        json={"user_id": user_b_id, "platform": "android", "device_name": "Batch10 Pixel"},
    )
    assert device_response.status_code == 201
    device_id = device_response.json()["id"]

    create_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_a_id,
            "device_id": device_id,
            "refresh_token_hash": "refresh-hash-mismatch",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert create_session_response.status_code == 404
    assert create_session_response.json() == {
        "error": {"code": "device_user_mismatch", "message": "device_user_mismatch"}
    }

    missing_device_response = client.get(f"/auth/devices/item/{uuid.uuid4()}")
    assert missing_device_response.status_code == 404
    assert missing_device_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    missing_session_response = client.get(f"/auth/sessions/item/{uuid.uuid4()}")
    assert missing_session_response.status_code == 404
    assert missing_session_response.json() == {
        "error": {"code": "session_not_found", "message": "session_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch10_sessions_list_missing_user_parity() -> None:
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
    list_sessions_response = client.get(f"/auth/sessions/{missing_user_id}")
    assert list_sessions_response.status_code == 404
    assert list_sessions_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch14_revoke_all_sessions_per_user_with_device_consistency() -> None:
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

    user_a_response = client.post(
        "/auth/register",
        json={"email": "batch14-user-a@example.com", "username": "batch14_user_a"},
    )
    user_b_response = client.post(
        "/auth/register",
        json={"email": "batch14-user-b@example.com", "username": "batch14_user_b"},
    )
    assert user_a_response.status_code == 201
    assert user_b_response.status_code == 201
    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]

    user_a_device_1 = client.post(
        "/auth/devices",
        json={"user_id": user_a_id, "platform": "ios", "device_name": "Batch14 iPhone"},
    )
    user_a_device_2 = client.post(
        "/auth/devices",
        json={"user_id": user_a_id, "platform": "android", "device_name": "Batch14 Pixel"},
    )
    user_b_device = client.post(
        "/auth/devices",
        json={"user_id": user_b_id, "platform": "ios", "device_name": "Batch14 Friend iPhone"},
    )
    assert user_a_device_1.status_code == 201
    assert user_a_device_2.status_code == 201
    assert user_b_device.status_code == 201

    user_a_device_1_id = user_a_device_1.json()["id"]
    user_a_device_2_id = user_a_device_2.json()["id"]
    user_b_device_id = user_b_device.json()["id"]

    user_a_session_1 = client.post(
        "/auth/sessions",
        json={
            "user_id": user_a_id,
            "device_id": user_a_device_1_id,
            "refresh_token_hash": "batch14-a-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    user_a_session_2 = client.post(
        "/auth/sessions",
        json={
            "user_id": user_a_id,
            "device_id": user_a_device_2_id,
            "refresh_token_hash": "batch14-a-2",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    user_b_session = client.post(
        "/auth/sessions",
        json={
            "user_id": user_b_id,
            "device_id": user_b_device_id,
            "refresh_token_hash": "batch14-b-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert user_a_session_1.status_code == 201
    assert user_a_session_2.status_code == 201
    assert user_b_session.status_code == 201

    user_b_session_id = user_b_session.json()["id"]

    revoke_all_response = client.patch(f"/auth/sessions/{user_a_id}/revoke-all")
    assert revoke_all_response.status_code == 200
    assert revoke_all_response.json()["count"] == 2
    revoked_ids = {item["id"] for item in revoke_all_response.json()["items"]}
    assert revoked_ids == {user_a_session_1.json()["id"], user_a_session_2.json()["id"]}
    assert all(item["revoked_at"] is not None for item in revoke_all_response.json()["items"])

    list_user_a_sessions = client.get(f"/auth/sessions/{user_a_id}")
    assert list_user_a_sessions.status_code == 200
    assert list_user_a_sessions.json()["count"] == 2
    assert all(item["revoked_at"] is not None for item in list_user_a_sessions.json()["items"])

    get_user_b_session = client.get(f"/auth/sessions/item/{user_b_session_id}")
    assert get_user_b_session.status_code == 200
    assert get_user_b_session.json()["revoked_at"] is None

    app.dependency_overrides.clear()


def test_batch14_revoke_all_sessions_per_device_and_missing_parent_parity() -> None:
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
        json={"email": "batch14-device-owner@example.com", "username": "batch14_device_owner"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    primary_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Batch14 Primary"},
    )
    backup_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "android", "device_name": "Batch14 Backup"},
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
            "refresh_token_hash": "batch14-primary-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    primary_session_2 = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": primary_device_id,
            "refresh_token_hash": "batch14-primary-2",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    backup_session = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": backup_device_id,
            "refresh_token_hash": "batch14-backup-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert primary_session_1.status_code == 201
    assert primary_session_2.status_code == 201
    assert backup_session.status_code == 201

    backup_session_id = backup_session.json()["id"]

    revoke_primary_device_sessions = client.patch(f"/auth/sessions/device/{primary_device_id}/revoke-all")
    assert revoke_primary_device_sessions.status_code == 200
    assert revoke_primary_device_sessions.json()["count"] == 2
    assert {item["device_id"] for item in revoke_primary_device_sessions.json()["items"]} == {primary_device_id}
    assert all(item["revoked_at"] is not None for item in revoke_primary_device_sessions.json()["items"])

    get_backup_session = client.get(f"/auth/sessions/item/{backup_session_id}")
    assert get_backup_session.status_code == 200
    assert get_backup_session.json()["revoked_at"] is None

    missing_device_response = client.patch(f"/auth/sessions/device/{uuid.uuid4()}/revoke-all")
    assert missing_device_response.status_code == 404
    assert missing_device_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch15_revoke_device_cleans_related_sessions_and_device_keys() -> None:
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
        json={"email": "batch15-device-owner@example.com", "username": "batch15_device_owner"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    revoked_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Batch15 Revoked Device"},
    )
    keep_device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "android", "device_name": "Batch15 Keep Device"},
    )
    assert revoked_device_response.status_code == 201
    assert keep_device_response.status_code == 201
    revoked_device_id = revoked_device_response.json()["id"]
    keep_device_id = keep_device_response.json()["id"]

    revoked_session_1_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": revoked_device_id,
            "refresh_token_hash": "batch15-revoked-session-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    revoked_session_2_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": revoked_device_id,
            "refresh_token_hash": "batch15-revoked-session-2",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    keep_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": keep_device_id,
            "refresh_token_hash": "batch15-keep-session-1",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert revoked_session_1_response.status_code == 201
    assert revoked_session_2_response.status_code == 201
    assert keep_session_response.status_code == 201

    revoked_session_1_id = revoked_session_1_response.json()["id"]
    revoked_session_2_id = revoked_session_2_response.json()["id"]
    keep_session_id = keep_session_response.json()["id"]

    revoked_device_key_1_response = client.post(
        "/auth/device-keys",
        json={"device_id": revoked_device_id, "public_key": "batch15-revoked-key-1", "key_version": 1},
    )
    revoked_device_key_2_response = client.post(
        "/auth/device-keys",
        json={"device_id": revoked_device_id, "public_key": "batch15-revoked-key-2", "key_version": 2},
    )
    keep_device_key_response = client.post(
        "/auth/device-keys",
        json={"device_id": keep_device_id, "public_key": "batch15-keep-key-1", "key_version": 1},
    )
    assert revoked_device_key_1_response.status_code == 201
    assert revoked_device_key_2_response.status_code == 201
    assert keep_device_key_response.status_code == 201

    revoke_device_response = client.patch(f"/auth/devices/{revoked_device_id}/revoke")
    assert revoke_device_response.status_code == 200
    assert revoke_device_response.json()["id"] == revoked_device_id
    assert revoke_device_response.json()["device_trust_state"] == "revoked"

    get_revoked_device_response = client.get(f"/auth/devices/item/{revoked_device_id}")
    assert get_revoked_device_response.status_code == 200
    assert get_revoked_device_response.json()["device_trust_state"] == "revoked"

    list_sessions_response = client.get(f"/auth/sessions/{user_id}")
    assert list_sessions_response.status_code == 200
    assert list_sessions_response.json()["count"] == 3
    sessions_by_id = {item["id"]: item for item in list_sessions_response.json()["items"]}
    assert sessions_by_id[revoked_session_1_id]["revoked_at"] is not None
    assert sessions_by_id[revoked_session_2_id]["revoked_at"] is not None
    assert sessions_by_id[keep_session_id]["revoked_at"] is None

    list_revoked_device_keys_response = client.get(f"/auth/device-keys/{revoked_device_id}")
    assert list_revoked_device_keys_response.status_code == 200
    assert list_revoked_device_keys_response.json()["count"] == 2
    assert all(item["revoked_at"] is not None for item in list_revoked_device_keys_response.json()["items"])

    list_keep_device_keys_response = client.get(f"/auth/device-keys/{keep_device_id}")
    assert list_keep_device_keys_response.status_code == 200
    assert list_keep_device_keys_response.json()["count"] == 1
    assert list_keep_device_keys_response.json()["items"][0]["revoked_at"] is None

    missing_device_response = client.patch(f"/auth/devices/{uuid.uuid4()}/revoke")
    assert missing_device_response.status_code == 404
    assert missing_device_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch16_revoke_session_idempotency_and_missing_parent_parity() -> None:
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
        json={"email": "batch16-session-user@example.com", "username": "batch16_session_user"},
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]

    device_response = client.post(
        "/auth/devices",
        json={"user_id": user_id, "platform": "ios", "device_name": "Batch16 iPhone"},
    )
    assert device_response.status_code == 201
    device_id = device_response.json()["id"]

    create_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": device_id,
            "refresh_token_hash": "batch16-refresh-hash",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert create_session_response.status_code == 201
    session_id = create_session_response.json()["id"]

    first_revoke_response = client.patch(f"/auth/sessions/{session_id}/revoke")
    assert first_revoke_response.status_code == 200
    first_revoked_at = first_revoke_response.json()["revoked_at"]
    assert first_revoked_at is not None

    second_revoke_response = client.patch(f"/auth/sessions/{session_id}/revoke")
    assert second_revoke_response.status_code == 200
    assert second_revoke_response.json()["revoked_at"] == first_revoked_at

    get_session_response = client.get(f"/auth/sessions/item/{session_id}")
    assert get_session_response.status_code == 200
    assert get_session_response.json()["revoked_at"] == first_revoked_at

    missing_session_revoke_response = client.patch(f"/auth/sessions/{uuid.uuid4()}/revoke")
    assert missing_session_revoke_response.status_code == 404
    assert missing_session_revoke_response.json() == {
        "error": {"code": "session_not_found", "message": "session_not_found"}
    }

    missing_user_revoke_all_response = client.patch(f"/auth/sessions/{uuid.uuid4()}/revoke-all")
    assert missing_user_revoke_all_response.status_code == 404
    assert missing_user_revoke_all_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_user_create_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": str(uuid.uuid4()),
            "device_id": device_id,
            "refresh_token_hash": "batch16-missing-user",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert missing_user_create_session_response.status_code == 404
    assert missing_user_create_session_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_device_create_session_response = client.post(
        "/auth/sessions",
        json={
            "user_id": user_id,
            "device_id": str(uuid.uuid4()),
            "refresh_token_hash": "batch16-missing-device",
            "expires_at": "2030-01-01T00:00:00Z",
        },
    )
    assert missing_device_create_session_response.status_code == 404
    assert missing_device_create_session_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch16_revoke_session_repeated_call_skips_second_write() -> None:
    service = SessionService()
    auth_session = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)

    class FakeSessionRepository:
        def __init__(self) -> None:
            self.update_calls = 0

        def get(self, db, session_id):
            assert session_id == auth_session.id
            return auth_session

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    fake_session_repository = FakeSessionRepository()
    original_session_repository = sessions_module.session_repository
    sessions_module.session_repository = fake_session_repository

    try:
        first_session = service.revoke_session(db=None, session_id=auth_session.id)
        assert first_session.revoked_at is not None
        assert fake_session_repository.update_calls == 1
        first_revoked_at = first_session.revoked_at

        second_session = service.revoke_session(db=None, session_id=auth_session.id)
        assert second_session.revoked_at == first_revoked_at
        assert fake_session_repository.update_calls == 1
    finally:
        sessions_module.session_repository = original_session_repository


def test_batch19_revoke_all_sessions_repeated_call_skips_second_write() -> None:
    service = SessionService()
    session_a = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)
    session_b = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)
    sessions = [session_a, session_b]
    user = SimpleNamespace(id=uuid.uuid4())

    class FakeSessionRepository:
        def __init__(self) -> None:
            self.update_calls = 0
            self.list_by_user_calls = 0

        def list_by_user_id(self, db, user_id):
            assert user_id == user.id
            self.list_by_user_calls += 1
            return sessions

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    class FakeUserRepository:
        def get(self, db, user_id):
            assert user_id == user.id
            return user

    fake_session_repository = FakeSessionRepository()
    fake_user_repository = FakeUserRepository()
    original_session_repository = sessions_module.session_repository
    original_user_repository = sessions_module.user_repository
    sessions_module.session_repository = fake_session_repository
    sessions_module.user_repository = fake_user_repository

    try:
        first_result = service.revoke_all_sessions_for_user(db=None, user_id=user.id)
        assert len(first_result) == 2
        assert fake_session_repository.update_calls == 2
        first_revoked_at = [item.revoked_at for item in first_result]
        assert all(timestamp is not None for timestamp in first_revoked_at)

        second_result = service.revoke_all_sessions_for_user(db=None, user_id=user.id)
        assert len(second_result) == 2
        assert fake_session_repository.update_calls == 2
        assert [item.revoked_at for item in second_result] == first_revoked_at
        assert fake_session_repository.list_by_user_calls == 2
    finally:
        sessions_module.session_repository = original_session_repository
        sessions_module.user_repository = original_user_repository


def test_batch19_revoke_all_device_sessions_repeated_call_skips_second_write() -> None:
    service = SessionService()
    session_a = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)
    session_b = SimpleNamespace(id=uuid.uuid4(), revoked_at=None)
    sessions = [session_a, session_b]
    device = SimpleNamespace(id=uuid.uuid4())

    class FakeSessionRepository:
        def __init__(self) -> None:
            self.update_calls = 0
            self.list_by_device_calls = 0

        def list_by_device_id(self, db, device_id):
            assert device_id == device.id
            self.list_by_device_calls += 1
            return sessions

        def update(self, db, entity, **data):
            self.update_calls += 1
            for field, value in data.items():
                setattr(entity, field, value)
            return entity

    class FakeDeviceRepository:
        def get(self, db, device_id):
            assert device_id == device.id
            return device

    fake_session_repository = FakeSessionRepository()
    fake_device_repository = FakeDeviceRepository()
    original_session_repository = sessions_module.session_repository
    original_device_repository = sessions_module.device_repository
    sessions_module.session_repository = fake_session_repository
    sessions_module.device_repository = fake_device_repository

    try:
        first_result = service.revoke_all_sessions_for_device(db=None, device_id=device.id)
        assert len(first_result) == 2
        assert fake_session_repository.update_calls == 2
        first_revoked_at = [item.revoked_at for item in first_result]
        assert all(timestamp is not None for timestamp in first_revoked_at)

        second_result = service.revoke_all_sessions_for_device(db=None, device_id=device.id)
        assert len(second_result) == 2
        assert fake_session_repository.update_calls == 2
        assert [item.revoked_at for item in second_result] == first_revoked_at
        assert fake_session_repository.list_by_device_calls == 2
    finally:
        sessions_module.session_repository = original_session_repository
        sessions_module.device_repository = original_device_repository
