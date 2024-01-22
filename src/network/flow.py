from __future__ import annotations
from dataclasses import dataclass
from dataclasses import field

from typing import Optional

from shared.model import Model
from agent.api_pb2 import Flow as AgentFlow


@dataclass(kw_only=True)
class Flow(Model):
    # Columns
    id: int = field(init=False, default=0)
    created_at: int = field(init=False, default=0)

    local_addr: str
    remote_addr: str
    l4_protocol: str
    l7_protocol: str
    request: bytes
    response: Optional[bytes]

    @classmethod
    def from_agent_flow(cls, agent_flow: AgentFlow) -> Flow:
        return Flow(
            local_addr=agent_flow.local_addr,
            remote_addr=agent_flow.remote_addr,
            l4_protocol=agent_flow.l4_protocol,
            l7_protocol=agent_flow.l7_protocol,
            request=agent_flow.request,
            response=agent_flow.response,
        )
