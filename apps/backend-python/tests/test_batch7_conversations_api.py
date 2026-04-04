import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_batch7_conversations_members_attachments_flow() -> None:
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

    user_a_response = client.post("/auth/register", json={"email": "batch7-a@example.com", "username": "batch7_a"})
    user_b_response = client.post("/auth/register", json={"email": "batch7-b@example.com", "username": "batch7_b"})
    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]
    uuid.UUID(user_a_id)
    uuid.UUID(user_b_id)

    create_conversation_response = client.post("/conversations", json={"conversation_type": "direct"})
    assert create_conversation_response.status_code == 201
    conversation_id = create_conversation_response.json()["id"]
    uuid.UUID(conversation_id)

    list_conversations_response = client.get("/conversations")
    assert list_conversations_response.status_code == 200
    assert list_conversations_response.json()["count"] == 1

    member_a_response = client.post(f"/conversations/{conversation_id}/members", json={"user_id": user_a_id})
    assert member_a_response.status_code == 201

    member_b_response = client.post(f"/conversations/{conversation_id}/members", json={"user_id": user_b_id})
    assert member_b_response.status_code == 201

    list_members_response = client.get(f"/conversations/{conversation_id}/members")
    assert list_members_response.status_code == 200
    assert list_members_response.json()["count"] == 2

    create_message_response = client.post(
        "/messages",
        json={"sender_user_id": user_a_id, "payload_text": "batch7-message"},
    )
    assert create_message_response.status_code == 201
    message_id = create_message_response.json()["id"]

    create_attachment_response = client.post(
        f"/messages/{message_id}/attachments",
        json={
            "attachment_type": "image",
            "encrypted_attachment_blob": "ciphertext-1",
            "storage_key": "attachments/batch7/image1.enc",
        },
    )
    assert create_attachment_response.status_code == 201

    list_attachments_response = client.get(f"/messages/{message_id}/attachments")
    assert list_attachments_response.status_code == 200
    assert list_attachments_response.json()["count"] == 1
    assert list_attachments_response.json()["items"][0]["attachment_type"] == "image"

    app.dependency_overrides.clear()
