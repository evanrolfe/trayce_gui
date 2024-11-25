from __future__ import annotations
from dataclasses import dataclass
from google.protobuf.descriptor_pool import DescriptorPool
from google.protobuf.descriptor import FileDescriptor

from network.models.flow_response import FlowResponse


@dataclass(kw_only=True)
class GrpcResponse(FlowResponse):
    headers: dict[str, list[str]]
    body: str

    def __str__(self):
        out = ""
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body

        return out

    def decode_body(self, file_descriptor: FileDescriptor, message_name: str) -> str:
        return ""
