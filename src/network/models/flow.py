from __future__ import annotations
from dataclasses import dataclass
from dataclasses import field
from typing import Optional

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
    local_addr: str
    remote_addr: str
    l4_protocol: str
    l7_protocol: str
    request_raw: bytes
    response_raw: bytes
    request: Optional[HttpRequest]
    response: Optional[HttpResponse]

    @classmethod
    def from_agent_flow(cls, agent_flow: AgentFlow) -> Flow:
        flow = Flow(
            uuid=agent_flow.uuid,
            local_addr=agent_flow.local_addr,
            remote_addr=agent_flow.remote_addr,
            l4_protocol=agent_flow.l4_protocol,
            l7_protocol=agent_flow.l7_protocol,
            request_raw=agent_flow.request,
            response_raw=agent_flow.response,
            request=None,
            response=None,
        )
        flow.build_request()
        flow.build_response()

        return flow

    def build_request(self):
        if len(self.request_raw) > 0:
            self.request = HttpRequest.from_raw(self.request_raw)

    def build_response(self):
        if len(self.response_raw) > 0:
            self.response = HttpResponse.from_raw(self.response_raw)

    def is_request(self) -> bool:
        return self.request_raw != b""

    def is_response(self) -> bool:
        return self.response_raw != b""

    def add_response(self, flow: Flow):
        self.response_raw = flow.response_raw
        self.build_response()

    def request_str(self) -> str:
        return self.request_raw.decode()

    def response_str(self) -> str:
        return self.response_raw.decode()

    def request_body_str(self) -> str:
        if not self.request:
            return ""
        return self.request.body

    def response_body_str(self) -> str:
        if not self.response:
            return ""
        return self.response.body

    def request_body_formatted(self) -> str:
        if not self.request:
            return ""

        body = self.request_body_str()
        content_type = self.request.headers.get("content-type", "")

        if "json" in content_type:
            return format_json(body)
        elif "html" in content_type:
            return body
        else:
            return body

    def response_body_formatted(self) -> str:
        if not self.response:
            return ""

        body = self.response_body_str()
        content_type = self.response.headers.get("content-type", "")

        if "json" in content_type:
            return format_json(body)
        elif "html" in content_type:
            return body
        else:
            return body
