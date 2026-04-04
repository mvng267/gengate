import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_friendship_request_and_accept_flow() -> None:
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

    accept_response = client.post(f"/friends/requests/{request_id}/accept")
    assert accept_response.status_code == 201

    list_response = client.get("/friends")
    assert list_response.status_code == 200
    assert list_response.json()["count"] == 1

    app.dependency_overrides.clear()
