from dataclasses import asdict, dataclass
from typing import Any


@dataclass(frozen=True)
class SystemMessage:
    """Message returned by a system endpoint."""

    message: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class SystemStatus:
    """Health information for the running API."""

    status: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
