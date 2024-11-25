from __future__ import annotations
from dataclasses import dataclass
from dataclasses import field
from typing import Optional

from network.models.flow_request import FlowRequest
from network.models.flow_response import FlowResponse
from network.models.grpc_request import GrpcRequest
from network.models.grpc_response import GrpcResponse
from network.models.http_request import HttpRequest
from network.models.http_response import HttpResponse
from shared.helpers import format_json
from shared.model import Model
from agent.api_pb2 import Flow as AgentFlow


@dataclass(kw_only=True)
class Flow(Model):
    # Columns
    id: int = field(init=False, default=0)
    created_at: int = field(init=False, default=0)

    uuid: str
    source_addr: str
    dest_addr: str
    l4_protocol: str
    l7_protocol: str
    request_raw: bytes
    response_raw: bytes
    request: Optional[FlowRequest]
    response: Optional[FlowResponse]

    meta = {
        "relationship_keys": [
            "request",
            "response",
        ],
        "json_columns": [],
        "do_not_save_keys": [],
    }

    @classmethod
    def from_agent_flow(cls, agent_flow: AgentFlow) -> Flow:
        flow = Flow(
            uuid=agent_flow.uuid,
            source_addr=agent_flow.source_addr,
            dest_addr=agent_flow.dest_addr,
            l4_protocol=agent_flow.l4_protocol,
            l7_protocol=agent_flow.l7_protocol,
            request_raw=bytes(),
            response_raw=bytes(),
            request=None,
            response=None,
        )

        # HTTP Request
        if len(agent_flow.http_request.method) > 0:
            req = agent_flow.http_request

            # Convert headers
            headers: dict[str, list[str]] = {}
            for key, values in req.headers.items():
                headers[key] = [str(value) for value in values.values]

            # Convert body
            body = ""
            if len(req.payload) > 0:
                body = req.payload.decode('utf-8')

            flow.request = HttpRequest(
                method=req.method,
                path=req.path,
                host=req.host,
                http_version=req.http_version,
                headers=headers,
                body=body,
            )

        # GRPC Request
        if len(agent_flow.grpc_request.path) > 0:
            req = agent_flow.grpc_request

            # Convert headers
            headers: dict[str, list[str]] = {}
            for key, values in req.headers.items():
                headers[key] = [str(value) for value in values.values]

            # Convert body
            body = ""
            if len(req.payload) > 0:
                body = req.payload.decode('utf-8')

            flow.request = GrpcRequest(
                path=req.path,
                headers=headers,
                body=body,
            )

        # HTTP Response
        if agent_flow.http_response.status > 0:
            resp = agent_flow.http_response

            # Convert headers
            headers: dict[str, list[str]] = {}
            for key, values in resp.headers.items():
                headers[key] = [str(value) for value in values.values]

            # Convert body
            body = ""
            if len(resp.payload) > 0:
                body = resp.payload.decode('utf-8')

            flow.response = HttpResponse(
                status=resp.status,
                status_msg=resp.status_msg,
                http_version=resp.http_version,
                headers=headers,
                body=body,
            )

        # GRPC Response
        if len(agent_flow.grpc_response.payload) > 0:
            req = agent_flow.grpc_response

            # Convert headers
            headers: dict[str, list[str]] = {}
            for key, values in req.headers.items():
                headers[key] = [str(value) for value in values.values]

            # Convert body
            body = ""
            if len(req.payload) > 0:
                body = req.payload.decode('utf-8')

            flow.response = GrpcResponse(
                headers=headers,
                body=body,
            )

        return flow

    def is_request(self) -> bool:
        return self.request is not None

    def is_response(self) -> bool:
        return self.response is not None

    def add_response(self, flow: Flow):
        self.response = flow.response

    def request_body_str(self) -> str:
        if not self.request:
            return ""

        if isinstance(self.request, HttpRequest):
            return self.request.body

        if isinstance(self.request, GrpcRequest):
            return self.request.body

        return ""

    def response_body_str(self) -> str:
        if not self.response:
            return ""

        if isinstance(self.response, HttpResponse):
            return self.response.body

        if isinstance(self.response, GrpcResponse):

            return self.response.decode_body(file_descriptor, "")

        return ""

    def request_body_formatted(self) -> str:
        if not self.request:
            return ""

        content_type = ""
        if isinstance(self.request, HttpRequest):
            content_type = self.request.headers.get("content-type", "")

        if isinstance(self.request, GrpcRequest):
            content_type = self.request.headers.get("content-type", "")

        body = self.request_body_str()

        if "json" in content_type:
            return format_json(body)
        elif "html" in content_type:
            return body
        else:
            return body

    def response_body_formatted(self) -> str:
        if not self.response:
            return ""

        content_type = ""
        if isinstance(self.response, HttpResponse):
            content_type = self.response.headers.get("content-type", "")

        if isinstance(self.response, GrpcResponse):
            content_type = self.response.headers.get("content-type", "")

        body = self.response_body_str()

        if "json" in content_type:
            return format_json(body)
        elif "html" in content_type:
            return body
        else:
            return body

    def destination(self) -> str:
        if self.request is None:
            return ""

        if isinstance(self.request, HttpRequest):
            return self.request.host

        if isinstance(self.request, GrpcRequest):
            return self.dest_addr

        return ""

    def operation(self) -> str:
        if isinstance(self.request, HttpRequest):
            return self.request.method

        if isinstance(self.request, GrpcRequest):
            return ""

        return ""

    def path(self) -> str:
        if isinstance(self.request, HttpRequest):
            return self.request.path

        if isinstance(self.request, GrpcRequest):
            return self.request.path

        return ""

    def response_status(self) -> str:
        if self.response is None:
            return ""

        if isinstance(self.response, HttpResponse):
            return str(self.response.status)

        return ""
