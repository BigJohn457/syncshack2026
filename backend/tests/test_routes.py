from app import create_app
from app.models import (
    AuthenticatedUser,
    MeetupMessage,
    MeetupRequest,
    MessageSender,
    UserProfile,
    MeetupParticipant,
)
from app.repositories import UploadedImage
from datetime import datetime
from io import BytesIO


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


def test_cancel_request_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/request/post/cancel-request", json={})

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_cancel_request_returns_cancelled_status(monkeypatch):
    import importlib

    request_routes = importlib.import_module("app.routes.request")
    received = []

    def cancel(request_id, user_id):
        received.append((request_id, user_id))
        return {"request_id": request_id, "status": "cancelled"}

    monkeypatch.setattr(request_routes.request_repository, "cancel", cancel)
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post(
            "/api/request/post/cancel-request",
            json={"request_id": "request-001"},
            headers={"X-User-ID": "user-123"},
        )

    assert response.status_code == 200
    assert received == [("request-001", "user-123")]
    assert response.get_json() == {
        "success": True,
        "message": "Request cancelled successfully",
        "data": {"request_id": "request-001", "status": "cancelled"},
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


def test_send_message_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/meetup-chat/post/send-message", json={})

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_send_message_returns_created_message(monkeypatch):
    import importlib

    chat_routes = importlib.import_module("app.routes.meetup_chat")
    monkeypatch.setattr(
        chat_routes.meetup_chat_repository,
        "create_message",
        lambda sender_id, submission: MeetupMessage(
            id="msg-001",
            sender_id=sender_id,
            sender=MessageSender(
                "Blue Panda", "https://example.com/avatar1.jpg"
            ),
            message=submission.message,
            created_at=datetime(2026, 8, 29, 2, 25, 14),
        ),
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post(
            "/api/meetup-chat/post/send-message",
            json={"meetup_id": "meetup-001", "message": "Hello everyone!"},
            headers={"X-User-ID": "user-123"},
        )

    assert response.status_code == 201
    assert response.get_json() == {
        "success": True,
        "message": "Message sent successfully",
        "data": {
            "meetup_id": "meetup-001",
            "message": {
                "id": "msg-001",
                "sender_id": "user-123",
                "sender": {
                    "anonymous_name": "Blue Panda",
                    "img_url": "https://example.com/avatar1.jpg",
                },
                "message": "Hello everyone!",
                "created_at": "2026-08-29T12:25:14+10:00",
            },
        },
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
    received_ids = []

    def get_profile(user_id):
        received_ids.append(user_id)
        return UserProfile(
            first_name="Blue",
            last_name="Panda",
            email="blue@example.com",
            phone="0400000000",
            radius=5.5,
            profile_image_url="https://example.com/avatar.jpg",
        )

    monkeypatch.setattr(
        user_routes.user_repository,
        "get_profile",
        get_profile,
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/users/get/own-profile",
            query_string={"id": "e8d66ac8-494f-4208-a96f-c75654504847"},
        )

    assert response.status_code == 200
    assert received_ids == ["e8d66ac8-494f-4208-a96f-c75654504847"]
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


def test_varchar_id_rejects_values_longer_than_database_column():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/users/get/own-profile", query_string={"id": "x" * 37}
        )

    assert response.status_code == 400
    assert response.get_json()["error"] == "id cannot exceed 36 characters"


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


def test_signup_creates_user_without_returning_password(monkeypatch):
    import importlib

    auth_routes = importlib.import_module("app.routes.auth")
    monkeypatch.setattr(
        auth_routes.auth_repository,
        "create_user",
        lambda signup: AuthenticatedUser(
            id="user-123",
            first_name=signup.first_name,
            last_name=signup.last_name,
            email=signup.email,
        ),
    )
    app = create_app("testing")
    payload = {
        "first_name": "Blue",
        "last_name": "Panda",
        "email": "blue@example.com",
        "password": "strong-password",
        "phone_number": "0400000000",
        "id_photo": "https://example.com/id.jpg",
        "face_photo": "https://example.com/face.jpg",
    }

    with app.test_client() as client:
        response = client.post("/api/auth/post/signup", json=payload)

    assert response.status_code == 201
    assert response.get_json()["data"]["id"] == "user-123"
    assert "password" not in response.get_json()["data"]


def test_login_sets_http_only_session_cookie(monkeypatch):
    import importlib

    auth_routes = importlib.import_module("app.routes.auth")
    monkeypatch.setattr(
        auth_routes.auth_repository,
        "authenticate",
        lambda login: AuthenticatedUser(
            id="user-123",
            first_name="Blue",
            last_name="Panda",
            email=login.email,
        ),
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post(
            "/api/auth/post/login",
            json={"email": "blue@example.com", "password": "strong-password"},
        )
        with client.session_transaction() as flask_session:
            assert flask_session["user_id"] == "user-123"

    assert response.status_code == 200
    assert "HttpOnly" in response.headers["Set-Cookie"]


def test_logout_clears_session():
    app = create_app("testing")

    with app.test_client() as client:
        with client.session_transaction() as flask_session:
            flask_session["user_id"] = "user-123"
        response = client.post("/api/auth/post/logout")
        with client.session_transaction() as flask_session:
            assert "user_id" not in flask_session

    assert response.status_code == 200


def test_accept_invitation_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/meetup/post/accept-invitation", json={})

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_accept_invitation_returns_meetup_participant(monkeypatch):
    import importlib

    meetup_routes = importlib.import_module("app.routes.meetup")
    monkeypatch.setattr(
        meetup_routes.meetup_repository,
        "accept_invitation",
        lambda user_id, acceptance: MeetupParticipant(
            meetup_id=acceptance.meetup_id,
            user_id=user_id,
            attendance_status="joined",
        ),
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post(
            "/api/meetup/post/accept-invitation",
            json={"meetup_id": "meetup-001"},
            headers={"X-User-ID": "user-123"},
        )

    assert response.status_code == 200
    assert response.get_json() == {
        "success": True,
        "message": "Invitation accepted successfully",
        "data": {
            "meetup_id": "meetup-001",
            "user_id": "user-123",
            "attendance_status": "joined",
        },
    }


def test_participant_status_requires_user_identity():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup/get/participant-status",
            query_string={"meetup_id": "meetup-001"},
        )

    assert response.status_code == 400
    assert response.get_json()["error"] == "X-User-ID header is required"


def test_participant_status_returns_both_tables(monkeypatch):
    import importlib

    meetup_routes = importlib.import_module("app.routes.meetup")
    expected = {
        "meetup_id": "meetup-001",
        "request_id": "request-001",
        "user_id": "user-123",
        "meetup_participant": {
            "exists": True,
            "attendance_status": "joined",
            "joined_at": "2026-08-30T09:00:00",
        },
        "request_participant": {
            "exists": True,
            "status": "accepted",
            "joined_at": "2026-08-30T08:50:00",
            "updated_at": "2026-08-30T09:00:00",
        },
    }
    monkeypatch.setattr(
        meetup_routes.meetup_repository,
        "get_participant_status",
        lambda meetup_id, user_id: expected,
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.get(
            "/api/meetup/get/participant-status",
            query_string={"meetup_id": "meetup-001"},
            headers={"X-User-ID": "user-123"},
        )

    assert response.status_code == 200
    assert response.get_json() == {"success": True, "data": expected}


def test_upload_picture_requires_multipart_file():
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post("/api/upload/post/picture")

    assert response.status_code == 400
    assert response.get_json()["error"] == "picture file is required"


def test_upload_picture_returns_public_url(monkeypatch):
    import importlib

    upload_routes = importlib.import_module("app.routes.upload")
    monkeypatch.setattr(
        upload_routes.image_repository,
        "upload",
        lambda picture: UploadedImage(
            url="https://mg-kopi.syd1.digitaloceanspaces.com/personal/hey/image.png",
            key="personal/hey/image.png",
        ),
    )
    app = create_app("testing")

    with app.test_client() as client:
        response = client.post(
            "/api/upload/post/picture",
            data={"picture": (BytesIO(b"image-data"), "picture.png")},
            content_type="multipart/form-data",
        )

    assert response.status_code == 201
    assert response.get_json() == {
        "success": True,
        "data": {
            "url": "https://mg-kopi.syd1.digitaloceanspaces.com/personal/hey/image.png",
            "key": "personal/hey/image.png",
        },
    }
