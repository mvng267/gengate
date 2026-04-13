import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
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


def test_friendship_request_and_accept_flow() -> None:
    client = create_test_client()

    requester = client.post("/auth/register", json={"email": "friend-a@example.com", "username": "friend_a"})
    receiver = client.post("/auth/register", json={"email": "friend-b@example.com", "username": "friend_b"})
    requester_id = requester.json()["id"]
    receiver_id = receiver.json()["id"]
    uuid.UUID(requester_id)
    uuid.UUID(receiver_id)

    request_response = client.post(
        "/friends/requests",
        json={"requester_user_id": requester_id, "receiver_user_id": receiver_id},
    )
    assert request_response.status_code == 201
    request_id = request_response.json()["id"]

    list_requests_response = client.get(f"/friends/requests?user_id={requester_id}")
    assert list_requests_response.status_code == 200
    list_requests_payload = list_requests_response.json()
    assert list_requests_payload["count"] == 1
    assert list_requests_payload["items"][0]["requester"]["id"] == requester_id
    assert list_requests_payload["items"][0]["receiver"]["id"] == receiver_id
    assert list_requests_payload["items"][0]["status"] == "pending"

    accept_response = client.post(f"/friends/requests/{request_id}/accept")
    assert accept_response.status_code == 201

    list_response = client.get(f"/friends?user_id={requester_id}")
    assert list_response.status_code == 200
    list_payload = list_response.json()
    assert list_payload["count"] == 1
    assert list_payload["items"][0]["state"] == "accepted"
    assert {list_payload["items"][0]["user_a"]["id"], list_payload["items"][0]["user_b"]["id"]} == {
        requester_id,
        receiver_id,
    }

    clear_overrides()


def test_list_friend_requests_missing_user_returns_not_found() -> None:
    client = create_test_client()

    response = client.get(f"/friends/requests?user_id={uuid.uuid4()}")
    assert response.status_code == 404
    assert response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    clear_overrides()
