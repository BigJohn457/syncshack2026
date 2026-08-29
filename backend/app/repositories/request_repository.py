import json
from collections.abc import Callable
from math import asin, cos, radians, sin, sqrt

from app.database import get_db_connection
from app.models import MeetupRequest

EARTH_RADIUS_KM = 6371.0


def haversine_km(
    latitude_1: float, longitude_1: float, latitude_2: float, longitude_2: float
) -> float:
    delta_latitude = radians(latitude_2 - latitude_1)
    delta_longitude = radians(longitude_2 - longitude_1)
    origin_latitude = radians(latitude_1)
    target_latitude = radians(latitude_2)
    chord = (
        sin(delta_latitude / 2) ** 2
        + cos(origin_latitude) * cos(target_latitude) * sin(delta_longitude / 2) ** 2
    )
    return 2 * EARTH_RADIUS_KM * asin(sqrt(chord))


class UserNotFoundError(Exception):
    pass


class RequestNotFoundError(Exception):
    pass


class RequestPermissionError(Exception):
    pass


class RequestCancellationError(Exception):
    pass


class RequestRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def create(self, meetup_request: MeetupRequest) -> MeetupRequest:
        """Persist a request in one transaction."""
        connection = self.connection_factory()
        cursor = connection.cursor()

        try:
            cursor.execute(
                "SELECT 1 FROM users WHERE id = %s LIMIT 1",
                (meetup_request.creator_id,),
            )
            if cursor.fetchone() is None:
                raise UserNotFoundError(meetup_request.creator_id)

            cursor.execute(
                """
                INSERT INTO requests (
                    request_id, creator_id, title, location, min_people,
                    max_people, meet_time, expires_at, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    meetup_request.request_id,
                    meetup_request.creator_id,
                    meetup_request.title,
                    json.dumps(meetup_request.location.__dict__),
                    meetup_request.min_people,
                    meetup_request.max_people,
                    meetup_request.meet_time,
                    meetup_request.expires_at,
                    meetup_request.status,
                ),
            )
            connection.commit()
            return meetup_request
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def find_nearby(
        self, latitude: float, longitude: float, radius: float
    ) -> list[MeetupRequest]:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    request_id, creator_id, title, location, min_people,
                    max_people, meet_time, expires_at, status
                FROM requests
                WHERE status = 'open'
                """
            )
            nearby: list[MeetupRequest] = []
            for row in cursor.fetchall():
                meetup_request = MeetupRequest.from_row(row)
                distance = haversine_km(
                    latitude,
                    longitude,
                    meetup_request.location.latitude,
                    meetup_request.location.longitude,
                )
                if distance <= radius:
                    nearby.append(meetup_request)
            return nearby
        finally:
            cursor.close()
            connection.close()

    def get_details(self, request_id: str) -> dict:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    u.anonymous_name,
                    u.reliability_score,
                    r.location,
                    r.min_people,
                    r.max_people,
                    r.meet_time,
                    r.expires_at
                FROM requests AS r
                JOIN users AS u ON u.id = r.creator_id
                WHERE r.request_id = %s
                LIMIT 1
                """,
                (request_id,),
            )
            row = cursor.fetchone()
            if row is None:
                raise RequestNotFoundError(request_id)

            location = row["location"]
            if isinstance(location, str):
                try:
                    location = json.loads(location)
                except json.JSONDecodeError:
                    pass
            if isinstance(location, dict):
                location = location.get("place_name", "")

            return {
                "anonymous_name": row["anonymous_name"],
                "reliability_score": float(row["reliability_score"]),
                "location": location,
                "min_people": int(row["min_people"]),
                "max_people": int(row["max_people"]),
                "meet_time": row["meet_time"].isoformat(),
                "expires_at": row["expires_at"].isoformat(),
            }
        finally:
            cursor.close()
            connection.close()

    def get_own_request(self, request_id: str) -> dict:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                "SELECT location FROM requests WHERE request_id = %s LIMIT 1",
                (request_id,),
            )
            row = cursor.fetchone()
            if row is None:
                raise RequestNotFoundError(request_id)

            location = row["location"]
            if isinstance(location, str):
                location = json.loads(location)

            return {"location": location}
        finally:
            cursor.close()
            connection.close()

    def cancel(self, request_id: str, user_id: str) -> dict[str, str]:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    r.creator_id,
                    r.status AS request_status,
                    m.meetup_id,
                    m.status AS meetup_status
                FROM requests AS r
                LEFT JOIN meetups AS m ON m.request_id = r.request_id
                WHERE r.request_id = %s
                LIMIT 1
                FOR UPDATE
                """,
                (request_id,),
            )
            row = cursor.fetchone()
            if row is None:
                raise RequestNotFoundError(request_id)
            if row["creator_id"] != user_id:
                raise RequestPermissionError()
            if row["request_status"] in {"cancelled", "expired"}:
                raise RequestCancellationError(
                    f"request is already {row['request_status']}"
                )
            if row["meetup_status"] == "completed":
                raise RequestCancellationError("completed meetup cannot be cancelled")

            cursor.execute(
                "UPDATE requests SET status = 'cancelled' WHERE request_id = %s",
                (request_id,),
            )
            cursor.execute(
                """
                UPDATE request_participants
                SET status = 'cancelled'
                WHERE request_id = %s AND status IN ('pending', 'accepted')
                """,
                (request_id,),
            )

            if row["meetup_id"] is not None:
                cursor.execute(
                    "UPDATE meetups SET status = 'cancelled' WHERE meetup_id = %s",
                    (row["meetup_id"],),
                )
                cursor.execute(
                    """
                    UPDATE meetup_participants
                    SET attendance_status = 'cancelled'
                    WHERE meetup_id = %s AND attendance_status = 'joined'
                    """,
                    (row["meetup_id"],),
                )

            connection.commit()
            return {"request_id": request_id, "status": "cancelled"}
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()
