import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def test_blocks_api_flow() -> None:
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

    blocker = client.post("/auth/register", json={"email": "blocker@example.com", "username": "blocker_u"})
    blocked = client.post("/auth/register", json={"email": "blocked@example.com", "username": "blocked_u"})
    blocker_id = blocker.json()["id"]
    blocked_id = blocked.json()["id"]
    uuid.UUID(blocker_id)
    uuid.UUID(blocked_id)

    create_response = client.post(
        "/friends/blocks",
        json={"blocker_user_id": blocker_id, "blocked_user_id": blocked_id},
    )
    assert create_response.status_code == 201
    assert create_response.json()["blocker_user_id"] == blocker_id
    assert create_response.json()["blocked_user_id"] == blocked_id

    list_response = client.get(f"/friends/blocks/{blocker_id}")
    assert list_response.status_code == 200
    assert list_response.json()["count"] == 1
    assert list_response.json()["items"][0]["blocked_user_id"] == blocked_id

    app.dependency_overrides.clear()


def test_moment_media_api_flow() -> None:
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

    user = client.post("/auth/register", json={"email": "media-author@example.com", "username": "media_author"})
    user_id = user.json()["id"]
    uuid.UUID(user_id)

    moment_response = client.post(
        "/moments",
        json={"author_user_id": user_id, "caption_text": "media moment"},
    )
    assert moment_response.status_code == 201
    moment_id = moment_response.json()["id"]

    create_media_response = client.post(
        f"/moments/{moment_id}/media",
        json={
            "media_type": "image",
            "storage_key": "moments/1.jpg",
            "mime_type": "image/jpeg",
            "width": 1200,
            "height": 800,
        },
    )
    assert create_media_response.status_code == 201
    assert create_media_response.json()["moment_id"] == moment_id

    list_media_response = client.get(f"/moments/{moment_id}/media")
    assert list_media_response.status_code == 200
    assert list_media_response.json()["count"] == 1
    assert list_media_response.json()["items"][0]["storage_key"] == "moments/1.jpg"

    app.dependency_overrides.clear()


def test_moment_reactions_api_flow() -> None:
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

    author = client.post("/auth/register", json={"email": "reaction-author@example.com", "username": "reaction_author"})
    reactor = client.post("/auth/register", json={"email": "reactor@example.com", "username": "reactor_u"})
    author_id = author.json()["id"]
    reactor_id = reactor.json()["id"]
    uuid.UUID(author_id)
    uuid.UUID(reactor_id)

    moment_response = client.post(
        "/moments",
        json={"author_user_id": author_id, "caption_text": "reaction moment"},
    )
    assert moment_response.status_code == 201
    moment_id = moment_response.json()["id"]

    create_reaction_response = client.post(
        f"/moments/{moment_id}/reactions",
        json={"user_id": reactor_id, "reaction_type": "heart"},
    )
    assert create_reaction_response.status_code == 201
    assert create_reaction_response.json()["moment_id"] == moment_id
    assert create_reaction_response.json()["reaction_type"] == "heart"

    list_reactions_response = client.get(f"/moments/{moment_id}/reactions")
    assert list_reactions_response.status_code == 200
    assert list_reactions_response.json()["count"] == 1
    assert list_reactions_response.json()["items"][0]["user_id"] == reactor_id

    app.dependency_overrides.clear()
