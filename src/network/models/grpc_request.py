from __future__ import annotations
from dataclasses import dataclass
from google.protobuf.descriptor import FileDescriptor

from network.models.flow_request import FlowRequest
from network.utils_grpc import decode_grpc_data, extract_grpc_path_info


@dataclass(kw_only=True)
class GrpcRequest(FlowRequest):
    path: str
    headers: dict[str, list[str]]
    body: bytes

    def __str__(self):
        out = self.header_str()

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body.decode()

        return out

    def header_str(self):
        out = f"GRPC {self.path}\n"
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        return out

    def decode_body(self, file_descriptor: FileDescriptor, path: str) -> str:
        _, service_name, method_name = extract_grpc_path_info(path)

        service = file_descriptor.services_by_name[service_name]
        method = service.methods_by_name[method_name]
        msg_name = method.input_type.name

        return decode_grpc_data(self.body, file_descriptor, msg_name)
