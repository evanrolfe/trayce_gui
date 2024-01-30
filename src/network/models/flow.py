from __future__ import annotations
from dataclasses import dataclass
from dataclasses import field

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
    request: bytes
    response: bytes

    @classmethod
    def from_agent_flow(cls, agent_flow: AgentFlow) -> Flow:
        return Flow(
            uuid=agent_flow.uuid,
            local_addr=agent_flow.local_addr,
            remote_addr=agent_flow.remote_addr,
            l4_protocol=agent_flow.l4_protocol,
            l7_protocol=agent_flow.l7_protocol,
            request=agent_flow.request,
            response=agent_flow.response,
        )

    def is_request(self) -> bool:
        return self.request != b""

    def is_response(self) -> bool:
        return self.response != b""

    def add_response(self, flow: Flow):
        self.response = flow.response

    def request_str(self) -> str:
        return self.request.decode()

    def response_str(self) -> str:
        return self.response.decode()
