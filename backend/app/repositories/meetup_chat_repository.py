from collections.abc import Callable
from uuid import uuid4

from app.database import get_db_connection
from app.models import MeetupMessage, MessageSender, MessageSubmission


class MeetupNotFoundError(Exception):
    pass


class ChatAccessDeniedError(Exception):
    pass


class MeetupChatRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def get_all_messages(self, meetup_id: str) -> list[MeetupMessage]:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                "SELECT 1 FROM meetups WHERE meetup_id = %s LIMIT 1",
                (meetup_id,),
            )
            if cursor.fetchone() is None:
                raise MeetupNotFoundError(meetup_id)

            cursor.execute(
                """
                SELECT
                    m.id,
                    m.sender_id,
                    u.anonymous_name,
                    COALESCE(
                        u.profile_image_url,
                        u.img_url_face,
                        u.img_url_id
                    ) AS img_url,
                    m.message,
                    m.created_at
                FROM messages AS m
                INNER JOIN users AS u ON u.id = m.sender_id
                WHERE m.meetup_id = %s
                ORDER BY m.created_at ASC, m.id ASC
                """,
                (meetup_id,),
            )
            return [
                MeetupMessage(
                    id=row["id"],
                    sender_id=row["sender_id"],
                    sender=MessageSender(
                        anonymous_name=row["anonymous_name"],
                        img_url=row["img_url"],
                    ),
                    message=row["message"],
                    created_at=row["created_at"],
                )
                for row in cursor.fetchall()
            ]
        finally:
            cursor.close()
            connection.close()

    def create_message(
        self, sender_id: str, submission: MessageSubmission
    ) -> MeetupMessage:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)
        message_id = str(uuid4())

        try:
            cursor.execute(
                "SELECT status FROM meetups WHERE meetup_id = %s LIMIT 1",
                (submission.meetup_id,),
            )
            meetup = cursor.fetchone()
            if meetup is None:
                raise MeetupNotFoundError(submission.meetup_id)
            if meetup["status"] == "cancelled":
                raise ChatAccessDeniedError("chat is unavailable for a cancelled meetup")

            cursor.execute(
                """
                SELECT attendance_status
                FROM meetup_participants
                WHERE meetup_id = %s AND user_id = %s
                LIMIT 1
                """,
                (submission.meetup_id, sender_id),
            )
            participant = cursor.fetchone()
            allowed_statuses = {"joined", "attended"}
            if (
                participant is None
                or participant["attendance_status"] not in allowed_statuses
            ):
                raise ChatAccessDeniedError(
                    "sender is not an active participant in this meetup"
                )

            cursor.execute(
                """
                INSERT INTO messages (id, meetup_id, sender_id, message)
                VALUES (%s, %s, %s, %s)
                """,
                (message_id, submission.meetup_id, sender_id, submission.message),
            )
            cursor.execute(
                """
                SELECT
                    m.id,
                    m.sender_id,
                    u.anonymous_name,
                    COALESCE(
                        u.profile_image_url,
                        u.img_url_face,
                        u.img_url_id
                    ) AS img_url,
                    m.message,
                    m.created_at
                FROM messages AS m
                INNER JOIN users AS u ON u.id = m.sender_id
                WHERE m.id = %s
                LIMIT 1
                """,
                (message_id,),
            )
            row = cursor.fetchone()
            connection.commit()
            return MeetupMessage(
                id=row["id"],
                sender_id=row["sender_id"],
                sender=MessageSender(
                    anonymous_name=row["anonymous_name"],
                    img_url=row["img_url"],
                ),
                message=row["message"],
                created_at=row["created_at"],
            )
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()
