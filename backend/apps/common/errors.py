"""Domain errors. Every one becomes the same JSON shape: {"code", "message"}."""


class DomainError(Exception):
    status_code = 400
    code = "error"

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class NotFound(DomainError):
    status_code = 404
    code = "not_found"


class Forbidden(DomainError):
    status_code = 403
    code = "forbidden"


class Conflict(DomainError):
    status_code = 409
    code = "conflict"
