import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models.base import Base
from app.models import all_models


def test_register_and_profile_crud_flow() -> None:
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
        json={"email": "profile-test@example.com", "username": "profile_test"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]
    uuid.UUID(user_id)

    upsert_response = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Profile Test", "bio": "hello"},
    )
    assert upsert_response.status_code == 201
    assert upsert_response.json()["display_name"] == "Profile Test"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    assert get_response.json()["display_name"] == "Profile Test"

    app.dependency_overrides.clear()


def test_get_profile_returns_profile_not_found_for_registered_user_without_profile() -> None:
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
        json={"email": "profile-edge@example.com", "username": "profile_edge"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 404
    assert get_response.json() == {"error": {"code": "profile_not_found", "message": "profile_not_found"}}

    app.dependency_overrides.clear()


def test_upsert_profile_returns_user_not_found_for_nonexistent_user() -> None:
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

    unknown_user_id = str(uuid.uuid4())
    upsert_response = client.post(
        "/profiles",
        json={"user_id": unknown_user_id, "display_name": "Ghost User", "bio": "x"},
    )
    assert upsert_response.status_code == 404
    assert upsert_response.json() == {"error": {"code": "user_not_found", "message": "user_not_found"}}

    app.dependency_overrides.clear()


def test_upsert_profile_updates_existing_profile_instead_of_creating_duplicate() -> None:
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
        json={"email": "profile-update@example.com", "username": "profile_update"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "First Name", "bio": "first"},
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Second Name", "bio": "second"},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == "Second Name"
    assert second_profile["bio"] == "second"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    fetched_profile = get_response.json()
    assert fetched_profile["id"] == first_profile["id"]
    assert fetched_profile["display_name"] == "Second Name"
    assert fetched_profile["bio"] == "second"

    app.dependency_overrides.clear()


def test_get_profile_returns_profile_not_found_for_unknown_user_id() -> None:
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

    unknown_user_id = str(uuid.uuid4())
    get_response = client.get(f"/profiles/{unknown_user_id}")
    assert get_response.status_code == 404
    assert get_response.json() == {"error": {"code": "profile_not_found", "message": "profile_not_found"}}

    app.dependency_overrides.clear()


def test_upsert_profile_updates_avatar_only_and_preserves_existing_text_fields() -> None:
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
        json={"email": "profile-avatar@example.com", "username": "profile_avatar"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Avatar User",
            "bio": "unchanged bio",
            "avatar_url": "https://example.com/first.png",
        },
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Avatar User",
            "bio": "unchanged bio",
            "avatar_url": "https://example.com/second.png",
        },
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == "Avatar User"
    assert second_profile["bio"] == "unchanged bio"
    assert second_profile["avatar_url"] == "https://example.com/second.png"

    app.dependency_overrides.clear()


def test_register_returns_user_exists_for_duplicate_username_with_different_email() -> None:
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

    first_register = client.post(
        "/auth/register",
        json={"email": "dup-username-a@example.com", "username": "same_username"},
    )
    assert first_register.status_code == 201

    second_register = client.post(
        "/auth/register",
        json={"email": "dup-username-b@example.com", "username": "same_username"},
    )
    assert second_register.status_code == 409
    assert second_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    app.dependency_overrides.clear()


def test_register_returns_user_exists_for_duplicate_email_with_different_username() -> None:
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

    first_register = client.post(
        "/auth/register",
        json={"email": "dup-email@example.com", "username": "user_a"},
    )
    assert first_register.status_code == 201

    second_register = client.post(
        "/auth/register",
        json={"email": "dup-email@example.com", "username": "user_b"},
    )
    assert second_register.status_code == 409
    assert second_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    app.dependency_overrides.clear()


def test_upsert_profile_accepts_minimal_payload_with_only_user_id() -> None:
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
        json={"email": "profile-minimal@example.com", "username": "profile_minimal"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    upsert_response = client.post("/profiles", json={"user_id": user_id})
    assert upsert_response.status_code == 201
    body = upsert_response.json()
    assert body["user_id"] == user_id
    assert body["display_name"] is None
    assert body["bio"] is None
    assert body["avatar_url"] is None

    app.dependency_overrides.clear()


def test_register_preserves_blank_username_and_blocks_exact_blank_username_duplicates() -> None:
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

    first_register = client.post(
        "/auth/register",
        json={"email": "blank-username-a@example.com", "username": "   "},
    )
    assert first_register.status_code == 201
    assert first_register.json()["username"] == "   "

    second_register = client.post(
        "/auth/register",
        json={"email": "blank-username-b@example.com", "username": "   "},
    )
    assert second_register.status_code == 409
    assert second_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    app.dependency_overrides.clear()


def test_get_profile_returns_validation_error_for_non_uuid_user_id() -> None:
    client = TestClient(app)

    response = client.get('/profiles/not-a-uuid')
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "user_id" in payload["error"]["message"]


def test_upsert_profile_returns_validation_error_for_non_uuid_user_id() -> None:
    client = TestClient(app)

    response = client.post(
        "/profiles",
        json={"user_id": "not-a-uuid", "display_name": "Invalid", "bio": "x"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "user_id" in payload["error"]["message"]


def test_register_preserves_email_whitespace_and_allows_trimmed_variant_as_distinct_user() -> None:
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

    spaced_register = client.post(
        "/auth/register",
        json={"email": "  spaced-email@example.com  ", "username": "spaced_mail_user"},
    )
    assert spaced_register.status_code == 201
    assert spaced_register.json()["email"] == "  spaced-email@example.com  "

    trimmed_register = client.post(
        "/auth/register",
        json={"email": "spaced-email@example.com", "username": "trimmed_mail_user"},
    )
    assert trimmed_register.status_code == 201
    assert trimmed_register.json()["email"] == "spaced-email@example.com"

    app.dependency_overrides.clear()


def test_get_profile_returns_method_not_allowed_for_empty_user_id_path_segment() -> None:
    client = TestClient(app)

    response = client.get('/profiles/')
    assert response.status_code == 405
    payload = response.json()
    assert payload["detail"] == "Method Not Allowed"


def test_upsert_profile_returns_validation_error_for_empty_user_id() -> None:
    client = TestClient(app)

    response = client.post(
        "/profiles",
        json={"user_id": "", "display_name": "Invalid", "bio": "x"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "user_id" in payload["error"]["message"]
