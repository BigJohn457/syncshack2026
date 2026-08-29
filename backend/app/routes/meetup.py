from flask import Blueprint, jsonify, request
from mysql.connector import Error as MySQLError

from app.repositories import UserRepository
from app.logging_config import log_handled_exception
from ._helpers import read_varchar_id

meetup = Blueprint("meetup", __name__, url_prefix="/meetups")
meetup_api = Blueprint("meetup_api", __name__, url_prefix="/meetup")
user_repository = UserRepository()


@meetup.get("")
def list_meetups():
    """Return meetups. Connect this route to a meetup repository."""
    return jsonify(meetups=[]), 200


@meetup_api.get("/get/all-users-profiles")
def get_all_users_profiles():
    try:
        user_id = read_varchar_id(request, "id")
    except ValueError as exc:
        log_handled_exception("Shared profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        profile = user_repository.get_shared_profile(user_id)
    except MySQLError as exc:
        log_handled_exception("Shared profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user profile not found"), 404

    return jsonify(success=True, data=profile), 200


@meetup_api.get("/get/all-anonymous-profiles")
def get_all_anonymous_profiles():
    try:
        user_id = read_varchar_id(request, "id")
    except ValueError as exc:
        log_handled_exception("Anonymous profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        profile = user_repository.get_anonymous_profile(user_id)
    except MySQLError as exc:
        log_handled_exception("Anonymous profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user profile not found"), 404

    return jsonify(success=True, data=profile), 200
