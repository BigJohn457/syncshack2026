import json
from collections.abc import Callable

from app.database import get_db_connection
from app.models import UserProfile, UserProfileUpdate


class UserNotFoundError(Exception):
    pass


class UserRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def get_profile(self, user_id: str) -> UserProfile | None:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    first_name,
                    last_name,
                    email,
                    phone,
                    radius,
                    profile_image_url
                    , personalization_answers, matchmaking
                FROM users
                WHERE id = %s
                LIMIT 1
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            if row is None:
                return None

            return UserProfile(
                first_name=row["first_name"],
                last_name=row["last_name"],
                email=row["email"],
                phone=row["phone"],
                radius=float(row["radius"]) if row["radius"] is not None else None,
                profile_image_url=row["profile_image_url"],
                personalization_answers=self._answers(
                    row.get("personalization_answers")
                ),
                matchmaking=int(row.get("matchmaking") or 0),
            )
        finally:
            cursor.close()
            connection.close()

    def get_shared_profile(self, user_id: str) -> dict | None:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    first_name,
                    last_name,
                    profile_image_url,
                    reliability_score
                    , personalization_answers
                FROM users
                WHERE id = %s
                LIMIT 1
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            if row is None:
                return None

            return {
                "first_name": row["first_name"],
                "last_name": row["last_name"],
                "profile_image_url": row["profile_image_url"],
                "reliability_score": float(row["reliability_score"]),
                "personalization_answers": self._answers(
                    row.get("personalization_answers")
                ),
            }
        finally:
            cursor.close()
            connection.close()

    def get_anonymous_profile(self, user_id: str) -> dict | None:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT
                    anonymous_name,
                    profile_image_url,
                    reliability_score
                FROM users
                WHERE id = %s
                LIMIT 1
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            if row is None:
                return None

            return {
                "anonymous_name": row["anonymous_name"],
                "profile_image_url": row["profile_image_url"],
                "reliability_score": float(row["reliability_score"]),
            }
        finally:
            cursor.close()
            connection.close()

    def update_profile(
        self, user_id: str, update: UserProfileUpdate
    ) -> UserProfile:
        connection = self.connection_factory()
        cursor = connection.cursor()

        try:
            cursor.execute("SELECT 1 FROM users WHERE id = %s LIMIT 1", (user_id,))
            if cursor.fetchone() is None:
                raise UserNotFoundError(user_id)

            cursor.execute(
                """
                UPDATE users
                SET first_name = %s,
                    last_name = %s,
                    email = %s,
                    phone = %s,
                    radius = %s,
                    profile_image_url = %s
                WHERE id = %s
                """,
                (
                    update.first_name,
                    update.last_name,
                    update.email,
                    update.phone,
                    update.radius,
                    update.profile_image_url,
                    user_id,
                ),
            )
            connection.commit()
            return update.to_profile()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    @staticmethod
    def _answers(value) -> dict[str, str]:
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                return {}
        return value if isinstance(value, dict) else {}

    def update_personalization(
        self, user_id: str, answers: dict[str, str]
    ) -> None:
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                """
                UPDATE users SET personalization_answers = %s
                WHERE id = %s
                """,
                (json.dumps(answers), user_id),
            )
            if cursor.rowcount == 0:
                raise UserNotFoundError(user_id)
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def set_matchmaking(self, user_id: str, enabled: bool) -> None:
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                "UPDATE users SET matchmaking = %s WHERE id = %s",
                (1 if enabled else 0, user_id),
            )
            if cursor.rowcount == 0:
                raise UserNotFoundError(user_id)
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def get_matchmaking_profiles(self, user_ids: list[str]) -> list[dict]:
        if not user_ids:
            return []
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)
        try:
            placeholders = ", ".join(["%s"] * len(user_ids))
            cursor.execute(
                f"""
                SELECT id, first_name, last_name, radius,
                       reliability_score, personalization_answers
                FROM users WHERE id IN ({placeholders})
                """,
                tuple(user_ids),
            )
            return [
                {
                    "user_id": row["id"],
                    "name": f"{row['first_name'] or ''} {row['last_name'] or ''}".strip(),
                    "radius": float(row["radius"] or 0),
                    "reliability_score": float(row["reliability_score"] or 0),
                    "personalization_answers": self._answers(
                        row.get("personalization_answers")
                    ),
                }
                for row in cursor.fetchall()
            ]
        finally:
            cursor.close()
            connection.close()
