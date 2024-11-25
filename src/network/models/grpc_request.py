from __future__ import annotations
from dataclasses import dataclass

from network.models.flow_request import FlowRequest


@dataclass(kw_only=True)
class GrpcRequest(FlowRequest):
    path: str
    headers: dict[str, list[str]]
    body: str

    def __str__(self):
        out = f"GRPC {self.path}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out
