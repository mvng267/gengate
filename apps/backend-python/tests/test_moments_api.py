import uuid

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.db import get_db_session
from app.main import app
from app.models import all_models
from app.models.base import Base


def create_test_client() -> TestClient:
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
    return TestClient(app)


def clear_overrides() -> None:
    app.dependency_overrides.clear()


def test_moment_crud_flow() -> None:
    client = create_test_client()

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

    clear_overrides()


def test_list_moments_for_author_includes_media_items() -> None:
    client = create_test_client()

    user = client.post("/auth/register", json={"email": "moment-list@example.com", "username": "moment_list"})
    user_id = user.json()["id"]
    uuid.UUID(user_id)

    create_response = client.post(
        "/moments",
        json={"author_user_id": user_id, "caption_text": "sunset caption"},
    )
    assert create_response.status_code == 201
    moment_id = create_response.json()["id"]

    media_response = client.post(
        f"/moments/{moment_id}/media",
        json={
            "media_type": "image",
            "storage_key": "moments/sunset.jpg",
            "mime_type": "image/jpeg",
            "width": 1080,
            "height": 1350,
        },
    )
    assert media_response.status_code == 201

    list_response = client.get(f"/moments?author_user_id={user_id}")
    assert list_response.status_code == 200
    payload = list_response.json()
    assert payload["count"] == 1
    assert payload["items"][0]["author"]["id"] == user_id
    assert payload["items"][0]["caption_text"] == "sunset caption"
    assert payload["items"][0]["media_items"][0]["storage_key"] == "moments/sunset.jpg"

    clear_overrides()


def test_private_friend_feed_lists_viewer_and_accepted_friend_moments_only() -> None:
    client = create_test_client()

    viewer = client.post("/auth/register", json={"email": "viewer@example.com", "username": "viewer_u"})
    friend = client.post("/auth/register", json={"email": "friend@example.com", "username": "friend_u"})
    stranger = client.post("/auth/register", json={"email": "stranger@example.com", "username": "stranger_u"})
    viewer_id = viewer.json()["id"]
    friend_id = friend.json()["id"]
    stranger_id = stranger.json()["id"]

    request_response = client.post(
        "/friends/requests",
        json={"requester_user_id": viewer_id, "receiver_user_id": friend_id},
    )
    assert request_response.status_code == 201
    request_id = request_response.json()["id"]
    accept_response = client.post(f"/friends/requests/{request_id}/accept")
    assert accept_response.status_code == 201

    viewer_moment = client.post(
        "/moments",
        json={"author_user_id": viewer_id, "caption_text": "viewer-own moment"},
    )
    assert viewer_moment.status_code == 201

    friend_moment = client.post(
        "/moments",
        json={"author_user_id": friend_id, "caption_text": "friend-only moment"},
    )
    assert friend_moment.status_code == 201
    friend_moment_id = friend_moment.json()["id"]
    friend_media = client.post(
        f"/moments/{friend_moment_id}/media",
        json={
            "media_type": "image",
            "storage_key": "moments/friend-feed.jpg",
            "mime_type": "image/jpeg",
            "width": 720,
            "height": 720,
        },
    )
    assert friend_media.status_code == 201

    stranger_moment = client.post(
        "/moments",
        json={"author_user_id": stranger_id, "caption_text": "stranger moment"},
    )
    assert stranger_moment.status_code == 201

    feed_response = client.get(f"/moments/feed?viewer_user_id={viewer_id}")
    assert feed_response.status_code == 200
    payload = feed_response.json()
    assert payload["count"] == 2

    items = payload["items"]
    captions = {item["caption_text"] for item in items}
    author_ids = {item["author"]["id"] for item in items}

    assert captions == {"viewer-own moment", "friend-only moment"}
    assert author_ids == {viewer_id, friend_id}
    assert stranger_id not in author_ids

    friend_item = next(item for item in items if item["author"]["id"] == friend_id)
    assert friend_item["media_items"][0]["storage_key"] == "moments/friend-feed.jpg"

    clear_overrides()


def test_deleted_moment_is_hidden_from_author_list_and_private_feed() -> None:
    client = create_test_client()

    viewer = client.post("/auth/register", json={"email": "viewer2@example.com", "username": "viewer2_u"})
    friend = client.post("/auth/register", json={"email": "friend2@example.com", "username": "friend2_u"})
    viewer_id = viewer.json()["id"]
    friend_id = friend.json()["id"]

    request_response = client.post(
        "/friends/requests",
        json={"requester_user_id": viewer_id, "receiver_user_id": friend_id},
    )
    assert request_response.status_code == 201
    request_id = request_response.json()["id"]
    accept_response = client.post(f"/friends/requests/{request_id}/accept")
    assert accept_response.status_code == 201

    keep_moment = client.post(
        "/moments",
        json={"author_user_id": friend_id, "caption_text": "keep-visible"},
    )
    assert keep_moment.status_code == 201

    delete_moment = client.post(
        "/moments",
        json={"author_user_id": friend_id, "caption_text": "to-delete"},
    )
    assert delete_moment.status_code == 201
    delete_moment_id = delete_moment.json()["id"]

    delete_response = client.delete(f"/moments/{delete_moment_id}")
    assert delete_response.status_code == 200

    authored_response = client.get(f"/moments?author_user_id={friend_id}")
    assert authored_response.status_code == 200
    authored_payload = authored_response.json()
    captions = [item["caption_text"] for item in authored_payload["items"]]
    assert "keep-visible" in captions
    assert "to-delete" not in captions

    feed_response = client.get(f"/moments/feed?viewer_user_id={viewer_id}")
    assert feed_response.status_code == 200
    feed_payload = feed_response.json()
    feed_captions = [item["caption_text"] for item in feed_payload["items"]]
    assert "keep-visible" in feed_captions
    assert "to-delete" not in feed_captions

    clear_overrides()
