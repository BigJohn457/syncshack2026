from flask import Blueprint, jsonify

meetup = Blueprint("meetup", __name__, url_prefix="/meetups")


@meetup.get("")
def list_meetups():
    """Return meetups. Connect this route to a meetup repository."""
    return jsonify(meetups=[]), 200
