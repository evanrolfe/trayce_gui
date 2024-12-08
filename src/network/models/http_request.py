from __future__ import annotations
import base64
from dataclasses import dataclass
import json

from network.models.flow_request import FlowRequest
from shared.model import Model


@dataclass(kw_only=True)
class HttpRequest(FlowRequest):
    method: str
    host: str
    path: str
    http_version: str
    headers: dict[str, list[str]]
    body: str

    meta = {
        "relationship_keys": [
            "request",
            "response",
        ],
        "json_columns": [],
        "do_not_save_keys": [],
    }

    @classmethod
    def from_json(cls, json_raw: bytes) -> HttpRequest:
        values = json.loads(json_raw)
        return HttpRequest(
            method=values['method'],
            path=values['path'],
            host=values['host'],
            http_version=values['http_version'],
            headers=values['headers'],
            body=values['body'],
        )

    def to_json(self) -> str:
        return json.dumps(self.values_for_db())

    def __str__(self):
        out = f"{self.method} {self.path} HTTP/{self.http_version}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out
