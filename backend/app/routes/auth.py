from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError, IntegrityError

from app.models import LoginData, SignUpData
from app.logging_config import log_handled_exception
from app.repositories import (
    AuthRepository,
    EmailAlreadyExistsError,
    InvalidCredentialsError,
)

auth = Blueprint("auth", __name__, url_prefix="/auth")
auth_repository = AuthRepository()


@auth.post("/post/signup")
def signup():
    try:
        signup_data = SignUpData.from_dict(request.get_json(silent=True))
        user = auth_repository.create_user(signup_data)
    except ValueError as exc:
        log_handled_exception("Signup validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except EmailAlreadyExistsError as exc:
        log_handled_exception("Signup email already exists", exc)
        return jsonify(success=False, error="email is already registered"), 409
    except IntegrityError as exc:
        log_handled_exception("Signup database integrity error", exc)
        if exc.errno == 1062:
            return jsonify(success=False, error="email is already registered"), 409
        return jsonify(success=False, error="database operation failed"), 500
    except MySQLError as exc:
        log_handled_exception("Signup database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=user.to_dict()), 201


@auth.post("/post/login")
def login():
    try:
        login_data = LoginData.from_dict(request.get_json(silent=True))
        user = auth_repository.authenticate(login_data)
    except ValueError as exc:
        log_handled_exception("Login validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except InvalidCredentialsError as exc:
        log_handled_exception("Login credentials rejected", exc)
        return jsonify(success=False, error="invalid email or password"), 401
    except MySQLError as exc:
        log_handled_exception("Login database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    session.clear()
    session["user_id"] = user.id
    session.permanent = True
    return jsonify(success=True, message="Login successful", data=user.to_dict()), 200


@auth.post("/post/logout")
def logout():
    session.clear()
    return jsonify(success=True, message="Logout successful"), 200
