from flask import Blueprint, jsonify

rating = Blueprint("rating", __name__, url_prefix="/ratings")


@rating.get("")
def list_ratings():
    """Return ratings. Connect this route to a rating repository."""
    return jsonify(ratings=[]), 200
