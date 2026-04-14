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


def test_create_friend_request_returns_conflict_when_pending_request_already_exists() -> None:
    client = create_test_client()

    requester = client.post("/auth/register", json={"email": "pending-a@example.com", "username": "pending_a"})
    receiver = client.post("/auth/register", json={"email": "pending-b@example.com", "username": "pending_b"})
    requester_id = requester.json()["id"]
    receiver_id = receiver.json()["id"]

    first_request = client.post(
        "/friends/requests",
        json={"requester_user_id": requester_id, "receiver_user_id": receiver_id},
    )
    assert first_request.status_code == 201

    duplicate_same_direction = client.post(
        "/friends/requests",
        json={"requester_user_id": requester_id, "receiver_user_id": receiver_id},
    )
    assert duplicate_same_direction.status_code == 400
    assert duplicate_same_direction.json() == {
        "error": {
            "code": "friend_request_already_pending",
            "message": "friend_request_already_pending",
        }
    }

    duplicate_reverse_direction = client.post(
        "/friends/requests",
        json={"requester_user_id": receiver_id, "receiver_user_id": requester_id},
    )
    assert duplicate_reverse_direction.status_code == 400
    assert duplicate_reverse_direction.json() == {
        "error": {
            "code": "friend_request_already_pending",
            "message": "friend_request_already_pending",
        }
    }

    clear_overrides()


def test_create_friend_request_returns_conflict_when_friendship_already_exists() -> None:
    client = create_test_client()

    requester = client.post("/auth/register", json={"email": "accepted-a@example.com", "username": "accepted_a"})
    receiver = client.post("/auth/register", json={"email": "accepted-b@example.com", "username": "accepted_b"})
    requester_id = requester.json()["id"]
    receiver_id = receiver.json()["id"]

    request_response = client.post(
        "/friends/requests",
        json={"requester_user_id": requester_id, "receiver_user_id": receiver_id},
    )
    assert request_response.status_code == 201

    accept_response = client.post(f"/friends/requests/{request_response.json()['id']}/accept")
    assert accept_response.status_code == 201

    duplicate_after_accept = client.post(
        "/friends/requests",
        json={"requester_user_id": requester_id, "receiver_user_id": receiver_id},
    )
    assert duplicate_after_accept.status_code == 400
    assert duplicate_after_accept.json() == {
        "error": {
            "code": "friendship_already_exists",
            "message": "friendship_already_exists",
        }
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
