from flask import Blueprint, jsonify, request
from mysql.connector import Error as MySQLError, IntegrityError

from app.models import UserProfileUpdate
from app.repositories import ProfileUserNotFoundError, UserRepository

users = Blueprint("users", __name__, url_prefix="/users")
user_repository = UserRepository()


@users.get("")
def list_users():
    """Return users. Connect this route to a users repository."""
    return jsonify(users=[]), 200


@users.get("/get/own-profile")
def get_own_profile():
    body = request.get_json(silent=True) or {}
    user_id = request.args.get("id")
    if user_id is None:
        user_id = body.get("id")

    if not isinstance(user_id, (str, int)) or not str(user_id).strip():
        return jsonify(success=False, error="id is required"), 400

    try:
        profile = user_repository.get_profile(str(user_id).strip())
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user not found"), 404

    return jsonify(success=True, data=profile.to_dict()), 200


@users.post("/post/edit-profile")
def edit_own_profile():
    user_id = request.headers.get("X-User-ID", "").strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        update = UserProfileUpdate.from_dict(request.get_json(silent=True))
        profile = user_repository.update_profile(user_id, update)
    except ValueError as exc:
        return jsonify(success=False, error=str(exc)), 400
    except ProfileUserNotFoundError:
        return jsonify(success=False, error="user not found"), 404
    except IntegrityError as exc:
        if exc.errno == 1062:
            return jsonify(success=False, error="email is already in use"), 409
        return jsonify(success=False, error="database operation failed"), 500
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=profile.to_dict()), 200
