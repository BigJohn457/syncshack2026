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
