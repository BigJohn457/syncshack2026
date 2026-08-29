from collections.abc import Callable

from app.database import get_db_connection
from app.models import MeetupMessage, MessageSender


class MeetupNotFoundError(Exception):
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
