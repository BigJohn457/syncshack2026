from collections.abc import Callable

from app.database import get_db_connection
from app.models import UserProfile, UserProfileUpdate


class UserNotFoundError(Exception):
    pass


class UserRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def get_profile(self, user_id: int) -> UserProfile | None:
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
            )
        finally:
            cursor.close()
            connection.close()

    def get_shared_profile(self, user_id: int) -> dict | None:
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
            }
        finally:
            cursor.close()
            connection.close()

    def get_anonymous_profile(self, user_id: int) -> dict | None:
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
