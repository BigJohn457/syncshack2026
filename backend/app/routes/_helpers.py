from typing import Any


def read_varchar_id(http_request: Any, name: str) -> str:
    """Read a VARCHAR(36) identifier from query parameters or a JSON body."""
    raw_value = http_request.args.get(name)
    if raw_value is None:
        body = http_request.get_json(silent=True) or {}
        raw_value = body.get(name)

    if raw_value is None or isinstance(raw_value, bool):
        raise ValueError(f"{name} is required")

    value = str(raw_value).strip()
    if not value:
        raise ValueError(f"{name} is required")
    if len(value) > 36:
        raise ValueError(f"{name} cannot exceed 36 characters")
    return value
