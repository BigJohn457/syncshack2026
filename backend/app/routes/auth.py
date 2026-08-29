from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError, IntegrityError

from app.models import LoginData, SignUpData
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
        return jsonify(success=False, error=str(exc)), 400
    except EmailAlreadyExistsError:
        return jsonify(success=False, error="email is already registered"), 409
    except IntegrityError as exc:
        if exc.errno == 1062:
            return jsonify(success=False, error="email is already registered"), 409
        return jsonify(success=False, error="database operation failed"), 500
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=user.to_dict()), 201


@auth.post("/post/login")
def login():
    try:
        login_data = LoginData.from_dict(request.get_json(silent=True))
        user = auth_repository.authenticate(login_data)
    except ValueError as exc:
        return jsonify(success=False, error=str(exc)), 400
    except InvalidCredentialsError:
        return jsonify(success=False, error="invalid email or password"), 401
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    session.clear()
    session["user_id"] = user.id
    session.permanent = True
    return jsonify(success=True, message="Login successful", data=user.to_dict()), 200


@auth.post("/post/logout")
def logout():
    session.clear()
    return jsonify(success=True, message="Logout successful"), 200
