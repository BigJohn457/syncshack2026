from datetime import datetime

from app.repositories import MeetupRepository


class FakeCursor:
    def __init__(self, rows):
        self.rows = iter(rows)

    def execute(self, query, params):
        self.params = params

    def fetchone(self):
        return next(self.rows)

    def close(self):
        pass


class FakeConnection:
    def __init__(self, rows):
        self.fake_cursor = FakeCursor(rows)

    def cursor(self, dictionary=False):
        assert dictionary is True
        return self.fake_cursor

    def close(self):
        pass


def test_participant_status_maps_both_participant_tables():
    connection = FakeConnection(
        [
            {"request_id": "request-001"},
            {
                "attendance_status": "joined",
                "joined_at": datetime(2026, 8, 30, 9, 0),
            },
            {
                "status": "accepted",
                "joined_at": datetime(2026, 8, 30, 8, 50),
                "updated_at": datetime(2026, 8, 30, 9, 0),
            },
        ]
    )
    repository = MeetupRepository(lambda: connection)

    result = repository.get_participant_status("meetup-001", "user-123")

    assert result["meetup_participant"] == {
        "exists": True,
        "attendance_status": "joined",
        "joined_at": "2026-08-30T09:00:00",
    }
    assert result["request_participant"]["status"] == "accepted"


def test_participant_status_returns_explicit_missing_flags():
    connection = FakeConnection([{"request_id": "request-001"}, None, None])
    repository = MeetupRepository(lambda: connection)

    result = repository.get_participant_status("meetup-001", "user-123")

    assert result["meetup_participant"]["exists"] is False
    assert result["request_participant"]["exists"] is False
