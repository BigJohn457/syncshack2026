from collections.abc import Callable
from datetime import datetime
from typing import Any

from app.database import get_db_connection
from app.models import InvitationAcceptance, MeetupParticipant


class InvitationNotFoundError(Exception):
    pass


class InvitationAlreadyProcessedError(Exception):
    pass


class MeetupUnavailableError(Exception):
    pass


class MeetupRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def accept_invitation(
        self, user_id: str, acceptance: InvitationAcceptance
    ) -> MeetupParticipant:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT request_id, status
                FROM meetups
                WHERE meetup_id = %s
                LIMIT 1
                FOR UPDATE
                """,
                (acceptance.meetup_id,),
            )
            meetup = cursor.fetchone()
            if meetup is None:
                raise InvitationNotFoundError("meetup not found")
            if meetup["status"] in {"completed", "cancelled"}:
                raise MeetupUnavailableError(
                    "invitations cannot be accepted for this meetup"
                )

            cursor.execute(
                """
                SELECT status
                FROM request_participants
                WHERE request_id = %s AND user_id = %s
                LIMIT 1
                FOR UPDATE
                """,
                (meetup["request_id"], user_id),
            )
            invitation = cursor.fetchone()
            if invitation is None:
                raise InvitationNotFoundError("invitation not found")
            if invitation["status"] != "pending":
                raise InvitationAlreadyProcessedError(invitation["status"])

            cursor.execute(
                """
                UPDATE request_participants
                SET status = 'accepted'
                WHERE request_id = %s AND user_id = %s
                """,
                (meetup["request_id"], user_id),
            )
            cursor.execute(
                """
                INSERT INTO meetup_participants (
                    meetup_id, user_id, attendance_status
                ) VALUES (%s, %s, 'joined')
                ON DUPLICATE KEY UPDATE attendance_status = 'joined'
                """,
                (acceptance.meetup_id, user_id),
            )
            connection.commit()
            return MeetupParticipant(
                meetup_id=acceptance.meetup_id,
                user_id=user_id,
                attendance_status="joined",
            )
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    @staticmethod
    def _serialize_datetime(value: datetime | None) -> str | None:
        return value.isoformat() if value is not None else None

    def get_participant_status(
        self, meetup_id: str, user_id: str
    ) -> dict[str, Any]:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                "SELECT request_id FROM meetups WHERE meetup_id = %s LIMIT 1",
                (meetup_id,),
            )
            meetup = cursor.fetchone()
            if meetup is None:
                raise InvitationNotFoundError("meetup not found")

            cursor.execute(
                """
                SELECT attendance_status, joined_at
                FROM meetup_participants
                WHERE meetup_id = %s AND user_id = %s
                LIMIT 1
                """,
                (meetup_id, user_id),
            )
            meetup_participant = cursor.fetchone()

            cursor.execute(
                """
                SELECT status, joined_at, updated_at
                FROM request_participants
                WHERE request_id = %s AND user_id = %s
                LIMIT 1
                """,
                (meetup["request_id"], user_id),
            )
            request_participant = cursor.fetchone()

            return {
                "meetup_id": meetup_id,
                "request_id": meetup["request_id"],
                "user_id": user_id,
                "meetup_participant": {
                    "exists": meetup_participant is not None,
                    "attendance_status": (
                        meetup_participant["attendance_status"]
                        if meetup_participant
                        else None
                    ),
                    "joined_at": self._serialize_datetime(
                        meetup_participant["joined_at"]
                        if meetup_participant
                        else None
                    ),
                },
                "request_participant": {
                    "exists": request_participant is not None,
                    "status": (
                        request_participant["status"]
                        if request_participant
                        else None
                    ),
                    "joined_at": self._serialize_datetime(
                        request_participant["joined_at"]
                        if request_participant
                        else None
                    ),
                    "updated_at": self._serialize_datetime(
                        request_participant["updated_at"]
                        if request_participant
                        else None
                    ),
                },
            }
        finally:
            cursor.close()
            connection.close()
