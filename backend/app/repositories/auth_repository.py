from collections.abc import Callable
from uuid import uuid4

from werkzeug.security import check_password_hash, generate_password_hash

from app.database import get_db_connection
from app.models import AuthenticatedUser, LoginData, SignUpData


class EmailAlreadyExistsError(Exception):
    pass


class InvalidCredentialsError(Exception):
    pass


class AuthRepository:
    def __init__(self, connection_factory: Callable = get_db_connection):
        self.connection_factory = connection_factory

    def create_user(self, signup: SignUpData) -> AuthenticatedUser:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)
        user_id = str(uuid4())

        try:
            cursor.execute(
                "SELECT 1 FROM users WHERE email = %s LIMIT 1", (signup.email,)
            )
            if cursor.fetchone() is not None:
                raise EmailAlreadyExistsError()

            cursor.execute(
                """
                INSERT INTO users (
                    id, first_name, last_name, anonymous_name, email, password,
                    phone, img_url_id, img_url_face, profile_image_url
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    user_id,
                    signup.first_name,
                    signup.last_name,
                    f"Anonymous {user_id[:8]}",
                    signup.email,
                    generate_password_hash(signup.password),
                    signup.phone_number,
                    signup.id_photo,
                    signup.face_photo,
                    signup.face_photo,
                ),
            )
            connection.commit()
            return AuthenticatedUser(
                id=user_id,
                first_name=signup.first_name,
                last_name=signup.last_name,
                email=signup.email,
            )
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def authenticate(self, login: LoginData) -> AuthenticatedUser:
        connection = self.connection_factory()
        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute(
                """
                SELECT id, first_name, last_name, email, password
                FROM users WHERE email = %s LIMIT 1
                """,
                (login.email,),
            )
            row = cursor.fetchone()
            if row is None or not row["password"]:
                raise InvalidCredentialsError()
            if not check_password_hash(row["password"], login.password):
                raise InvalidCredentialsError()

            return AuthenticatedUser(
                id=row["id"],
                first_name=row["first_name"],
                last_name=row["last_name"],
                email=row["email"],
            )
        finally:
            cursor.close()
            connection.close()
