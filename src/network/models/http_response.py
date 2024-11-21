from __future__ import annotations
from dataclasses import dataclass

from shared.model import Model


@dataclass(kw_only=True)
class HttpResponse(Model):
    http_version: str
    status: int
    status_msg: str
    headers: dict[str, list[str]]
    body: str

    def __str__(self):
        out = f"HTTP/{self.http_version} {self.status} {self.status_msg}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out
