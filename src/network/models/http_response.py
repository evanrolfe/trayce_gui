from __future__ import annotations
import base64
from dataclasses import dataclass
import json

from network.models.flow_response import FlowResponse


@dataclass(kw_only=True)
class HttpResponse(FlowResponse):
    http_version: str
    status: int
    status_msg: str
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
    def from_json(cls, json_raw: bytes) -> HttpResponse:
        values = json.loads(json_raw)
        return HttpResponse(
            http_version=values['http_version'],
            status=values['status'],
            status_msg=values['status_msg'],
            headers=values['headers'],
            body=values['body'],
        )

    def to_json(self) -> str:
        return json.dumps(self.values_for_db())

    def __str__(self):
        out = f"HTTP/{self.http_version} {self.status} {self.status_msg}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out
