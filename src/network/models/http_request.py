from __future__ import annotations
from dataclasses import dataclass

from shared.model import Model


@dataclass(kw_only=True)
class HttpRequest(Model):
    method: str
    host: str
    path: str
    http_version: str
    headers: dict[str, str]
    body: str

    @classmethod
    def from_raw(cls, raw_request: bytes) -> HttpRequest:
        request_str = raw_request.decode("utf-8")

        lines = request_str.split("\r\n")
        request_line = lines[0].split(" ")
        method, path, http_version = request_line[0], request_line[1], request_line[2]

        headers: dict[str, str] = {}
        for line in lines[1:]:
            if line == "":  # Empty line denotes end of headers
                break
            key, value = line.split(": ", 1)  # Split each header line into key and value
            headers[key] = value

        body = request_str.split("\r\n\r\n", 1)[-1]

        host = ""
        if headers.get("Host"):
            host = headers["Host"]
        elif headers.get("host"):
            host = headers["host"]

        return HttpRequest(method=method, host=host, path=path, http_version=http_version, headers=headers, body=body)
