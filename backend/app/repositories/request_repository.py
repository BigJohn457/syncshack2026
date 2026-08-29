import json
from collections.abc import Callable

from app.database import get_db_connection
from app.models import MeetupRequest


class UserNotFoundError(Exception):
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
