from flask import current_app
from mysql.connector import MySQLConnection, connect


def get_db_connection() -> MySQLConnection:
    """Create a verified SSL connection using the active Flask config."""
    return connect(
        host=current_app.config["DB_HOST"],
        port=current_app.config["DB_PORT"],
        user=current_app.config["DB_USER"],
        password=current_app.config["DB_PASSWORD"],
        database=current_app.config["DB_NAME"],
        ssl_ca=current_app.config["DB_SSL_CA"],
        ssl_verify_cert=True,
    )
