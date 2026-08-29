from app import create_app
from app.models import (
    MeetupMessage,
    MeetupRequest,
    MessageSender,
    UserProfile,
)
from datetime import datetime


def test_index_endpoint():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/home")

    assert response.status_code == 200
    assert response.get_json() == {"message": "Flask server is running"}


def test_health_endpoint():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/home/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_feature_routes_are_registered_separately():
    app = create_app("testing")

    expected_responses = {
        "/api/request": {"requests": []},
        "/api/meetup-chat": {"meetup_chats": []},
        "/api/meetups": {"meetups": []},
        "/api/rating": {"ratings": []},
        "/api/users": {"users": []},
    }

    with app.test_client() as client:
        for path, expected_json in expected_responses.items():
            response = client.get(path)
            assert response.status_code == 200
            assert response.get_json() == expected_json


def test_submit_request_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/request/post/submit-request", json={})

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "X-User-ID header is required",
    }


def test_submit_request_returns_created_data(monkeypatch):
    import importlib

    request_routes = importlib.import_module("app.routes.request")
    monkeypatch.setattr(
        request_routes.request_repository,
        "create",
        lambda meetup_request: meetup_request,
    )
    app = create_app("testing")
    payload = {
        "title": "Lunch at Broadway",
        "min_people": 2,
        "max_people": 4,
        "time": "2026-08-29T13:00:00",
        "location": {
            "latitude": -33.8832,
            "longitude": 151.1943,
            "place_name": "Broadway",
        },
        "expired_time": "2026-08-29T13:30:00",
    }

    with app.test_client() as client:
        response = client.post(
            "/api/request/post/submit-request",
            json=payload,
            headers={"X-User-ID": "user-id"},
        )

    body = response.get_json()
    assert response.status_code == 201
    assert body["success"] is True
    assert body["data"]["creator_id"] == "user-id"
    assert body["data"]["location"] == payload["location"]


def test_get_all_messages_requires_meetup_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/meetup-chat/get/all-messages")

    assert response.status_code == 400
    assert response.get_json()["error"] == "meetup_id is required"


def test_get_all_messages_returns_sender_details(monkeypatch):
    import importlib

    chat_routes = importlib.import_module("app.routes.meetup_chat")
    monkeypatch.setattr(
        chat_routes.meetup_chat_repository,
        "get_all_messages",
        lambda meetup_id: [
            MeetupMessage(
                id="msg-001",
                sender_id="user-123",
                sender=MessageSender(
                    "Blue Panda", "https://example.com/avatar1.jpg"
                ),
                message="Hey! I'm already at the cafe",
                created_at=datetime(2026, 8, 29, 2, 25, 14),
            )
        ],
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup-chat/get/all-messages",
            query_string={"meetup_id": "meetup-001"},
        )

    body = response.get_json()
    assert response.status_code == 200
    assert body["success"] is True
    assert body["data"]["meetup_id"] == "meetup-001"
    assert body["data"]["messages"][0]["sender"] == {
        "anonymous_name": "Blue Panda",
        "img_url": "https://example.com/avatar1.jpg",
    }


def test_get_own_profile_requires_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/users/get/own-profile")

    assert response.status_code == 400
    assert response.get_json() == {"success": False, "error": "id is required"}


def test_get_own_profile_returns_selected_user_fields(monkeypatch):
    import importlib

    user_routes = importlib.import_module("app.routes.users")
    monkeypatch.setattr(
        user_routes.user_repository,
        "get_profile",
        lambda user_id: UserProfile(
            first_name="Blue",
            last_name="Panda",
            email="blue@example.com",
            phone="0400000000",
            radius=5.5,
            profile_image_url="https://example.com/avatar.jpg",
        ),
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/users/get/own-profile", query_string={"id": "user-123"}
        )

    assert response.status_code == 200
    assert response.get_json() == {
        "success": True,
        "data": {
            "first_name": "Blue",
            "last_name": "Panda",
            "email": "blue@example.com",
            "phone": "0400000000",
            "radius": 5.5,
            "profile_image_url": "https://example.com/avatar.jpg",
        },
    }


def test_edit_profile_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/users/post/edit-profile", json={})

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_edit_profile_returns_updated_profile(monkeypatch):
    import importlib

    user_routes = importlib.import_module("app.routes.users")
    monkeypatch.setattr(
        user_routes.user_repository,
        "update_profile",
        lambda user_id, update: update.to_profile(),
    )
    app = create_app("testing")
    payload = {
        "first_name": "Blue",
        "last_name": "Panda",
        "email": "blue@example.com",
        "phone": "0400000000",
        "radius": 8.5,
        "profile_image_url": "https://example.com/avatar.jpg",
    }

    with app.test_client() as client:
        response = client.post(
            "/api/users/post/edit-profile",
            json=payload,
            headers={"X-User-ID": "user-123"},
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": payload}


def test_submit_rating_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/rating/post/submit-rating", json={})

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_submit_rating_returns_contract_response(monkeypatch):
    import importlib

    rating_routes = importlib.import_module("app.routes.rating")
    monkeypatch.setattr(
        rating_routes.rating_repository,
        "create",
        lambda from_user_id, submission: None,
    )
    app = create_app("testing")
    payload = {
        "meetup_id": "meetup_123",
        "to_user_id": "user_456",
        "rating": 5,
    }

    with app.test_client() as client:
        response = client.post(
            "/api/rating/post/submit-rating",
            json=payload,
            headers={"X-User-ID": "user_123"},
        )

    assert response.status_code == 201
    assert response.get_json() == {
        "success": True,
        "message": "Rating submitted successfully",
        "data": payload,
    }
