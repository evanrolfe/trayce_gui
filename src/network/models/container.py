from dataclasses import dataclass


@dataclass(kw_only=True)
class Container:
    short_id: str
    name: str
    status: str
    ports: dict[str, list[dict[str, str]]]
    image: str
    networks: list[str]
    raw_container: object
    host_name: str
    ip: str
    intercepted: bool

    def is_trayce_agent(self) -> bool:
        return "traycer/trayce_agent" in self.image
