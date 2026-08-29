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


def test_request_details_returns_selected_fields(monkeypatch):
    import importlib

    home_routes = importlib.import_module("app.routes.home")
    details = {
        "anonymous_name": "Blue Panda",
        "reliability_score": 4.75,
        "location": "Broadway",
        "min_people": 2,
        "max_people": 4,
        "meet_time": "2026-08-29T13:00:00",
        "expires_at": "2026-08-29T13:30:00",
    }
    monkeypatch.setattr(home_routes.request_repository, "get_details", lambda request_id: details)
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/home/get/request-details", query_string={"request_id": 123}
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": details}


def test_own_request_details_returns_selected_fields(monkeypatch):
    import importlib

    home_routes = importlib.import_module("app.routes.home")
    details = {
        "anonymous_name": "Blue Panda",
        "reliability_score": 4.75,
        "location": "Broadway",
        "min_people": 2,
        "max_people": 4,
        "meet_time": "2026-08-29T13:00:00",
        "expires_at": "2026-08-29T13:30:00",
    }
    monkeypatch.setattr(
        home_routes.request_repository,
        "get_details",
        lambda request_id: details,
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/home/get/own-request-details",
            query_string={"request_id": 123},
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": details}


def test_request_details_requires_integer_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/home/get/request-details", query_string={"request_id": "abc"}
        )

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "request_id must be an integer",
    }


def test_own_request_returns_location(monkeypatch):
    import importlib

    home_routes = importlib.import_module("app.routes.home")
    location = {
        "latitude": -33.8832,
        "longitude": 151.1943,
        "place_name": "Broadway",
    }
    monkeypatch.setattr(
        home_routes.request_repository,
        "get_own_request",
        lambda request_id: {"location": location},
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/home/get/own-request", query_string={"request_id": 123}
        )

    assert response.status_code == 200
    assert response.get_json() == {
        "success": True,
        "data": {"location": location},
    }


def test_own_request_requires_integer_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/home/get/own-request")

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "request_id must be an integer",
    }


def test_feature_routes_are_registered_separately():
    app = create_app("testing")

    expected_responses = {
        "/api/request": {"requests": []},
        "/api/meetup-chat": {"meetup_chats": []},
        "/api/meetups": {"meetups": []},
        "/api/ratings": {"ratings": []},
        "/api/users": {"users": []},
    }

    with app.test_client() as client:
        for path, expected_json in expected_responses.items():
            response = client.get(path)
            assert response.status_code == 200
            assert response.get_json() == expected_json


def test_get_all_users_profiles_returns_shared_profile(monkeypatch):
    import importlib

    meetup_routes = importlib.import_module("app.routes.meetup")
    profile = {
        "first_name": "Blue",
        "last_name": "Panda",
        "profile_image_url": "https://example.com/avatar.jpg",
        "reliability_score": 4.75,
    }
    monkeypatch.setattr(
        meetup_routes.user_repository,
        "get_shared_profile",
        lambda user_id: profile,
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup/get/all-users-profiles", query_string={"id": 123}
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": profile}


def test_get_all_users_profiles_requires_integer_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup/get/all-users-profiles", query_string={"id": "abc"}
        )

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "id must be an integer",
    }


def test_get_all_anonymous_profiles_returns_profile(monkeypatch):
    import importlib

    meetup_routes = importlib.import_module("app.routes.meetup")
    profile = {
        "anonymous_name": "Blue Panda",
        "profile_image_url": "https://example.com/avatar.jpg",
        "reliability_score": 4.75,
    }
    monkeypatch.setattr(
        meetup_routes.user_repository,
        "get_anonymous_profile",
        lambda user_id: profile,
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup/get/all-anonymous-profiles",
            query_string={"id": 123},
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": profile}


def test_get_all_anonymous_profiles_requires_integer_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/meetup/get/all-anonymous-profiles")

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "id must be an integer",
    }


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


def test_get_all_requests_requires_coordinates():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get("/api/request/get/all-request")

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "longitude, latitude, and radius are required",
    }


def test_get_all_requests_returns_nearby_locations(monkeypatch):
    import importlib

    nearby = MeetupRequest.from_submission(
        {
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
        },
        creator_id="user-id",
        request_id="request-id",
    )
    request_routes = importlib.import_module("app.routes.request")
    monkeypatch.setattr(
        request_routes.request_repository,
        "find_nearby",
        lambda latitude, longitude, radius: [nearby],
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/request/get/all-request",
            query_string={
                "longitude": 151.1943,
                "latitude": -33.8832,
                "radius": 5,
            },
        )

    body = response.get_json()
    assert response.status_code == 200
    assert body["success"] is True
    assert body["data"][0]["location"] == {
        "latitude": -33.8832,
        "longitude": 151.1943,
        "place_name": "Broadway",
    }


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
            "/api/users/get/own-profile", query_string={"id": 123}
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


def test_get_own_profile_rejects_non_integer_id():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/users/get/own-profile", query_string={"id": "user-123"}
        )

    assert response.status_code == 400
    assert response.get_json() == {
        "success": False,
        "error": "id must be an integer",
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
    assert response.get_json() == {"success": True, "data": {}}
