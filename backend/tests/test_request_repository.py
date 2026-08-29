import json
from datetime import datetime

from app.repositories.request_repository import RequestRepository


class FakeCursor:
    def __init__(self, rows):
        self.rows = rows
        self.closed = False

    def execute(self, query, params=None):
        self.query = query

    def fetchall(self):
        return self.rows

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self, rows):
        self.cursor_instance = FakeCursor(rows)
        self.closed = False

    def cursor(self, dictionary=False):
        assert dictionary is True
        return self.cursor_instance

    def close(self):
        self.closed = True


def _row(request_id, latitude, longitude, status="open"):
    return {
        "request_id": request_id,
        "creator_id": "user-id",
        "title": request_id,
        "min_people": 2,
        "max_people": 4,
        "meet_time": datetime(2026, 8, 29, 13, 0, 0),
        "location": json.dumps(
            {
                "latitude": latitude,
                "longitude": longitude,
                "place_name": request_id,
            }
        ),
        "expires_at": datetime(2026, 8, 29, 13, 30, 0),
        "status": status,
    }


def test_find_nearby_filters_by_radius_and_closes_connection():
    connection = FakeConnection(
        [
            _row("broadway", -33.8832, 151.1943),
            _row("newcastle", -32.9283, 151.7817),
        ]
    )
    repository = RequestRepository(lambda: connection)

    nearby = repository.find_nearby(-33.8832, 151.1943, radius=5)

    assert [item.request_id for item in nearby] == ["broadway"]
    assert connection.cursor_instance.closed is True
    assert connection.closed is True
