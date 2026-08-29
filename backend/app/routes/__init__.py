"""Blueprints for each API feature area."""

from .auth import auth
from .home import home
from .meetup import meetup, meetup_api
from .meetup_chat import meetup_chat
from .rating import rating
from .request import request
from .users import users
from .upload import upload

blueprints = (
    home,
    auth,
    request,
    meetup_chat,
    meetup,
    meetup_api,
    rating,
    users,
    upload,
)

__all__ = ["blueprints"]
