import docker
from docker import DockerClient
from network.models.container import Container

# NOTE: IF you get "too many open files" error, set:
# DefaultLimitNOFILE=100000
# in /etc/systemd/system.conf
# and restart


class ContainerRepo:
    docker: DockerClient

    def __init__(self):
        self.docker = docker.from_env()

    def get_all(self) -> list[Container]:
        docker_client = docker.from_env()
        raw_containers = self.docker.containers.list()  # type:ignore
        docker_client.close()  # this is necessary to avoid a "too many file descriptors" error
        containers: list[Container] = [
            self.__raw_container_to_container(raw_container) for raw_container in raw_containers  # type:ignore
        ]
        return containers

    def __raw_container_to_container(self, raw_container) -> Container:  # type:ignore
        networks = list(raw_container.attrs["NetworkSettings"]["Networks"].keys())  # type:ignore
        ip = raw_container.attrs["NetworkSettings"].get("IPAddress")  # type:ignore

        if len(networks) == 0:  # type:ignore
            host_name = ""
        else:
            docker_compose_host = raw_container.attrs["Config"]["Labels"].get(  # type:ignore
                "com.docker.compose.service"
            )  # type:ignore
            network_aliases = (  # type:ignore
                raw_container.attrs["NetworkSettings"]["Networks"].get(networks[0], {}).get("Aliases")
            )  # type:ignore

            if docker_compose_host:
                host_name = docker_compose_host  # type:ignore
            elif network_aliases and len(network_aliases) > 0:  # type:ignore
                host_name = network_aliases[0]  # type:ignore
            else:
                host_name = ip  # type:ignore

        return Container(
            short_id=raw_container.short_id,  # type:ignore
            name=raw_container.name,  # type:ignore
            status=raw_container.status,  # type:ignore
            ports=raw_container.ports,  # type:ignore
            image=raw_container.attrs["Config"]["Image"],  # type:ignore
            networks=networks,  # type:ignore
            raw_container=raw_container,  # type:ignore
            host_name=host_name,  # type:ignore
            ip=ip,  # type:ignore
            intercepted=False,
        )
