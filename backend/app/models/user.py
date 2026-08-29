from dataclasses import asdict, dataclass
from typing import Any


@dataclass(frozen=True)
class UserProfile:
    first_name: str | None
    last_name: str | None
    email: str | None
    phone: str | None
    radius: float | None
    profile_image_url: str | None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class UserProfileUpdate:
    first_name: str
    last_name: str
    email: str
    phone: str
    radius: float
    profile_image_url: str | None

    @classmethod
    def from_dict(cls, data: Any) -> "UserProfileUpdate":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        required = ("first_name", "last_name", "email", "phone", "radius")
        missing = [field for field in required if field not in data]
        if missing:
            raise ValueError(f"missing required field: {missing[0]}")

        first_name = str(data["first_name"]).strip()
        last_name = str(data["last_name"]).strip()
        email = str(data["email"]).strip()
        phone = str(data["phone"]).strip()
        image = data.get("profile_image_url")
        profile_image_url = None if image is None else str(image).strip() or None

        try:
            radius = float(data["radius"])
        except (TypeError, ValueError) as exc:
            raise ValueError("radius must be a number") from exc

        if not first_name or len(first_name) > 100:
            raise ValueError("first_name must contain 1 to 100 characters")
        if not last_name or len(last_name) > 100:
            raise ValueError("last_name must contain 1 to 100 characters")
        if not email or len(email) > 255 or "@" not in email:
            raise ValueError("email must be a valid email address")
        if len(phone) > 30:
            raise ValueError("phone cannot exceed 30 characters")
        if radius < 0:
            raise ValueError("radius cannot be negative")

        return cls(
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone,
            radius=radius,
            profile_image_url=profile_image_url,
        )

    def to_profile(self) -> UserProfile:
        return UserProfile(**asdict(self))
