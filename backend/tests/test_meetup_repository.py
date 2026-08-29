from datetime import datetime

from app.models import InvitationAcceptance
from app.repositories import MeetupRepository


class FakeCursor:
    def __init__(self, rows):
        self.rows = iter(rows)

    def execute(self, query, params):
        self.params = params
        self.queries = getattr(self, "queries", []) + [query]

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

    def commit(self):
        self.committed = True

    def rollback(self):
        self.rolled_back = True


def test_participant_status_maps_both_participant_tables():
    connection = FakeConnection(
        [
            {"request_id": "request-001"},
            {
                "attendance_status": "joined",
                "joined_at": datetime(2026, 8, 30, 9, 0),
                "is_reveal": False,
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
        "is_reveal": False,
    }
    assert result["request_participant"]["status"] == "accepted"


def test_participant_status_returns_explicit_missing_flags():
    connection = FakeConnection([{"request_id": "request-001"}, None, None])
    repository = MeetupRepository(lambda: connection)

    result = repository.get_participant_status("meetup-001", "user-123")

    assert result["meetup_participant"]["exists"] is False
    assert result["request_participant"]["exists"] is False


def test_finishing_last_participant_completes_meetup():
    connection = FakeConnection(
        [
            {"status": "active"},
            {"attendance_status": "attended"},
            {"remaining_count": 0},
        ]
    )
    repository = MeetupRepository(lambda: connection)

    result = repository.finish_participation("meetup-001", "user-123")

    assert result["attendance_status"] == "finished"
    assert result["meetup_completed"] is True
    assert any(
        "UPDATE meetups SET status = 'completed'" in query
        for query in connection.fake_cursor.queries
    )
    assert connection.committed is True


def test_finishing_before_other_participants_does_not_complete_meetup():
    connection = FakeConnection(
        [
            {"status": "active"},
            {"attendance_status": "joined"},
            {"remaining_count": 1},
        ]
    )
    repository = MeetupRepository(lambda: connection)

    result = repository.finish_participation("meetup-001", "user-123")

    assert result["meetup_completed"] is False
    assert not any(
        "UPDATE meetups SET status = 'completed'" in query
        for query in connection.fake_cursor.queries
    )


def test_accepting_last_available_place_marks_request_as_matched():
    connection = FakeConnection(
        [
            {"request_id": "request-001", "status": "matched"},
            {"status": "pending"},
            {"max_people": 2, "accepted_count": 1},
        ]
    )
    repository = MeetupRepository(lambda: connection)

    repository.accept_invitation(
        "user-123",
        InvitationAcceptance(meetup_id="meetup-001"),
    )

    assert any(
        "UPDATE requests SET status = 'matched'" in query
        for query in connection.fake_cursor.queries
    )


def test_accepting_before_capacity_keeps_request_open():
    connection = FakeConnection(
        [
            {"request_id": "request-001", "status": "matched"},
            {"status": "pending"},
            {"max_people": 3, "accepted_count": 1},
        ]
    )
    repository = MeetupRepository(lambda: connection)

    repository.accept_invitation(
        "user-123",
        InvitationAcceptance(meetup_id="meetup-001"),
    )

    assert not any(
        "UPDATE requests SET status = 'matched'" in query
        for query in connection.fake_cursor.queries
    )
