from flask import Blueprint, current_app, jsonify, request
from mysql.connector import Error as MySQLError

from app.repositories import MeetupChatRepository, MeetupNotFoundError

meetup_chat = Blueprint("meetup_chat", __name__, url_prefix="/meetup-chat")
meetup_chat_repository = MeetupChatRepository()


@meetup_chat.get("")
def list_meetup_chats():
    """Return meetup chats. Connect this route to a chat repository."""
    return jsonify(meetup_chats=[]), 200


@meetup_chat.get("/get/all-messages")
def get_all_messages():
    body = request.get_json(silent=True) or {}
    meetup_id = request.args.get("meetup_id") or body.get("meetup_id")
    if not isinstance(meetup_id, str) or not meetup_id.strip():
        return jsonify(success=False, error="meetup_id is required"), 400

    meetup_id = meetup_id.strip()
    try:
        messages = meetup_chat_repository.get_all_messages(meetup_id)
    except MeetupNotFoundError:
        return jsonify(success=False, error="meetup not found"), 404
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    timezone_name = current_app.config["API_TIMEZONE"]
    return jsonify(
        success=True,
        data={
            "meetup_id": meetup_id,
            "messages": [message.to_dict(timezone_name) for message in messages],
        },
    ), 200
