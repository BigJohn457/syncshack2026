from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any
from zoneinfo import ZoneInfo


@dataclass(frozen=True)
class MessageSender:
    anonymous_name: str
    img_url: str | None

    def to_dict(self) -> dict[str, Any]:
        return {
            "anonymous_name": self.anonymous_name,
            "img_url": self.img_url,
        }


@dataclass(frozen=True)
class MeetupMessage:
    id: str
    sender_id: str
    sender: MessageSender
    message: str
    created_at: datetime

    def to_dict(self, timezone_name: str) -> dict[str, Any]:
        created_at = self.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=UTC)

        return {
            "id": self.id,
            "sender_id": self.sender_id,
            "sender": self.sender.to_dict(),
            "message": self.message,
            "created_at": created_at.astimezone(ZoneInfo(timezone_name)).isoformat(),
        }


@dataclass(frozen=True)
class MessageSubmission:
    meetup_id: str
    message: str

    @classmethod
    def from_dict(cls, data: Any) -> "MessageSubmission":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        meetup_id = str(data.get("meetup_id", "")).strip()
        message = str(data.get("message", "")).strip()
        if not meetup_id:
            raise ValueError("meetup_id is required")
        if len(meetup_id) > 36:
            raise ValueError("meetup_id cannot exceed 36 characters")
        if not message:
            raise ValueError("message is required")
        if len(message) > 5000:
            raise ValueError("message cannot exceed 5000 characters")

        return cls(meetup_id=meetup_id, message=message)
