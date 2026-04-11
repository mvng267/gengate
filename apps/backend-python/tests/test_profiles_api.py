import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base
from app.models.profiles import Profile


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
    register_body = register_response.json()
    user_id = register_body["id"]
    uuid.UUID(user_id)
    assert register_body["email"] == "profile-test@example.com"

    session = testing_session_local()
    try:
        registered_user = session.get(all_models[1], uuid.UUID(user_id))
        assert registered_user is not None
        assert registered_user.email_verified_at is not None
    finally:
        session.close()

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


def test_upsert_profile_is_idempotent_for_same_payload_without_unintended_mutation() -> None:
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
        json={"email": "profile-idempotent@example.com", "username": "profile_idempotent"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    payload = {
        "user_id": user_id,
        "display_name": "Idempotent Name",
        "bio": "Idempotent Bio",
        "avatar_url": "https://example.com/idempotent.png",
    }

    first_upsert = client.post("/profiles", json=payload)
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post("/profiles", json=payload)
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile == first_profile

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted == first_profile

    session = testing_session_local()
    try:
        profile_count = session.scalar(select(func.count()).select_from(Profile))
        assert profile_count == 1
    finally:
        session.close()

    app.dependency_overrides.clear()


def test_upsert_profile_preserves_whitespace_in_display_name_and_bio() -> None:
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
        json={"email": "profile-whitespace-fields@example.com", "username": "profile_ws_fields"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    upsert_response = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "  Name With Spaces  ",
            "bio": "  Bio With Spaces  ",
        },
    )
    assert upsert_response.status_code == 201
    body = upsert_response.json()
    assert body["display_name"] == "  Name With Spaces  "
    assert body["bio"] == "  Bio With Spaces  "

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "  Name With Spaces  "
    assert persisted["bio"] == "  Bio With Spaces  "

    app.dependency_overrides.clear()


def test_upsert_profile_returns_validation_error_when_display_name_exceeds_max_length() -> None:
    client = TestClient(app)

    response = client.post(
        "/profiles",
        json={"user_id": str(uuid.uuid4()), "display_name": "n" * 121, "bio": "x"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "display_name" in payload["error"]["message"]
    assert "120" in payload["error"]["message"]


def test_upsert_profile_accepts_very_long_bio_and_persists_it() -> None:
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
        json={"email": "profile-long-bio@example.com", "username": "profile_long_bio"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    long_bio = "b" * 10000
    upsert_response = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Long Bio User", "bio": long_bio},
    )
    assert upsert_response.status_code == 201
    body = upsert_response.json()
    assert body["display_name"] == "Long Bio User"
    assert body["bio"] == long_bio

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "Long Bio User"
    assert persisted["bio"] == long_bio

    app.dependency_overrides.clear()


def test_upsert_profile_updates_display_name_and_bio_to_empty_strings_instead_of_null() -> None:
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
        json={"email": "profile-empty-fields@example.com", "username": "profile_empty_fields"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Before", "bio": "Before bio"},
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "", "bio": ""},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == ""
    assert second_profile["bio"] == ""

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == ""
    assert persisted["bio"] == ""

    app.dependency_overrides.clear()


def test_upsert_profile_updates_display_name_and_bio_to_null_when_explicitly_provided() -> None:
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
        json={"email": "profile-null-fields@example.com", "username": "profile_null_fields"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Before", "bio": "Before bio"},
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": None, "bio": None},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] is None
    assert second_profile["bio"] is None

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] is None
    assert persisted["bio"] is None

    app.dependency_overrides.clear()


def test_upsert_profile_updates_display_name_to_null_and_preserves_bio_when_bio_omitted() -> None:
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
        json={"email": "profile-null-omitted-bio@example.com", "username": "profile_null_omitted_bio"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": "Before", "bio": "Keep me"},
    )
    assert first_upsert.status_code == 201

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": None},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["display_name"] is None
    assert second_profile["bio"] == "Keep me"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] is None
    assert persisted["bio"] == "Keep me"

    app.dependency_overrides.clear()


def test_upsert_profile_updates_display_name_to_null_and_preserves_omitted_bio_and_avatar_url() -> None:
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
        json={
            "email": "profile-null-omitted-bio-avatar@example.com",
            "username": "profile_null_omitted_bio_avatar",
        },
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Before",
            "bio": "Keep me",
            "avatar_url": "https://example.com/keep-me.png",
        },
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "display_name": None},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] is None
    assert second_profile["bio"] == "Keep me"
    assert second_profile["avatar_url"] == "https://example.com/keep-me.png"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] is None
    assert persisted["bio"] == "Keep me"
    assert persisted["avatar_url"] == "https://example.com/keep-me.png"

    app.dependency_overrides.clear()


def test_upsert_profile_updates_bio_to_null_and_preserves_omitted_display_name_and_avatar_url() -> None:
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
        json={
            "email": "profile-bio-null-omitted-display-avatar@example.com",
            "username": "profile_bio_null_omitted_display_avatar",
        },
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Keep Name",
            "bio": "Before bio",
            "avatar_url": "https://example.com/keep-avatar.png",
        },
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "bio": None},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == "Keep Name"
    assert second_profile["bio"] is None
    assert second_profile["avatar_url"] == "https://example.com/keep-avatar.png"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "Keep Name"
    assert persisted["bio"] is None
    assert persisted["avatar_url"] == "https://example.com/keep-avatar.png"

    app.dependency_overrides.clear()


def test_upsert_profile_updates_bio_to_null_and_preserves_omitted_display_name_and_avatar_url_when_values_are_empty_strings() -> None:
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
        json={
            "email": "profile-bio-null-omitted-display-avatar-empty@example.com",
            "username": "profile_bio_null_omitted_display_avatar_empty",
        },
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "",
            "bio": "Before bio",
            "avatar_url": "",
        },
    )
    assert first_upsert.status_code == 201
    first_profile = first_upsert.json()

    second_upsert = client.post(
        "/profiles",
        json={"user_id": user_id, "bio": None},
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == ""
    assert second_profile["bio"] is None
    assert second_profile["avatar_url"] == ""

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == ""
    assert persisted["bio"] is None
    assert persisted["avatar_url"] == ""

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
            "avatar_url": "https://example.com/second.png",
        },
    )
    assert second_upsert.status_code == 201
    second_profile = second_upsert.json()

    assert second_profile["id"] == first_profile["id"]
    assert second_profile["display_name"] == "Avatar User"
    assert second_profile["bio"] == "unchanged bio"
    assert second_profile["avatar_url"] == "https://example.com/second.png"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "Avatar User"
    assert persisted["bio"] == "unchanged bio"
    assert persisted["avatar_url"] == "https://example.com/second.png"

    app.dependency_overrides.clear()


def test_upsert_profile_clears_avatar_with_null_and_preserves_omitted_text_fields() -> None:
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
        json={"email": "profile-avatar-null@example.com", "username": "profile_avatar_null"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Avatar Null User",
            "bio": "keep bio",
            "avatar_url": "https://example.com/original.png",
        },
    )
    assert first_upsert.status_code == 201

    clear_avatar_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "avatar_url": None,
        },
    )
    assert clear_avatar_upsert.status_code == 201
    clear_avatar_body = clear_avatar_upsert.json()
    assert clear_avatar_body["display_name"] == "Avatar Null User"
    assert clear_avatar_body["bio"] == "keep bio"
    assert clear_avatar_body["avatar_url"] is None

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "Avatar Null User"
    assert persisted["bio"] == "keep bio"
    assert persisted["avatar_url"] is None

    app.dependency_overrides.clear()


def test_upsert_profile_sequential_partial_updates_preserve_untouched_fields() -> None:
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
        json={"email": "profile-seq-partial@example.com", "username": "profile_seq_partial"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Sequential User",
            "bio": "initial bio",
            "avatar_url": "https://example.com/initial.png",
        },
    )
    assert first_upsert.status_code == 201

    avatar_only_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "avatar_url": "https://example.com/avatar-only.png",
        },
    )
    assert avatar_only_upsert.status_code == 201
    avatar_only_body = avatar_only_upsert.json()
    assert avatar_only_body["display_name"] == "Sequential User"
    assert avatar_only_body["bio"] == "initial bio"
    assert avatar_only_body["avatar_url"] == "https://example.com/avatar-only.png"

    bio_only_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "bio": "updated bio only",
        },
    )
    assert bio_only_upsert.status_code == 201
    bio_only_body = bio_only_upsert.json()
    assert bio_only_body["display_name"] == "Sequential User"
    assert bio_only_body["bio"] == "updated bio only"
    assert bio_only_body["avatar_url"] == "https://example.com/avatar-only.png"

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "Sequential User"
    assert persisted["bio"] == "updated bio only"
    assert persisted["avatar_url"] == "https://example.com/avatar-only.png"

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


def test_upsert_profile_create_path_sets_only_provided_fields_for_newly_registered_user() -> None:
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
        json={"email": "profile-create-path@example.com", "username": "profile_create_path"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    upsert_response = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "First-time Display Name",
        },
    )
    assert upsert_response.status_code == 201
    body = upsert_response.json()
    assert body["user_id"] == user_id
    assert body["display_name"] == "First-time Display Name"
    assert body["bio"] is None
    assert body["avatar_url"] is None

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["id"] == body["id"]
    assert persisted["display_name"] == "First-time Display Name"
    assert persisted["bio"] is None
    assert persisted["avatar_url"] is None

    session = testing_session_local()
    try:
        profile_count = session.scalar(select(func.count()).select_from(Profile))
        assert profile_count == 1
    finally:
        session.close()

    app.dependency_overrides.clear()


def test_register_normalizes_whitespace_only_username_to_null_and_allows_multiple_distinct_emails() -> None:
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
    assert first_register.json()["username"] is None

    second_register = client.post(
        "/auth/register",
        json={"email": "blank-username-b@example.com", "username": "   "},
    )
    assert second_register.status_code == 201
    assert second_register.json()["username"] is None

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


def test_upsert_profile_returns_validation_error_when_user_id_is_omitted_with_text_fields() -> None:
    client = TestClient(app)

    response = client.post(
        "/profiles",
        json={"display_name": "Invalid combo", "bio": "x"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "user_id" in payload["error"]["message"]


def test_register_normalizes_email_by_trimming_and_lowercasing() -> None:
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
        json={"email": "  Case-Trim@Example.COM  ", "username": "normalized_mail_user"},
    )
    assert register_response.status_code == 201
    assert register_response.json()["email"] == "case-trim@example.com"

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


def test_register_allows_null_username_for_multiple_distinct_emails() -> None:
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
        json={"email": "null-username-a@example.com", "username": None},
    )
    assert first_register.status_code == 201
    assert first_register.json()["username"] is None

    second_register = client.post(
        "/auth/register",
        json={"email": "null-username-b@example.com", "username": None},
    )
    assert second_register.status_code == 201
    assert second_register.json()["username"] is None

    app.dependency_overrides.clear()


def test_register_normalizes_empty_username_to_null_and_allows_multiple_distinct_emails() -> None:
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
        json={"email": "empty-username-a@example.com", "username": ""},
    )
    assert first_register.status_code == 201
    assert first_register.json()["username"] is None

    second_register = client.post(
        "/auth/register",
        json={"email": "empty-username-b@example.com", "username": ""},
    )
    assert second_register.status_code == 201
    assert second_register.json()["username"] is None

    app.dependency_overrides.clear()


def test_register_blocks_case_variant_emails_after_normalization() -> None:
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
        json={"email": "CaseVariant@example.com", "username": "case_variant_a"},
    )
    assert first_register.status_code == 201
    assert first_register.json()["email"] == "casevariant@example.com"

    second_register = client.post(
        "/auth/register",
        json={"email": "casevariant@example.com", "username": "case_variant_b"},
    )
    assert second_register.status_code == 409
    assert second_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    app.dependency_overrides.clear()


def test_register_blocks_trimmed_variant_when_existing_email_has_outer_whitespace() -> None:
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
        json={"email": "  dup-space@example.com  ", "username": "dup_space_a"},
    )
    assert spaced_register.status_code == 201
    assert spaced_register.json()["email"] == "dup-space@example.com"

    trimmed_register = client.post(
        "/auth/register",
        json={"email": "dup-space@example.com", "username": "dup_space_b"},
    )
    assert trimmed_register.status_code == 409
    assert trimmed_register.json() == {"error": {"code": "user_exists", "message": "user_exists"}}

    app.dependency_overrides.clear()


def test_register_returns_validation_error_when_email_is_null() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": None, "username": "null_email_user"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email" in payload["error"]["message"]


def test_register_returns_validation_error_for_empty_payload() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email" in payload["error"]["message"]


def test_register_returns_validation_error_when_email_exceeds_max_length_after_normalization() -> None:
    client = TestClient(app)

    local_part = "a" * 309
    response = client.post(
        "/auth/register",
        json={"email": f"  {local_part}@example.com  ", "username": "too_long_email_user"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email_too_long" in payload["error"]["message"]


def test_register_returns_validation_error_when_username_exceeds_max_length() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "too-long-username@example.com", "username": "u" * 51},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "username_too_long" in payload["error"]["message"]


def test_register_rejects_username_exceeding_max_length_after_trim() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "too-long-trimmed-username@example.com", "username": f" {'u' * 51} "},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "username_too_long" in payload["error"]["message"]


def test_register_trims_username_before_persisting() -> None:
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
        json={"email": "trim-username@example.com", "username": "  trimmed_user  "},
    )
    assert register_response.status_code == 201
    assert register_response.json()["username"] == "trimmed_user"

    app.dependency_overrides.clear()


def test_get_profile_accepts_hyphenless_uuid_user_id_and_returns_profile_not_found() -> None:
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

    hyphenless_uuid = "123e4567e89b12d3a456426614174000"
    response = client.get(f"/profiles/{hyphenless_uuid}")
    assert response.status_code == 404
    assert response.json() == {"error": {"code": "profile_not_found", "message": "profile_not_found"}}

    app.dependency_overrides.clear()


def test_register_rejects_whitespace_only_email_after_normalization() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "   ", "username": "space_only_email_user_a"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email_required" in payload["error"]["message"]


def test_register_rejects_email_with_internal_space() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "first last@example.com", "username": "internal_space_email_user"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email_invalid_format" in payload["error"]["message"]


def test_register_rejects_email_with_internal_tab() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "first\tlast@example.com", "username": "internal_tab_email_user"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email_invalid_format" in payload["error"]["message"]


def test_register_rejects_email_with_internal_newline() -> None:
    client = TestClient(app)

    response = client.post(
        "/auth/register",
        json={"email": "first\nlast@example.com", "username": "internal_newline_email_user"},
    )
    assert response.status_code == 422
    payload = response.json()
    assert payload["error"]["code"] == "validation_error"
    assert "email_invalid_format" in payload["error"]["message"]


def test_get_profile_returns_profile_not_found_for_nil_uuid() -> None:
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

    nil_uuid = "00000000-0000-0000-0000-000000000000"
    response = client.get(f"/profiles/{nil_uuid}")
    assert response.status_code == 404
    assert response.json() == {"error": {"code": "profile_not_found", "message": "profile_not_found"}}

    app.dependency_overrides.clear()


def test_upsert_profile_accepts_empty_avatar_url_and_persists_it() -> None:
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
        json={"email": "empty-avatar@example.com", "username": "empty_avatar_user"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    upsert_response = client.post(
        "/profiles",
        json={"user_id": user_id, "avatar_url": ""},
    )
    assert upsert_response.status_code == 201
    body = upsert_response.json()
    assert body["avatar_url"] == ""

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    assert get_response.json()["avatar_url"] == ""

    app.dependency_overrides.clear()


def test_upsert_profile_preserves_empty_avatar_across_display_name_and_bio_only_updates() -> None:
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
        json={"email": "empty-avatar-followup@example.com", "username": "empty_avatar_followup"},
    )
    assert register_response.status_code == 201
    user_id = register_response.json()["id"]

    first_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "Before name",
            "bio": "Before bio",
            "avatar_url": "",
        },
    )
    assert first_upsert.status_code == 201
    first_body = first_upsert.json()
    assert first_body["avatar_url"] == ""

    display_name_only_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "display_name": "After name",
        },
    )
    assert display_name_only_upsert.status_code == 201
    display_name_only_body = display_name_only_upsert.json()
    assert display_name_only_body["display_name"] == "After name"
    assert display_name_only_body["bio"] == "Before bio"
    assert display_name_only_body["avatar_url"] == ""

    bio_only_upsert = client.post(
        "/profiles",
        json={
            "user_id": user_id,
            "bio": "After bio",
        },
    )
    assert bio_only_upsert.status_code == 201
    bio_only_body = bio_only_upsert.json()
    assert bio_only_body["display_name"] == "After name"
    assert bio_only_body["bio"] == "After bio"
    assert bio_only_body["avatar_url"] == ""

    get_response = client.get(f"/profiles/{user_id}")
    assert get_response.status_code == 200
    persisted = get_response.json()
    assert persisted["display_name"] == "After name"
    assert persisted["bio"] == "After bio"
    assert persisted["avatar_url"] == ""

    app.dependency_overrides.clear()
