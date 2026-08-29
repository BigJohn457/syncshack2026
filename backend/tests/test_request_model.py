from app.models import MeetupRequest


VALID_PAYLOAD = {
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


def test_request_submission_maps_to_database_model():
    meetup_request = MeetupRequest.from_submission(
        VALID_PAYLOAD, creator_id="user-id", request_id="request-id"
    )

    assert meetup_request.title == "Lunch at Broadway"
    assert meetup_request.location.place_name == "Broadway"
    assert meetup_request.to_dict()["time"] == "2026-08-29T13:00:00"


def test_request_submission_rejects_invalid_people_range():
    payload = {**VALID_PAYLOAD, "min_people": 5, "max_people": 4}

    try:
        MeetupRequest.from_submission(payload, "user-id", "request-id")
    except ValueError as exc:
        assert str(exc) == "max_people must be greater than or equal to min_people"
    else:
        raise AssertionError("invalid people range was accepted")
