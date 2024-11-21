from __future__ import annotations
from dataclasses import dataclass

from shared.model import Model


@dataclass(kw_only=True)
class HttpRequest(Model):
    method: str
    host: str
    path: str
    http_version: str
    headers: dict[str, list[str]]
    body: str

    def __str__(self):
        out = f"{self.method} {self.path} HTTP/{self.http_version}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out
