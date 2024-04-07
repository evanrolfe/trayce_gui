import socket


def get_local_ip_addr() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 1))
    local_ip_addr = s.getsockname()[0]

    return str(local_ip_addr)


def get_docker_cmd() -> str:
    ip = get_local_ip_addr()
    cmd = f"docker run --pid=host --privileged -v /var/run/docker.sock:/var/run/docker.sock -t trayce_agent -grpcaddr {ip}:50051"
    return cmd
