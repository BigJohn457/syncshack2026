from uuid import uuid4

from flask import Blueprint, jsonify, request as flask_request
from mysql.connector import Error as MySQLError

from app.models import MeetupRequest
from app.repositories import RequestRepository, UserNotFoundError

request = Blueprint("request", __name__, url_prefix="/request")
request_repository = RequestRepository()


@request.get("")
def list_requests():
    """Return requests. Connect this route to a request repository."""
    return jsonify(requests=[]), 200


@request.post("/post/submit-request")
def submit_request():
    creator_id = flask_request.headers.get("X-User-ID", "").strip()
    if not creator_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        meetup_request = MeetupRequest.from_submission(
            flask_request.get_json(silent=True), creator_id, str(uuid4())
        )
        created_request = request_repository.create(meetup_request)
    except ValueError as exc:
        return jsonify(success=False, error=str(exc)), 400
    except UserNotFoundError:
        return jsonify(success=False, error="user not found"), 404
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=created_request.to_dict()), 201
