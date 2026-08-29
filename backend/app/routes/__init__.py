"""Blueprints for each API feature area."""

from .home import home
from .meetup import meetup, meetup_api
from .meetup_chat import meetup_chat
from .rating import rating
from .request import request
from .users import users

blueprints = (home, request, meetup_chat, meetup, meetup_api, rating, users)

__all__ = ["blueprints"]
