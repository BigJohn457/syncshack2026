from app.repositories import UserRepository


class FakeCursor:
    def __init__(self, row):
        self.row = row
        self.executed = None
        self.closed = False

    def execute(self, query, params):
        self.executed = (query, params)

    def fetchone(self):
        return self.row

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self, row):
        self.cursor_instance = FakeCursor(row)
        self.closed = False

    def cursor(self, dictionary=False):
        assert dictionary is True
        return self.cursor_instance

    def close(self):
        self.closed = True


def test_user_repository_maps_profile_and_closes_connection():
    connection = FakeConnection(
        {
            "first_name": "Blue",
            "last_name": "Panda",
            "email": "blue@example.com",
            "phone": None,
            "radius": 3.0,
            "profile_image_url": None,
        }
    )
    repository = UserRepository(lambda: connection)

    profile = repository.get_profile("user-123")

    assert profile.first_name == "Blue"
    assert profile.radius == 3.0
    assert connection.cursor_instance.executed[1] == ("user-123",)
    assert connection.cursor_instance.closed is True
    assert connection.closed is True
