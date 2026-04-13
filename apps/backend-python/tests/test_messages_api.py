import uuid
from types import SimpleNamespace

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

import app.services.messages as messages_module
from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base
from app.services.messages import MessageService


def test_message_crud_flow() -> None:
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

    user = client.post("/auth/register", json={"email": "message-user@example.com", "username": "message_user"})
    user_id = user.json()["id"]
    uuid.UUID(user_id)

    recipient_user = client.post(
        "/auth/register",
        json={"email": "recipient-user@example.com", "username": "recipient_user"},
    )
    recipient_user_id = recipient_user.json()["id"]
    uuid.UUID(recipient_user_id)

    recipient_device = client.post(
        "/auth/devices",
        json={"user_id": recipient_user_id, "platform": "ios", "device_name": "Recipient iPhone"},
    )
    assert recipient_device.status_code == 201
    recipient_device_id = recipient_device.json()["id"]
    uuid.UUID(recipient_device_id)

    create_response = client.post(
        "/messages",
        json={"sender_user_id": user_id, "payload_text": "hello"},
    )
    assert create_response.status_code == 201
    message_id = create_response.json()["id"]
    conversation_id = create_response.json()["conversation_id"]

    get_response = client.get(f"/messages/{message_id}")
    assert get_response.status_code == 200
    assert get_response.json()["payload_text"] == "hello"

    list_response = client.get(f"/messages?conversation_id={conversation_id}")
    assert list_response.status_code == 200
    assert list_response.json()["count"] == 1

    create_device_key_response = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": recipient_user_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "wrapped-key-blob-1",
        },
    )
    assert create_device_key_response.status_code == 201
    assert create_device_key_response.json()["message_id"] == message_id
    assert create_device_key_response.json()["wrapped_message_key_blob"] == "wrapped-key-blob-1"

    list_device_keys_response = client.get(f"/messages/{message_id}/device-keys")
    assert list_device_keys_response.status_code == 200
    assert list_device_keys_response.json()["count"] == 1
    assert list_device_keys_response.json()["items"][0]["recipient_device_id"] == recipient_device_id

    app.dependency_overrides.clear()


def test_message_device_keys_message_not_found() -> None:
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

    recipient_user = client.post(
        "/auth/register",
        json={"email": "recipient-missing@example.com", "username": "recipient_missing"},
    )
    recipient_user_id = recipient_user.json()["id"]

    recipient_device = client.post(
        "/auth/devices",
        json={"user_id": recipient_user_id, "platform": "android", "device_name": "Pixel"},
    )
    recipient_device_id = recipient_device.json()["id"]

    missing_message_id = str(uuid.uuid4())
    create_device_key_response = client.post(
        f"/messages/{missing_message_id}/device-keys",
        json={
            "recipient_user_id": recipient_user_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "wrapped-key-blob-2",
        },
    )
    assert create_device_key_response.status_code == 404
    assert create_device_key_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch20_message_device_keys_missing_parent_and_mismatch_parity() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch20-sender@example.com", "username": "batch20_sender"})
    sender_id = sender.json()["id"]

    recipient = client.post(
        "/auth/register",
        json={"email": "batch20-recipient@example.com", "username": "batch20_recipient"},
    )
    recipient_id = recipient.json()["id"]

    other_user = client.post(
        "/auth/register",
        json={"email": "batch20-other@example.com", "username": "batch20_other"},
    )
    other_user_id = other_user.json()["id"]

    recipient_device = client.post(
        "/auth/devices",
        json={"user_id": recipient_id, "platform": "ios", "device_name": "Batch20 Recipient iPhone"},
    )
    assert recipient_device.status_code == 201
    recipient_device_id = recipient_device.json()["id"]

    message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch20 hello"},
    )
    assert message.status_code == 201
    message_id = message.json()["id"]

    missing_user_response = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": str(uuid.uuid4()),
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "batch20-missing-user",
        },
    )
    assert missing_user_response.status_code == 404
    assert missing_user_response.json() == {
        "error": {"code": "user_not_found", "message": "user_not_found"}
    }

    missing_device_response = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": recipient_id,
            "recipient_device_id": str(uuid.uuid4()),
            "wrapped_message_key_blob": "batch20-missing-device",
        },
    )
    assert missing_device_response.status_code == 404
    assert missing_device_response.json() == {
        "error": {"code": "device_not_found", "message": "device_not_found"}
    }

    mismatch_response = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": other_user_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "batch20-mismatch",
        },
    )
    assert mismatch_response.status_code == 404
    assert mismatch_response.json() == {
        "error": {"code": "device_user_mismatch", "message": "device_user_mismatch"}
    }

    missing_list_response = client.get(f"/messages/{uuid.uuid4()}/device-keys")
    assert missing_list_response.status_code == 404
    assert missing_list_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch21_message_create_reuses_sender_device_and_attachment_missing_parent_parity() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch21-sender@example.com", "username": "batch21_sender"})
    assert sender.status_code == 201
    sender_id = sender.json()["id"]

    sender_device = client.post(
        "/auth/devices",
        json={"user_id": sender_id, "platform": "ios", "device_name": "Batch21 Existing Device"},
    )
    assert sender_device.status_code == 201
    sender_device_id = sender_device.json()["id"]

    first_message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch21 first"},
    )
    second_message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch21 second"},
    )
    assert first_message.status_code == 201
    assert second_message.status_code == 201
    first_message_id = first_message.json()["id"]

    device_list = client.get(f"/auth/devices/{sender_id}")
    assert device_list.status_code == 200
    assert device_list.json()["count"] == 1
    assert device_list.json()["items"][0]["id"] == sender_device_id

    attachment_response = client.post(
        f"/messages/{first_message_id}/attachments",
        json={
            "attachment_type": "image",
            "encrypted_attachment_blob": "batch21-image-blob",
            "storage_key": "attachments/batch21/image1.enc",
        },
    )
    assert attachment_response.status_code == 201
    assert attachment_response.json()["message_id"] == first_message_id

    list_attachments_response = client.get(f"/messages/{first_message_id}/attachments")
    assert list_attachments_response.status_code == 200
    assert list_attachments_response.json()["count"] == 1
    assert list_attachments_response.json()["items"][0]["storage_key"] == "attachments/batch21/image1.enc"

    delete_response = client.delete(f"/messages/{first_message_id}")
    assert delete_response.status_code == 200
    assert delete_response.json() == {"status": "deleted"}

    get_deleted_response = client.get(f"/messages/{first_message_id}")
    assert get_deleted_response.status_code == 404
    assert get_deleted_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    list_after_delete = client.get("/messages")
    assert list_after_delete.status_code == 200
    assert list_after_delete.json()["count"] == 1
    assert list_after_delete.json()["items"][0]["id"] == second_message.json()["id"]

    delete_again_response = client.delete(f"/messages/{first_message_id}")
    assert delete_again_response.status_code == 404
    assert delete_again_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    create_attachment_on_deleted = client.post(
        f"/messages/{first_message_id}/attachments",
        json={
            "attachment_type": "image",
            "encrypted_attachment_blob": "batch21-deleted-message",
            "storage_key": "attachments/batch21/deleted.enc",
        },
    )
    assert create_attachment_on_deleted.status_code == 404
    assert create_attachment_on_deleted.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    list_attachment_on_deleted = client.get(f"/messages/{first_message_id}/attachments")
    assert list_attachment_on_deleted.status_code == 404
    assert list_attachment_on_deleted.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    missing_create_response = client.post(
        f"/messages/{uuid.uuid4()}/attachments",
        json={
            "attachment_type": "image",
            "encrypted_attachment_blob": "batch21-missing-message",
            "storage_key": "attachments/batch21/missing.enc",
        },
    )
    assert missing_create_response.status_code == 404
    assert missing_create_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    missing_list_response = client.get(f"/messages/{uuid.uuid4()}/attachments")
    assert missing_list_response.status_code == 404
    assert missing_list_response.json() == {
        "error": {"code": "message_not_found", "message": "message_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch21_message_create_reuses_existing_trusted_sender_device_in_service() -> None:
    service = MessageService()
    sender_id = uuid.uuid4()
    existing_device = SimpleNamespace(id=uuid.uuid4(), user_id=sender_id, device_trust_state="trusted")
    created_messages: list[dict] = []

    class FakeDb:
        def add(self, entity):
            return None

        def flush(self):
            return None

    class FakeUserRepository:
        def get(self, db, user_id):
            assert user_id == sender_id
            return SimpleNamespace(id=sender_id)

    class FakeMessageRepository:
        def create(self, db, **data):
            created_messages.append(data)
            return SimpleNamespace(
                id=uuid.uuid4(),
                conversation_id=data["conversation_id"],
                sender_user_id=data["sender_user_id"],
                sender_device_id=data["sender_device_id"],
                encrypted_payload_blob=data["encrypted_payload_blob"],
            )

    class FakeDeviceRepository:
        def list_by_user_id(self, db, user_id):
            assert user_id == sender_id
            return [existing_device]

    class FakeConversation:
        def __init__(self, conversation_type):
            self.id = uuid.uuid4()
            self.conversation_type = conversation_type

    original_user_repository = messages_module.user_repository
    original_message_repository = messages_module.message_repository
    original_device_repository = messages_module.device_repository
    original_conversation_model = messages_module.Conversation
    messages_module.user_repository = FakeUserRepository()
    messages_module.message_repository = FakeMessageRepository()
    messages_module.device_repository = FakeDeviceRepository()
    messages_module.Conversation = FakeConversation

    try:
        message = service.create_message(FakeDb(), sender_user_id=sender_id, payload_text="batch21 service")
        assert message.sender_device_id == existing_device.id
        assert len(created_messages) == 1
        assert created_messages[0]["sender_device_id"] == existing_device.id
    finally:
        messages_module.user_repository = original_user_repository
        messages_module.message_repository = original_message_repository
        messages_module.device_repository = original_device_repository
        messages_module.Conversation = original_conversation_model


def test_batch32_message_create_with_legacy_sender_device_state_creates_replacement() -> None:
    service = MessageService()
    sender_id = uuid.uuid4()
    legacy_device = SimpleNamespace(id=uuid.uuid4(), user_id=sender_id, device_trust_state="legacy")
    created_messages: list[dict] = []
    added_entities: list[object] = []

    class FakeDb:
        def add(self, entity):
            if getattr(entity, "id", None) is None:
                entity.id = uuid.uuid4()
            added_entities.append(entity)
            return None

        def flush(self):
            return None

    class FakeUserRepository:
        def get(self, db, user_id):
            assert user_id == sender_id
            return SimpleNamespace(id=sender_id)

    class FakeMessageRepository:
        def create(self, db, **data):
            created_messages.append(data)
            return SimpleNamespace(
                id=uuid.uuid4(),
                conversation_id=data["conversation_id"],
                sender_user_id=data["sender_user_id"],
                sender_device_id=data["sender_device_id"],
                encrypted_payload_blob=data["encrypted_payload_blob"],
            )

    class FakeDeviceRepository:
        def list_by_user_id(self, db, user_id):
            assert user_id == sender_id
            return [legacy_device]

    class FakeConversation:
        def __init__(self, conversation_type):
            self.id = uuid.uuid4()
            self.conversation_type = conversation_type

    original_user_repository = messages_module.user_repository
    original_message_repository = messages_module.message_repository
    original_device_repository = messages_module.device_repository
    original_conversation_model = messages_module.Conversation
    messages_module.user_repository = FakeUserRepository()
    messages_module.message_repository = FakeMessageRepository()
    messages_module.device_repository = FakeDeviceRepository()
    messages_module.Conversation = FakeConversation

    try:
        message = service.create_message(FakeDb(), sender_user_id=sender_id, payload_text="batch32 service")
        assert len(created_messages) == 1
        assert created_messages[0]["sender_device_id"] != legacy_device.id
        assert message.sender_device_id == created_messages[0]["sender_device_id"]

        created_devices = [entity for entity in added_entities if isinstance(entity, messages_module.Device)]
        assert len(created_devices) == 1
        assert created_devices[0].platform == "local"
        assert created_devices[0].device_name == "default-device"
        assert created_devices[0].device_trust_state == "trusted"
    finally:
        messages_module.user_repository = original_user_repository
        messages_module.message_repository = original_message_repository
        messages_module.device_repository = original_device_repository
        messages_module.Conversation = original_conversation_model


def test_batch33_message_create_with_missing_legacy_trust_state_creates_replacement() -> None:
    service = MessageService()
    sender_id = uuid.uuid4()
    legacy_device = SimpleNamespace(id=uuid.uuid4(), user_id=sender_id, device_trust_state=None)
    created_messages: list[dict] = []
    added_entities: list[object] = []

    class FakeDb:
        def add(self, entity):
            if getattr(entity, "id", None) is None:
                entity.id = uuid.uuid4()
            added_entities.append(entity)
            return None

        def flush(self):
            return None

    class FakeUserRepository:
        def get(self, db, user_id):
            assert user_id == sender_id
            return SimpleNamespace(id=sender_id)

    class FakeMessageRepository:
        def create(self, db, **data):
            created_messages.append(data)
            return SimpleNamespace(
                id=uuid.uuid4(),
                conversation_id=data["conversation_id"],
                sender_user_id=data["sender_user_id"],
                sender_device_id=data["sender_device_id"],
                encrypted_payload_blob=data["encrypted_payload_blob"],
            )

    class FakeDeviceRepository:
        def list_by_user_id(self, db, user_id):
            assert user_id == sender_id
            return [legacy_device]

    class FakeConversation:
        def __init__(self, conversation_type):
            self.id = uuid.uuid4()
            self.conversation_type = conversation_type

    original_user_repository = messages_module.user_repository
    original_message_repository = messages_module.message_repository
    original_device_repository = messages_module.device_repository
    original_conversation_model = messages_module.Conversation
    messages_module.user_repository = FakeUserRepository()
    messages_module.message_repository = FakeMessageRepository()
    messages_module.device_repository = FakeDeviceRepository()
    messages_module.Conversation = FakeConversation

    try:
        message = service.create_message(FakeDb(), sender_user_id=sender_id, payload_text="batch33 service")
        assert len(created_messages) == 1
        assert created_messages[0]["sender_device_id"] != legacy_device.id
        assert message.sender_device_id == created_messages[0]["sender_device_id"]

        created_devices = [entity for entity in added_entities if isinstance(entity, messages_module.Device)]
        assert len(created_devices) == 1
        assert created_devices[0].platform == "local"
        assert created_devices[0].device_name == "default-device"
        assert created_devices[0].device_trust_state == "trusted"
    finally:
        messages_module.user_repository = original_user_repository
        messages_module.message_repository = original_message_repository
        messages_module.device_repository = original_device_repository
        messages_module.Conversation = original_conversation_model


def test_batch22_list_messages_missing_conversation_parity() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch22-sender@example.com", "username": "batch22_sender"})
    assert sender.status_code == 201

    list_missing_conversation = client.get(f"/messages?conversation_id={uuid.uuid4()}")
    assert list_missing_conversation.status_code == 404
    assert list_missing_conversation.json() == {
        "error": {"code": "conversation_not_found", "message": "conversation_not_found"}
    }

    app.dependency_overrides.clear()


def test_batch22_message_create_with_revoked_sender_device_creates_replacement() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch22-revoked@example.com", "username": "batch22_revoked"})
    assert sender.status_code == 201
    sender_id = sender.json()["id"]

    sender_device = client.post(
        "/auth/devices",
        json={"user_id": sender_id, "platform": "ios", "device_name": "Batch22 Revoked Device"},
    )
    assert sender_device.status_code == 201

    revoke_device = client.patch(f"/auth/devices/{sender_device.json()['id']}/revoke")
    assert revoke_device.status_code == 200
    assert revoke_device.json()["device_trust_state"] == "revoked"

    create_message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch22 replace revoked sender device"},
    )
    assert create_message.status_code == 201

    list_devices = client.get(f"/auth/devices/{sender_id}")
    assert list_devices.status_code == 200
    assert list_devices.json()["count"] == 2
    trusted_devices = [item for item in list_devices.json()["items"] if item["device_trust_state"] == "trusted"]
    revoked_devices = [item for item in list_devices.json()["items"] if item["device_trust_state"] == "revoked"]
    assert len(trusted_devices) == 1
    assert trusted_devices[0]["platform"] == "local"
    assert trusted_devices[0]["device_name"] == "default-device"
    assert len(revoked_devices) == 1

    app.dependency_overrides.clear()


def test_batch23_message_device_key_duplicate_guard() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch23-sender@example.com", "username": "batch23_sender"})
    assert sender.status_code == 201
    sender_id = sender.json()["id"]

    recipient = client.post(
        "/auth/register",
        json={"email": "batch23-recipient@example.com", "username": "batch23_recipient"},
    )
    assert recipient.status_code == 201
    recipient_id = recipient.json()["id"]

    recipient_device = client.post(
        "/auth/devices",
        json={"user_id": recipient_id, "platform": "ios", "device_name": "Batch23 Recipient iPhone"},
    )
    assert recipient_device.status_code == 201
    recipient_device_id = recipient_device.json()["id"]

    message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch23 hello"},
    )
    assert message.status_code == 201
    message_id = message.json()["id"]

    first_create = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": recipient_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "batch23-first-key",
        },
    )
    assert first_create.status_code == 201

    duplicate_create = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": recipient_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "batch23-duplicate-key",
        },
    )
    assert duplicate_create.status_code == 409
    assert duplicate_create.json() == {
        "error": {"code": "message_device_key_exists", "message": "message_device_key_exists"}
    }

    list_device_keys = client.get(f"/messages/{message_id}/device-keys")
    assert list_device_keys.status_code == 200
    assert list_device_keys.json()["count"] == 1

    app.dependency_overrides.clear()


def test_batch24_message_device_key_duplicate_integrity_parity() -> None:
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

    sender = client.post("/auth/register", json={"email": "batch24-sender@example.com", "username": "batch24_sender"})
    assert sender.status_code == 201
    sender_id = sender.json()["id"]

    recipient = client.post(
        "/auth/register",
        json={"email": "batch24-recipient@example.com", "username": "batch24_recipient"},
    )
    assert recipient.status_code == 201
    recipient_id = recipient.json()["id"]

    recipient_device = client.post(
        "/auth/devices",
        json={"user_id": recipient_id, "platform": "ios", "device_name": "Batch24 Recipient iPhone"},
    )
    assert recipient_device.status_code == 201
    recipient_device_id = recipient_device.json()["id"]

    message = client.post(
        "/messages",
        json={"sender_user_id": sender_id, "payload_text": "batch24 hello"},
    )
    assert message.status_code == 201
    message_id = message.json()["id"]

    first_create = client.post(
        f"/messages/{message_id}/device-keys",
        json={
            "recipient_user_id": recipient_id,
            "recipient_device_id": recipient_device_id,
            "wrapped_message_key_blob": "batch24-first-key",
        },
    )
    assert first_create.status_code == 201

    class FakeOrigError:
        diag = type(
            "Diag",
            (),
            {
                "constraint_name": "uq_message_device_keys_message_recipient_device",
                "message_detail": "duplicate key value violates unique constraint",
                "table_name": "message_device_keys",
            },
        )
        pgcode = "23505"

    class FakeIntegrityError(IntegrityError):
        def __init__(self):
            super().__init__(
                "INSERT INTO message_device_keys (...) VALUES (...)",
                {"message_id": message_id, "recipient_device_id": recipient_device_id},
                FakeOrigError(),
            )

    original_get_by_message_and_recipient_device = (
        messages_module.message_device_key_repository.get_by_message_and_recipient_device
    )
    original_create = messages_module.message_device_key_repository.create
    messages_module.message_device_key_repository.get_by_message_and_recipient_device = (
        lambda db, message_id, recipient_device_id: None
    )

    def raise_integrity_error(db, **kwargs):
        raise FakeIntegrityError()

    messages_module.message_device_key_repository.create = raise_integrity_error

    try:
        duplicate_create = client.post(
            f"/messages/{message_id}/device-keys",
            json={
                "recipient_user_id": recipient_id,
                "recipient_device_id": recipient_device_id,
                "wrapped_message_key_blob": "batch24-duplicate-key",
            },
        )
        assert duplicate_create.status_code == 409
        assert duplicate_create.json() == {
            "error": {"code": "message_device_key_exists", "message": "message_device_key_exists"}
        }

        list_device_keys = client.get(f"/messages/{message_id}/device-keys")
        assert list_device_keys.status_code == 200
        assert list_device_keys.json()["count"] == 1
    finally:
        messages_module.message_device_key_repository.get_by_message_and_recipient_device = (
            original_get_by_message_and_recipient_device
        )
        messages_module.message_device_key_repository.create = original_create
        app.dependency_overrides.clear()


def test_batch58_direct_conversation_thread_shell_flow() -> None:
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

    user_a = client.post("/auth/register", json={"email": "batch58-a@example.com", "username": "batch58_a"})
    user_b = client.post("/auth/register", json={"email": "batch58-b@example.com", "username": "batch58_b"})
    assert user_a.status_code == 201
    assert user_b.status_code == 201
    user_a_id = user_a.json()["id"]
    user_b_id = user_b.json()["id"]

    open_thread = client.post(
        "/conversations/direct",
        json={"user_a_id": user_a_id, "user_b_id": user_b_id},
    )
    assert open_thread.status_code == 201
    conversation_id = open_thread.json()["id"]
    assert open_thread.json()["conversation_type"] == "direct"
    assert set(open_thread.json()["member_user_ids"]) == {user_a_id, user_b_id}

    reopen_thread = client.post(
        "/conversations/direct",
        json={"user_a_id": user_b_id, "user_b_id": user_a_id},
    )
    assert reopen_thread.status_code == 201
    assert reopen_thread.json()["id"] == conversation_id

    send_message = client.post(
        "/messages",
        json={
            "conversation_id": conversation_id,
            "sender_user_id": user_a_id,
            "payload_text": "batch58 hello direct thread",
        },
    )
    assert send_message.status_code == 201
    assert send_message.json()["conversation_id"] == conversation_id
    assert send_message.json()["payload_text"] == "batch58 hello direct thread"

    list_messages = client.get(f"/messages?conversation_id={conversation_id}")
    assert list_messages.status_code == 200
    assert list_messages.json()["count"] == 1
    assert list_messages.json()["items"][0]["sender_user_id"] == user_a_id

    invalid_sender = client.post(
        "/messages",
        json={
            "conversation_id": conversation_id,
            "sender_user_id": str(uuid.uuid4()),
            "payload_text": "should fail",
        },
    )
    assert invalid_sender.status_code == 404
    assert invalid_sender.json() == {"error": {"code": "user_not_found", "message": "user_not_found"}}

    outsider = client.post(
        "/auth/register",
        json={"email": "batch58-outsider@example.com", "username": "batch58_outsider"},
    )
    assert outsider.status_code == 201
    outsider_id = outsider.json()["id"]

    outsider_send = client.post(
        "/messages",
        json={
            "conversation_id": conversation_id,
            "sender_user_id": outsider_id,
            "payload_text": "outsider should fail",
        },
    )
    assert outsider_send.status_code == 400
    assert outsider_send.json() == {
        "error": {"code": "conversation_member_not_found", "message": "conversation_member_not_found"}
    }

    app.dependency_overrides.clear()
