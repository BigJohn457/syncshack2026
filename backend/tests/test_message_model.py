from datetime import datetime

import pytest

from app.models import MeetupMessage, MessageSender, MessageSubmission


def test_message_serializes_utc_database_timestamp_in_sydney_time():
    message = MeetupMessage(
        id="msg-001",
        sender_id="user-123",
        sender=MessageSender("Blue Panda", "https://example.com/avatar1.jpg"),
        message="Hey! I'm already at the cafe",
        created_at=datetime(2026, 8, 29, 2, 25, 14),
    )

    result = message.to_dict("Australia/Sydney")

    assert result["created_at"] == "2026-08-29T12:25:14+10:00"
    assert result["sender"]["anonymous_name"] == "Blue Panda"


def test_message_submission_validates_input():
    submission = MessageSubmission.from_dict(
        {"meetup_id": "meetup-001", "message": " Hello everyone! "}
    )

    assert submission.message == "Hello everyone!"


def test_message_submission_rejects_empty_message():
    with pytest.raises(ValueError, match="message is required"):
        MessageSubmission.from_dict({"meetup_id": "meetup-001", "message": " "})
