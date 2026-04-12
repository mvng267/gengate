import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models.base import Base


def create_test_client() -> TestClient:
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
    return TestClient(app)


def clear_overrides() -> None:
    app.dependency_overrides.clear()


def test_auth_login_creates_session_shell_for_existing_user() -> None:
    client = create_test_client()

    register_response = client.post(
        "/auth/register",
        json={"email": "batch31-auth@example.com", "username": "batch31_auth"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]
    uuid.UUID(user_id)

    login_response = client.post(
        "/auth/login",
        json={
            "email": "batch31-auth@example.com",
            "platform": "ios",
            "device_name": "Batch31 iPhone",
        },
    )
    assert login_response.status_code == 200

    payload = login_response.json()
    assert payload["user_id"] == user_id
    assert payload["email"] == "batch31-auth@example.com"
    uuid.UUID(payload["device_id"])
    uuid.UUID(payload["session_id"])
    assert payload["refresh_token"]
    assert payload["token_type"] == "bearer"
    assert payload["bootstrap_mode"] == "password_stub"

    clear_overrides()


def test_auth_login_missing_user_returns_not_found() -> None:
    client = create_test_client()

    login_response = client.post(
        "/auth/login",
        json={
            "email": "missing-user@example.com",
            "platform": "web",
            "device_name": "Missing Browser",
        },
    )
    assert login_response.status_code == 404
    assert login_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    clear_overrides()


def test_auth_refresh_rotates_session_and_session_snapshot_reads_active_session() -> None:
    client = create_test_client()

    register_response = client.post(
        "/auth/register",
        json={"email": "refresh-flow@example.com", "username": "refresh_flow"},
    )
    assert register_response.status_code == 201

    login_response = client.post(
        "/auth/login",
        json={
            "email": "refresh-flow@example.com",
            "platform": "web",
            "device_name": "Batch31 Browser",
        },
    )
    assert login_response.status_code == 200
    login_payload = login_response.json()

    session_response = client.post(
        "/auth/session",
        json={"refresh_token": login_payload["refresh_token"]},
    )
    assert session_response.status_code == 200
    session_payload = session_response.json()
    assert session_payload["user_id"] == login_payload["user_id"]
    assert session_payload["device_id"] == login_payload["device_id"]
    assert session_payload["session_id"] == login_payload["session_id"]
    assert session_payload["session_status"] == "active"

    refresh_response = client.post(
        "/auth/refresh",
        json={"refresh_token": login_payload["refresh_token"]},
    )
    assert refresh_response.status_code == 200
    refresh_payload = refresh_response.json()
    assert refresh_payload["user_id"] == login_payload["user_id"]
    assert refresh_payload["device_id"] == login_payload["device_id"]
    assert refresh_payload["session_id"] != login_payload["session_id"]
    assert refresh_payload["refresh_token"] != login_payload["refresh_token"]
    assert refresh_payload["bootstrap_mode"] == "refresh_token"

    stale_refresh_response = client.post(
        "/auth/session",
        json={"refresh_token": login_payload["refresh_token"]},
    )
    assert stale_refresh_response.status_code == 401
    assert stale_refresh_response.json() == {
        "error": {"code": "session_revoked", "message": "session_revoked"}
    }

    fresh_session_response = client.post(
        "/auth/session",
        json={"refresh_token": refresh_payload["refresh_token"]},
    )
    assert fresh_session_response.status_code == 200
    assert fresh_session_response.json()["session_id"] == refresh_payload["session_id"]

    clear_overrides()


def test_auth_logout_revokes_current_session() -> None:
    client = create_test_client()

    register_response = client.post(
        "/auth/register",
        json={"email": "logout-flow@example.com", "username": "logout_flow"},
    )
    assert register_response.status_code == 201

    login_response = client.post(
        "/auth/login",
        json={
            "email": "logout-flow@example.com",
            "platform": "ios",
            "device_name": "Batch31 iPhone",
        },
    )
    assert login_response.status_code == 200
    login_payload = login_response.json()

    logout_response = client.post(
        "/auth/logout",
        json={"refresh_token": login_payload["refresh_token"]},
    )
    assert logout_response.status_code == 200
    assert logout_response.json()["session_status"] == "revoked"
    assert logout_response.json()["session_id"] == login_payload["session_id"]

    post_logout_session = client.post(
        "/auth/session",
        json={"refresh_token": login_payload["refresh_token"]},
    )
    assert post_logout_session.status_code == 401
    assert post_logout_session.json() == {
        "error": {"code": "session_revoked", "message": "session_revoked"}
    }

    clear_overrides()
