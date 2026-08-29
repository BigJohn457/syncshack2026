from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError

from app.models import RatingSubmission
from app.repositories import (
    DuplicateRatingError,
    RatingEligibilityError,
    RatingRepository,
)

rating = Blueprint("rating", __name__, url_prefix="/rating")
rating_repository = RatingRepository()


@rating.get("")
def list_ratings():
    """Return ratings. Connect this route to a rating repository."""
    return jsonify(ratings=[]), 200


@rating.post("/post/submit-rating")
def submit_rating():
    from_user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not from_user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        submission = RatingSubmission.from_dict(request.get_json(silent=True))
        rating_repository.create(from_user_id, submission)
    except ValueError as exc:
        return jsonify(success=False, error=str(exc)), 400
    except RatingEligibilityError as exc:
        return jsonify(success=False, error=str(exc)), 403
    except DuplicateRatingError:
        return jsonify(success=False, error="rating already submitted"), 409
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        message="Rating submitted successfully",
        data=submission.to_dict(),
    ), 201
