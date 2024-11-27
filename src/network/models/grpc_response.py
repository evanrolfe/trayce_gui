from __future__ import annotations
from dataclasses import dataclass
from google.protobuf.descriptor import FileDescriptor

from network.models.flow_response import FlowResponse
from network.utils_grpc import decode_grpc_data, extract_grpc_path_info


@dataclass(kw_only=True)
class GrpcResponse(FlowResponse):
    headers: dict[str, list[str]]
    body: bytes

    def __str__(self):
        out = ""
        for key, value in self.headers.items():
            v = ",".join(value)
            out += f"{key}: {v}\n"

        out += "\r\n"
        if len(self.body) > 0:
            out += self.body.decode()

        return out

    def decode_body(self, file_descriptor: FileDescriptor, path: str) -> str:
        _, service_name, method_name = extract_grpc_path_info(path)

        service = file_descriptor.services_by_name[service_name]
        method = service.methods_by_name[method_name]
        msg_name = method.output_type.name

        return decode_grpc_data(self.body, file_descriptor, msg_name)

