from dataclasses import asdict, dataclass
from typing import Any


@dataclass(frozen=True)
class InvitationAcceptance:
    meetup_id: str

    @classmethod
    def from_dict(cls, data: Any) -> "InvitationAcceptance":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        meetup_id = str(data.get("meetup_id", "")).strip()
        if not meetup_id:
            raise ValueError("meetup_id is required")
        if len(meetup_id) > 36:
            raise ValueError("meetup_id cannot exceed 36 characters")
        return cls(meetup_id=meetup_id)


@dataclass(frozen=True)
class MeetupParticipant:
    meetup_id: str
    user_id: str
    attendance_status: str
    is_reveal: bool = False

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
