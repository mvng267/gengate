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
    assert list_members_response.json()["items"][0]["last_read_message_id"] is None

    create_message_response = client.post(
        "/messages",
        json={"sender_user_id": user_a_id, "payload_text": "batch7-message", "conversation_id": conversation_id},
    )
    assert create_message_response.status_code == 201
    message_id = create_message_response.json()["id"]

    update_read_cursor_response = client.patch(
        f"/conversations/{conversation_id}/members/{user_a_id}/read-cursor",
        json={"last_read_message_id": message_id},
    )
    assert update_read_cursor_response.status_code == 200
    assert update_read_cursor_response.json()["conversation_id"] == conversation_id
    assert update_read_cursor_response.json()["user_id"] == user_a_id
    assert update_read_cursor_response.json()["last_read_message_id"] == message_id

    list_members_after_cursor = client.get(f"/conversations/{conversation_id}/members")
    assert list_members_after_cursor.status_code == 200
    assert list_members_after_cursor.json()["count"] == 2

    member_after_cursor = next(
        item for item in list_members_after_cursor.json()["items"] if item["user_id"] == user_a_id
    )
    assert member_after_cursor["last_read_message_id"] == message_id

    mismatch_cursor_response = client.patch(
        f"/conversations/{conversation_id}/members/{user_b_id}/read-cursor",
        json={"last_read_message_id": str(uuid.uuid4())},
    )
    assert mismatch_cursor_response.status_code == 404
    assert mismatch_cursor_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

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


def test_batch58_list_direct_conversations_for_user() -> None:
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

    user_a_response = client.post("/auth/register", json={"email": "batch58-list-a@example.com", "username": "batch58_list_a"})
    user_b_response = client.post("/auth/register", json={"email": "batch58-list-b@example.com", "username": "batch58_list_b"})
    user_c_response = client.post("/auth/register", json={"email": "batch58-list-c@example.com", "username": "batch58_list_c"})
    assert user_a_response.status_code == 201
    assert user_b_response.status_code == 201
    assert user_c_response.status_code == 201

    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]
    user_c_id = user_c_response.json()["id"]

    open_thread_ab = client.post(
        "/conversations/direct",
        json={"user_a_id": user_a_id, "user_b_id": user_b_id},
    )
    assert open_thread_ab.status_code == 201
    conversation_ab_id = open_thread_ab.json()["id"]

    open_thread_ac = client.post(
        "/conversations/direct",
        json={"user_a_id": user_a_id, "user_b_id": user_c_id},
    )
    assert open_thread_ac.status_code == 201
    conversation_ac_id = open_thread_ac.json()["id"]

    list_for_user_a = client.get(f"/conversations/direct?user_id={user_a_id}")
    assert list_for_user_a.status_code == 200
    assert list_for_user_a.json()["count"] == 2
    listed_ids_for_a = [item["id"] for item in list_for_user_a.json()["items"]]
    assert set(listed_ids_for_a) == {conversation_ab_id, conversation_ac_id}
    for item in list_for_user_a.json()["items"]:
        assert item["conversation_type"] == "direct"
        assert len(item["member_user_ids"]) == 2
        assert user_a_id in item["member_user_ids"]

    list_for_user_b = client.get(f"/conversations/direct?user_id={user_b_id}")
    assert list_for_user_b.status_code == 200
    assert list_for_user_b.json()["count"] == 1
    assert list_for_user_b.json()["items"][0]["id"] == conversation_ab_id

    missing_user_response = client.get(f"/conversations/direct?user_id={uuid.uuid4()}")
    assert missing_user_response.status_code == 404
    assert missing_user_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch101_direct_member_read_cursor_contract_errors() -> None:
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

    user_a_response = client.post("/auth/register", json={"email": "batch101-a@example.com", "username": "batch101_a"})
    user_b_response = client.post("/auth/register", json={"email": "batch101-b@example.com", "username": "batch101_b"})
    user_c_response = client.post("/auth/register", json={"email": "batch101-c@example.com", "username": "batch101_c"})
    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]
    user_c_id = user_c_response.json()["id"]

    direct_response = client.post(
        "/conversations/direct",
        json={"user_a_id": user_a_id, "user_b_id": user_b_id},
    )
    assert direct_response.status_code == 201
    direct_conversation_id = direct_response.json()["id"]

    group_response = client.post("/conversations", json={"conversation_type": "group"})
    assert group_response.status_code == 201
    group_conversation_id = group_response.json()["id"]

    add_group_member_a = client.post(f"/conversations/{group_conversation_id}/members", json={"user_id": user_a_id})
    add_group_member_b = client.post(f"/conversations/{group_conversation_id}/members", json={"user_id": user_b_id})
    assert add_group_member_a.status_code == 201
    assert add_group_member_b.status_code == 201

    message_response = client.post(
        "/messages",
        json={
            "sender_user_id": user_a_id,
            "payload_text": "batch101 message",
            "conversation_id": direct_conversation_id,
        },
    )
    assert message_response.status_code == 201
    message_id = message_response.json()["id"]

    conversation_not_found = client.patch(
        f"/conversations/{uuid.uuid4()}/members/{user_a_id}/read-cursor",
        json={"last_read_message_id": message_id},
    )
    assert conversation_not_found.status_code == 404
    assert conversation_not_found.json() == {
        "error": {"code": "conversation_not_found", "message": "conversation_not_found"}
    }

    member_not_found = client.patch(
        f"/conversations/{direct_conversation_id}/members/{user_c_id}/read-cursor",
        json={"last_read_message_id": message_id},
    )
    assert member_not_found.status_code == 404
    assert member_not_found.json() == {
        "error": {"code": "conversation_member_not_found", "message": "conversation_member_not_found"}
    }

    non_direct_cursor = client.patch(
        f"/conversations/{group_conversation_id}/members/{user_a_id}/read-cursor",
        json={"last_read_message_id": message_id},
    )
    assert non_direct_cursor.status_code == 400
    assert non_direct_cursor.json() == {
        "error": {"code": "conversation_not_direct", "message": "conversation_not_direct"}
    }

    group_message = client.post(
        "/messages",
        json={
            "sender_user_id": user_a_id,
            "payload_text": "batch101 group message",
            "conversation_id": group_conversation_id,
        },
    )
    assert group_message.status_code == 201
    group_message_id = group_message.json()["id"]

    mismatch_response = client.patch(
        f"/conversations/{direct_conversation_id}/members/{user_a_id}/read-cursor",
        json={"last_read_message_id": group_message_id},
    )
    assert mismatch_response.status_code == 400
    assert mismatch_response.json() == {
        "error": {"code": "message_conversation_mismatch", "message": "message_conversation_mismatch"}
    }

    app.dependency_overrides.clear()


def test_deleted_message_clears_member_read_cursor_reference() -> None:
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
        json={"email": "batch235-cursor-a@example.com", "username": "batch235_cursor_a"},
    )
    user_b_response = client.post(
        "/auth/register",
        json={"email": "batch235-cursor-b@example.com", "username": "batch235_cursor_b"},
    )
    assert user_a_response.status_code == 201
    assert user_b_response.status_code == 201

    user_a_id = user_a_response.json()["id"]
    user_b_id = user_b_response.json()["id"]

    direct_response = client.post(
        "/conversations/direct",
        json={"user_a_id": user_a_id, "user_b_id": user_b_id},
    )
    assert direct_response.status_code == 201
    conversation_id = direct_response.json()["id"]

    message_response = client.post(
        "/messages",
        json={
            "sender_user_id": user_a_id,
            "payload_text": "batch235 cursor reset target",
            "conversation_id": conversation_id,
        },
    )
    assert message_response.status_code == 201
    message_id = message_response.json()["id"]

    update_cursor_response = client.patch(
        f"/conversations/{conversation_id}/members/{user_b_id}/read-cursor",
        json={"last_read_message_id": message_id},
    )
    assert update_cursor_response.status_code == 200
    assert update_cursor_response.json()["last_read_message_id"] == message_id

    delete_message_response = client.delete(f"/messages/{message_id}")
    assert delete_message_response.status_code == 200
    assert delete_message_response.json() == {"status": "deleted"}

    members_after_delete = client.get(f"/conversations/{conversation_id}/members")
    assert members_after_delete.status_code == 200
    assert members_after_delete.json()["count"] == 2

    user_b_member = next(
        item for item in members_after_delete.json()["items"] if item["user_id"] == user_b_id
    )
    assert user_b_member["last_read_message_id"] is None

    app.dependency_overrides.clear()
