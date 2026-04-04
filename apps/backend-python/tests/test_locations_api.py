import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_location_share_and_snapshot_flow() -> None:
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

    user = client.post("/auth/register", json={"email": "location-user@example.com", "username": "location_user"})
    user_id = user.json()["id"]
    uuid.UUID(user_id)

    create_share_response = client.post(
        "/locations/shares",
        json={"owner_user_id": user_id, "is_active": True, "sharing_mode": "custom_list"},
    )
    assert create_share_response.status_code == 201
    share_id = create_share_response.json()["id"]

    snapshot_response = client.post(
        "/locations/snapshots",
        json={"owner_user_id": user_id, "lat": 10.76, "lng": 106.66, "accuracy_meters": 20.0},
    )
    assert snapshot_response.status_code == 201

    list_share_response = client.get("/locations/shares")
    assert list_share_response.status_code == 200
    assert list_share_response.json()["count"] == 1

    list_snapshot_response = client.get(f"/locations/snapshots/{user_id}")
    assert list_snapshot_response.status_code == 200
    assert list_snapshot_response.json()["count"] == 1

    update_share_response = client.patch(f"/locations/shares/{share_id}", json={"is_active": False})
    assert update_share_response.status_code == 200

    app.dependency_overrides.clear()
