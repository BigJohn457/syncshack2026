from dataclasses import asdict, dataclass
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class Location:
    latitude: float
    longitude: float
    place_name: str

    @classmethod
    def from_dict(cls, data: Any) -> "Location":
        if not isinstance(data, dict):
            raise ValueError("location must be an object")

        try:
            latitude = float(data["latitude"])
            longitude = float(data["longitude"])
            place_name = str(data["place_name"]).strip()
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError(
                "location requires latitude, longitude, and place_name"
            ) from exc

        if not -90 <= latitude <= 90:
            raise ValueError("location.latitude must be between -90 and 90")
        if not -180 <= longitude <= 180:
            raise ValueError("location.longitude must be between -180 and 180")
        if not place_name:
            raise ValueError("location.place_name cannot be empty")

        return cls(latitude, longitude, place_name)


@dataclass(frozen=True)
class MeetupRequest:
    request_id: str
    creator_id: str
    title: str
    min_people: int
    max_people: int
    meet_time: datetime
    location: Location
    expires_at: datetime
    status: str = "open"

    @classmethod
    def from_submission(
        cls, data: Any, creator_id: str, request_id: str
    ) -> "MeetupRequest":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        try:
            title = str(data["title"]).strip()
            min_people = int(data["min_people"])
            max_people = int(data["max_people"])
            meet_time = datetime.fromisoformat(data["time"])
            expires_at = datetime.fromisoformat(data["expired_time"])
            location = Location.from_dict(data["location"])
        except KeyError as exc:
            raise ValueError(f"missing required field: {exc.args[0]}") from exc
        except (TypeError, ValueError) as exc:
            if isinstance(exc, ValueError) and str(exc).startswith("location"):
                raise
            raise ValueError("people counts and dates must have valid values") from exc

        if not title:
            raise ValueError("title cannot be empty")
        if min_people < 1:
            raise ValueError("min_people must be at least 1")
        if max_people < min_people:
            raise ValueError("max_people must be greater than or equal to min_people")
        if expires_at <= meet_time:
            raise ValueError("expired_time must be later than time")

        return cls(
            request_id=request_id,
            creator_id=creator_id,
            title=title,
            min_people=min_people,
            max_people=max_people,
            meet_time=meet_time,
            location=location,
            expires_at=expires_at,
        )

    def to_dict(self) -> dict[str, Any]:
        result = asdict(self)
        result["time"] = result.pop("meet_time").isoformat()
        result["expired_time"] = result.pop("expires_at").isoformat()
        return result
