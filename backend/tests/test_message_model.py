from datetime import datetime

from app.models import MeetupMessage, MessageSender


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
