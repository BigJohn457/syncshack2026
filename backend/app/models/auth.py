from dataclasses import dataclass
from typing import Any
from urllib.parse import urlparse


def _required_text(data: dict[str, Any], field: str, max_length: int) -> str:
    if field not in data:
        raise ValueError(f"missing required field: {field}")
    value = str(data[field]).strip()
    if not value or len(value) > max_length:
        raise ValueError(f"{field} must contain 1 to {max_length} characters")
    return value


def _validate_url(value: str, field: str) -> str:
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"{field} must be a valid HTTP or HTTPS URL")
    return value


@dataclass(frozen=True)
class SignUpData:
    first_name: str
    last_name: str
    email: str
    password: str
    phone_number: str
    id_photo: str
    face_photo: str

    @classmethod
    def from_dict(cls, data: Any) -> "SignUpData":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        first_name = _required_text(data, "first_name", 100)
        last_name = _required_text(data, "last_name", 100)
        email = _required_text(data, "email", 255).lower()
        password = _required_text(data, "password", 128)
        phone_number = _required_text(data, "phone_number", 30)
        id_photo = _required_text(data, "id_photo", 2048)
        face_photo = _required_text(data, "face_photo", 2048)

        if "@" not in email or email.startswith("@") or email.endswith("@"):
            raise ValueError("email must be a valid email address")
        if len(password) < 8:
            raise ValueError("password must contain at least 8 characters")

        return cls(
            first_name=first_name,
            last_name=last_name,
            email=email,
            password=password,
            phone_number=phone_number,
            id_photo=_validate_url(id_photo, "id_photo"),
            face_photo=_validate_url(face_photo, "face_photo"),
        )


@dataclass(frozen=True)
class LoginData:
    email: str
    password: str

    @classmethod
    def from_dict(cls, data: Any) -> "LoginData":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")
        email = _required_text(data, "email", 255).lower()
        password = _required_text(data, "password", 128)
        return cls(email=email, password=password)


@dataclass(frozen=True)
class AuthenticatedUser:
    id: str
    first_name: str | None
    last_name: str | None
    email: str

    def to_dict(self) -> dict[str, str | None]:
        return {
            "id": self.id,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
        }
