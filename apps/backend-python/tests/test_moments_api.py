import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_moment_crud_flow() -> None:
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

    user = client.post("/auth/register", json={"email": "moment-user@example.com", "username": "moment_user"})
    user_id = user.json()["id"]
    uuid.UUID(user_id)

    create_response = client.post(
        "/moments",
        json={"author_user_id": user_id, "caption_text": "first"},
    )
    assert create_response.status_code == 201
    moment_id = create_response.json()["id"]

    update_response = client.patch(
        f"/moments/{moment_id}",
        json={"caption_text": "updated"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["caption_text"] == "updated"

    get_response = client.get(f"/moments/{moment_id}")
    assert get_response.status_code == 200

    delete_response = client.delete(f"/moments/{moment_id}")
    assert delete_response.status_code == 200

    app.dependency_overrides.clear()
