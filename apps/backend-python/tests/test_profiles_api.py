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
