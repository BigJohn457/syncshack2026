import pytest

from app.models import RatingSubmission


def test_rating_submission_parses_valid_payload():
    submission = RatingSubmission.from_dict(
        {"meetup_id": "meetup_123", "to_user_id": "user_456", "rating": 5}
    )

    assert submission.to_dict() == {
        "meetup_id": "meetup_123",
        "to_user_id": "user_456",
        "rating": 5,
    }


@pytest.mark.parametrize("value", [0, 6, "bad"])
def test_rating_submission_rejects_invalid_rating(value):
    with pytest.raises(ValueError, match="rating must be an integer from 1 to 5"):
        RatingSubmission.from_dict(
            {"meetup_id": "meetup_123", "to_user_id": "user_456", "rating": value}
        )
