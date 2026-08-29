from dataclasses import asdict, dataclass
from typing import Any


@dataclass(frozen=True)
class RatingSubmission:
    meetup_id: str
    to_user_id: str
    rating: int

    @classmethod
    def from_dict(cls, data: Any) -> "RatingSubmission":
        if not isinstance(data, dict):
            raise ValueError("request body must be a JSON object")

        try:
            meetup_id = str(data["meetup_id"]).strip()
            to_user_id = str(data["to_user_id"]).strip()
            rating = int(data["rating"])
        except KeyError as exc:
            raise ValueError(f"missing required field: {exc.args[0]}") from exc
        except (TypeError, ValueError) as exc:
            raise ValueError("rating must be an integer from 1 to 5") from exc

        if not meetup_id:
            raise ValueError("meetup_id cannot be empty")
        if not to_user_id:
            raise ValueError("to_user_id cannot be empty")
        if not 1 <= rating <= 5:
            raise ValueError("rating must be an integer from 1 to 5")

        return cls(meetup_id=meetup_id, to_user_id=to_user_id, rating=rating)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
