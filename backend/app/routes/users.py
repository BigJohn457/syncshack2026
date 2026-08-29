from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError, IntegrityError

from app.models import UserProfileUpdate
from app.logging_config import log_handled_exception
from app.repositories import ProfileUserNotFoundError, UserRepository
from ._helpers import read_varchar_id

users = Blueprint("users", __name__, url_prefix="/users")
user_repository = UserRepository()


@users.get("")
def list_users():
    """Return users. Connect this route to a users repository."""
    return jsonify(users=[]), 200


@users.get("/get/own-profile")
def get_own_profile():
    try:
        user_id = read_varchar_id(request, "id")
    except ValueError as exc:
        log_handled_exception("Own profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        profile = user_repository.get_profile(user_id)
    except MySQLError as exc:
        log_handled_exception("Own profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user not found"), 404

    return jsonify(success=True, data=profile.to_dict()), 200


@users.post("/post/edit-profile")
def edit_own_profile():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        update = UserProfileUpdate.from_dict(request.get_json(silent=True))
        user_repository.update_profile(user_id, update)
    except ValueError as exc:
        log_handled_exception("Edit profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except ProfileUserNotFoundError as exc:
        log_handled_exception("Edit profile user not found", exc)
        return jsonify(success=False, error="user not found"), 404
    except IntegrityError as exc:
        log_handled_exception("Edit profile database integrity error", exc)
        if exc.errno == 1062:
            return jsonify(success=False, error="email is already in use"), 409
        return jsonify(success=False, error="database operation failed"), 500
    except MySQLError as exc:
        log_handled_exception("Edit profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data={}), 200
