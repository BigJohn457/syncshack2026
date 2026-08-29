import json
from collections.abc import Callable
from math import asin, cos, radians, sin, sqrt
from uuid import uuid4

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


class RequestJoinError(Exception):
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

    def join(self, request_id: str, user_id: str) -> dict[str, str]:
        """Create the pending participant row and return its meetup ID."""
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT creator_id, status
                FROM requests
                WHERE request_id = %s
                LIMIT 1
                FOR UPDATE
                """,
                (request_id,),
            )
            meetup_request = cursor.fetchone()
            if meetup_request is None:
                raise RequestNotFoundError(request_id)
            if meetup_request["creator_id"] == user_id:
                raise RequestJoinError("request creators cannot join their own request")
            if meetup_request["status"] != "open":
                raise RequestJoinError(
                    f"request is not open (status: {meetup_request['status']})"
                )

            cursor.execute("SELECT 1 FROM users WHERE id = %s LIMIT 1", (user_id,))
            if cursor.fetchone() is None:
                raise UserNotFoundError(user_id)

            cursor.execute(
                "SELECT meetup_id FROM meetups WHERE request_id = %s LIMIT 1",
                (request_id,),
            )
            meetup = cursor.fetchone()
            if meetup is None:
                meetup_id = str(uuid4())
                cursor.execute(
                    """
                    INSERT INTO meetups (meetup_id, request_id, status)
                    VALUES (%s, %s, 'matched')
                    """,
                    (meetup_id, request_id),
                )
                cursor.execute(
                    """
                    INSERT INTO meetup_participants (
                        meetup_id, user_id, attendance_status, is_reveal
                    ) VALUES (%s, %s, 'joined', FALSE)
                    ON DUPLICATE KEY UPDATE
                        attendance_status = 'joined', is_reveal = FALSE
                    """,
                    (meetup_id, meetup_request["creator_id"]),
                )
            else:
                meetup_id = meetup["meetup_id"]

            cursor.execute(
                """
                SELECT status FROM request_participants
                WHERE request_id = %s AND user_id = %s
                LIMIT 1
                FOR UPDATE
                """,
                (request_id, user_id),
            )
            participant = cursor.fetchone()
            if participant is None:
                cursor.execute(
                    """
                    INSERT INTO request_participants (request_id, user_id, status)
                    VALUES (%s, %s, 'pending')
                    """,
                    (request_id, user_id),
                )
                invitation_status = "pending"
            elif participant["status"] == "accepted":
                invitation_status = "accepted"
            else:
                cursor.execute(
                    """
                    UPDATE request_participants
                    SET status = 'pending'
                    WHERE request_id = %s AND user_id = %s
                    """,
                    (request_id, user_id),
                )
                invitation_status = "pending"

            connection.commit()
            return {
                "request_id": request_id,
                "meetup_id": meetup_id,
                "invitation_status": invitation_status,
            }
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def get_status(self, request_id: str, user_id: str) -> dict:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    r.request_id,
                    r.creator_id,
                    r.status AS request_status,
                    r.max_people,
                    m.meetup_id,
                    m.status AS meetup_status,
                    (
                        SELECT COUNT(*)
                        FROM request_participants AS rp
                        WHERE rp.request_id = r.request_id
                          AND rp.status = 'accepted'
                    ) AS accepted_count
                FROM requests AS r
                LEFT JOIN meetups AS m ON m.request_id = r.request_id
                WHERE r.request_id = %s
                LIMIT 1
                """,
                (request_id,),
            )
            row = cursor.fetchone()
            if row is None:
                raise RequestNotFoundError(request_id)
            if row["creator_id"] != user_id:
                raise RequestPermissionError()

            return {
                "request_id": row["request_id"],
                "meetup_id": row["meetup_id"],
                "request_status": row["request_status"],
                "meetup_status": row["meetup_status"],
                "accepted_count": int(row["accepted_count"]),
                "max_people": int(row["max_people"]),
            }
        finally:
            cursor.close()
            connection.close()

    def get_current_stage(self, user_id: str) -> dict | None:
        """Return the user's latest unfinished request/meetup from the database."""
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute(
                """
                SELECT r.request_id, r.title, r.location,
                    r.min_people, r.max_people, r.meet_time, r.expires_at,
                    r.status AS request_status, m.meetup_id,
                    m.status AS meetup_status,
                    (SELECT COUNT(*) FROM request_participants AS accepted
                     WHERE accepted.request_id = r.request_id
                       AND accepted.status = 'accepted') AS accepted_count
                FROM requests AS r
                LEFT JOIN meetups AS m ON m.request_id = r.request_id
                LEFT JOIN meetup_participants AS mp
                    ON mp.meetup_id = m.meetup_id AND mp.user_id = %s
                LEFT JOIN request_participants AS rp
                    ON rp.request_id = r.request_id AND rp.user_id = %s
                WHERE (r.creator_id = %s OR mp.user_id IS NOT NULL
                       OR rp.status IN ('pending', 'accepted'))
                  AND r.status NOT IN ('cancelled', 'expired')
                  AND COALESCE(m.status, '') != 'cancelled'
                  AND COALESCE(mp.attendance_status, 'joined')
                      NOT IN ('left', 'cancelled')
                ORDER BY CASE COALESCE(m.status, '')
                    WHEN 'completed' THEN 1 WHEN 'active' THEN 2
                    WHEN 'matched' THEN 3 ELSE 4 END, r.meet_time DESC
                LIMIT 1
                """,
                (user_id, user_id, user_id),
            )
            row = cursor.fetchone()
            if row is None:
                return None
            meetup_status = row["meetup_status"]
            stage = {
                "completed": "rating",
                "active": "meetup",
                "matched": "chat",
            }.get(meetup_status, "requesting")
            location = row["location"]
            if isinstance(location, str):
                try:
                    location = json.loads(location)
                except json.JSONDecodeError:
                    location = {}
            if not isinstance(location, dict):
                location = {}
            return {
                "stage": stage,
                "request_id": row["request_id"],
                "meetup_id": row["meetup_id"],
                "activity": row["title"],
                "place": location.get("place_name", ""),
                "latitude": float(location.get("latitude", -33.8688)),
                "longitude": float(location.get("longitude", 151.2093)),
                "min_people": int(row["min_people"]),
                "max_people": int(row["max_people"]),
                "meet_time": row["meet_time"].isoformat(),
                "expires_at": row["expires_at"].isoformat(),
                "request_status": row["request_status"],
                "meetup_status": meetup_status,
                "accepted_count": int(row["accepted_count"]),
            }
        finally:
            cursor.close()
            connection.close()
