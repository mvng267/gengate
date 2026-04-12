import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models.base import Base


def test_auth_login_creates_session_shell_for_existing_user() -> None:
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

    register_response = client.post(
        "/auth/register",
        json={"email": "batch30-auth@example.com", "username": "batch30_auth"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]
    uuid.UUID(user_id)

    login_response = client.post(
        "/auth/login",
        json={
            "email": "batch30-auth@example.com",
            "platform": "ios",
            "device_name": "Batch30 iPhone",
        },
    )
    assert login_response.status_code == 200

    payload = login_response.json()
    assert payload["user_id"] == user_id
    assert payload["email"] == "batch30-auth@example.com"
    uuid.UUID(payload["device_id"])
    uuid.UUID(payload["session_id"])
    assert payload["refresh_token"]
    assert payload["token_type"] == "bearer"
    assert payload["bootstrap_mode"] == "password_stub"

    app.dependency_overrides.clear()


def test_auth_login_missing_user_returns_not_found() -> None:
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

    app.dependency_overrides.clear()
