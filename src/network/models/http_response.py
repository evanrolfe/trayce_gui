from __future__ import annotations
from dataclasses import dataclass

from shared.model import Model


@dataclass(kw_only=True)
class HttpResponse(Model):
    http_version: str
    status: int
    status_msg: str
    headers: dict[str, str]
    body: str

    @classmethod
    def from_raw(cls, raw_response: bytes) -> HttpResponse:
        response_str = raw_response.decode("utf-8")

        header_part, body = response_str.split("\r\n\r\n", 1)
        lines = header_part.split("\r\n")
        status_line = lines[0].split(" ")
        http_version, status, status_msg = status_line[0], int(status_line[1]), " ".join(status_line[2:])

        # Initialize headers dictionary
        headers: dict[str, str] = {}
        # Iterate over the remaining lines to fill the headers dictionary
        for line in lines[1:]:
            key, value = line.split(": ", 1)  # Split each header line into key and value
            headers[key] = value

        return HttpResponse(http_version=http_version, status=status, status_msg=status_msg, headers=headers, body=body)
