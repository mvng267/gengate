import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_location_share_audience_flow() -> None:
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

    owner = client.post("/auth/register", json={"email": "owner@example.com", "username": "owner_u"})
    friend = client.post("/auth/register", json={"email": "friend@example.com", "username": "friend_u"})
    owner_id = owner.json()["id"]
    friend_id = friend.json()["id"]
    uuid.UUID(owner_id)
    uuid.UUID(friend_id)

    share_response = client.post(
        "/locations/shares",
        json={"owner_user_id": owner_id, "is_active": True, "sharing_mode": "custom_list"},
    )
    assert share_response.status_code == 201
    share_id = share_response.json()["id"]

    add_audience_response = client.post(
        f"/locations/shares/{share_id}/audience",
        json={"allowed_user_id": friend_id},
    )
    assert add_audience_response.status_code == 201

    list_audience_response = client.get(f"/locations/shares/{share_id}/audience")
    assert list_audience_response.status_code == 200
    assert list_audience_response.json()["count"] == 1

    app.dependency_overrides.clear()


def test_location_share_audience_list_missing_share_returns_404() -> None:
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

    missing_share_id = str(uuid.uuid4())
    list_audience_response = client.get(f"/locations/shares/{missing_share_id}/audience")

    assert list_audience_response.status_code == 404
    assert list_audience_response.json()["error"]["code"] == "share_not_found"

    app.dependency_overrides.clear()


def test_location_share_audience_remove_flow_and_duplicate_guard() -> None:
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

    owner = client.post("/auth/register", json={"email": "aud-remove-owner@example.com", "username": "aud_remove_owner"})
    friend = client.post("/auth/register", json={"email": "aud-remove-friend@example.com", "username": "aud_remove_friend"})
    assert owner.status_code == 201
    assert friend.status_code == 201
    owner_id = owner.json()["id"]
    friend_id = friend.json()["id"]

    share_response = client.post(
        "/locations/shares",
        json={"owner_user_id": owner_id, "is_active": True, "sharing_mode": "custom_list"},
    )
    assert share_response.status_code == 201
    share_id = share_response.json()["id"]

    add_audience_response = client.post(
        f"/locations/shares/{share_id}/audience",
        json={"allowed_user_id": friend_id},
    )
    assert add_audience_response.status_code == 201
    audience_id = add_audience_response.json()["id"]

    duplicate_add_response = client.post(
        f"/locations/shares/{share_id}/audience",
        json={"allowed_user_id": friend_id},
    )
    assert duplicate_add_response.status_code == 409
    assert duplicate_add_response.json() == {
        "error": {"code": "audience_exists", "message": "audience_exists"}
    }

    remove_response = client.delete(f"/locations/shares/{share_id}/audience/{audience_id}")
    assert remove_response.status_code == 200
    assert remove_response.json() == {"status": "removed"}

    list_after_remove = client.get(f"/locations/shares/{share_id}/audience")
    assert list_after_remove.status_code == 200
    assert list_after_remove.json()["count"] == 0

    remove_again_response = client.delete(f"/locations/shares/{share_id}/audience/{audience_id}")
    assert remove_again_response.status_code == 404
    assert remove_again_response.json() == {
        "error": {"code": "audience_not_found", "message": "audience_not_found"}
    }

    missing_share_remove_response = client.delete(f"/locations/shares/{uuid.uuid4()}/audience/{audience_id}")
    assert missing_share_remove_response.status_code == 404
    assert missing_share_remove_response.json() == {
        "error": {"code": "share_not_found", "message": "share_not_found"}
    }

    app.dependency_overrides.clear()
