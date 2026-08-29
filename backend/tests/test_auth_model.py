import pytest

from app.models import LoginData, SignUpData


VALID_SIGNUP = {
    "first_name": "Blue",
    "last_name": "Panda",
    "email": "BLUE@example.com",
    "password": "strong-password",
    "phone_number": "0400000000",
    "id_photo": "https://example.com/id.jpg",
    "face_photo": "https://example.com/face.jpg",
}


def test_signup_validates_and_normalizes_input():
    signup = SignUpData.from_dict(VALID_SIGNUP)

    assert signup.email == "blue@example.com"
    assert signup.id_photo == "https://example.com/id.jpg"


def test_signup_rejects_short_password():
    with pytest.raises(ValueError, match="at least 8 characters"):
        SignUpData.from_dict({**VALID_SIGNUP, "password": "short"})


def test_login_normalizes_email():
    login = LoginData.from_dict(
        {"email": " BLUE@example.com ", "password": "strong-password"}
    )

    assert login.email == "blue@example.com"
