from collections.abc import Callable
from uuid import uuid4

from app.database import get_db_connection
from app.models import RatingSubmission


class RatingEligibilityError(Exception):
    pass


class DuplicateRatingError(Exception):
    pass


class RatingRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def create(self, from_user_id: str, submission: RatingSubmission) -> None:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                "SELECT status FROM meetups WHERE meetup_id = %s LIMIT 1",
                (submission.meetup_id,),
            )
            meetup = cursor.fetchone()
            if meetup is None:
                raise RatingEligibilityError("meetup not found")
            if meetup["status"] == "cancelled":
                raise RatingEligibilityError("cancelled meetups cannot be rated")
            if from_user_id == submission.to_user_id:
                raise RatingEligibilityError("users cannot rate themselves")

            cursor.execute(
                """
                SELECT user_id, attendance_status
                FROM meetup_participants
                WHERE meetup_id = %s AND user_id IN (%s, %s)
                """,
                (submission.meetup_id, from_user_id, submission.to_user_id),
            )
            participants = {
                row["user_id"]: row["attendance_status"]
                for row in cursor.fetchall()
            }
            if participants.get(from_user_id) != "finished":
                raise RatingEligibilityError(
                    "finish your participation before submitting ratings"
                )
            if participants.get(submission.to_user_id) not in {
                "joined",
                "attended",
                "finished",
            }:
                raise RatingEligibilityError(
                    "the selected user did not participate in the meetup"
                )

            cursor.execute(
                """
                SELECT 1 FROM ratings
                WHERE meetup_id = %s AND from_user_id = %s AND to_user_id = %s
                LIMIT 1
                """,
                (submission.meetup_id, from_user_id, submission.to_user_id),
            )
            if cursor.fetchone() is not None:
                raise DuplicateRatingError()

            cursor.execute(
                """
                INSERT INTO ratings (
                    id, meetup_id, from_user_id, to_user_id, rating
                ) VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    str(uuid4()),
                    submission.meetup_id,
                    from_user_id,
                    submission.to_user_id,
                    submission.rating,
                ),
            )
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()
