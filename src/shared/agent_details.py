from packaging.version import Version

MIN_AGENT_VERSION_REQUIRED = '0.2.0'

class AgentDetails:
    running: bool
    version: str

    def __init__(self, running: bool, version: str):
        self.running = running
        self.version = version

    def version_ok(self) -> bool:
        if self.version == '':
            return False

        required_version = Version(MIN_AGENT_VERSION_REQUIRED)
        agent_version = Version(self.version)

        return agent_version >= required_version
