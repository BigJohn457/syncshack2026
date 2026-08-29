from werkzeug.security import generate_password_hash

from app.models import LoginData
from app.repositories import AuthRepository, InvalidCredentialsError


class FakeCursor:
    def __init__(self, row):
        self.row = row

    def execute(self, query, params):
        self.params = params

    def fetchone(self):
        return self.row

    def close(self):
        pass


class FakeConnection:
    def __init__(self, row):
        self.fake_cursor = FakeCursor(row)

    def cursor(self, dictionary=False):
        return self.fake_cursor

    def close(self):
        pass


def test_authenticate_checks_password_hash():
    connection = FakeConnection(
        {
            "id": "user-123",
            "first_name": "Blue",
            "last_name": "Panda",
            "email": "blue@example.com",
            "password": generate_password_hash("strong-password"),
        }
    )
    repository = AuthRepository(lambda: connection)

    user = repository.authenticate(
        LoginData(email="blue@example.com", password="strong-password")
    )

    assert user.id == "user-123"


def test_authenticate_rejects_wrong_password():
    connection = FakeConnection(
        {
            "id": "user-123",
            "first_name": "Blue",
            "last_name": "Panda",
            "email": "blue@example.com",
            "password": generate_password_hash("strong-password"),
        }
    )
    repository = AuthRepository(lambda: connection)

    try:
        repository.authenticate(LoginData("blue@example.com", "wrong-password"))
    except InvalidCredentialsError:
        pass
    else:
        raise AssertionError("wrong password was accepted")
