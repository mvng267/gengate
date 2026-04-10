from fastapi.testclient import TestClient

from app.main import app


def test_get_profile_returns_422_contract_for_invalid_uuid_format() -> None:
    client = TestClient(app)

    response = client.get("/profiles/123e4567-e89b-12d3-a456-42661417400Z")

    assert response.status_code == 422
    payload = response.json()
    assert set(payload.keys()) == {"error"}
    assert set(payload["error"].keys()) == {"code", "message"}
    assert payload["error"]["code"] == "validation_error"
    assert "user_id" in payload["error"]["message"]
    assert "uuid" in payload["error"]["message"].lower()
