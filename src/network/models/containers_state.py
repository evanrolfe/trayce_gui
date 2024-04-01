from dataclasses import dataclass

from network.models.container import Container


# ContainersState contains the containers currently running on this machine and some extra info about them
@dataclass(kw_only=True)
class ContainersState:
    containers: list[Container]

    def is_trayce_agent_running(self) -> bool:
        return any(c.is_trayce_agent() for c in self.containers)
