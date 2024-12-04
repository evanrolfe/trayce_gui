import re
import typing
import grpc
from agent import api_pb2_grpc
from agent import api_pb2


def send_flow_over_grpc(flow: api_pb2.Flow):
    # Set up a channel and a stub
    channel = grpc.insecure_channel("localhost:50051")  # Adjust the address and port accordingly
    stub = api_pb2_grpc.TrayceAgentStub(channel)

    flow_message = api_pb2.Flows(flows=[flow])  # Replace with actual fields

    # Send the message using the stub
    stub.SendFlowsObserved(flow_message)


def send_containers_over_grpc(containers: list[api_pb2.Container]):
    # Set up a channel and a stub
    channel = grpc.insecure_channel("localhost:50051")  # Adjust the address and port accordingly
    stub = api_pb2_grpc.TrayceAgentStub(channel)

    containers_message = api_pb2.Containers(containers=containers)  # Replace with actual fields

    # Send the message using the stub
    stub.SendContainersObserved(containers_message)


def hex_dump_to_bytes(hex_dump: str) -> bytes:
    lines = hex_dump.split("\n")
    hex_string = ""

    for line in lines:
        # Find the hex portion of each line and concatenate it
        if "|" in line:
            hex_part = line.split("|")[0].strip()
            print(hex_part)
            hex_string += hex_part[10:]

    # Remove all non-hexadecimal characters
    hex_string = re.sub(r"[^0-9A-Fa-f]", "", hex_string)

    # Convert the hexadecimal string to bytes
    decoded = bytes.fromhex(hex_string)

    return decoded


def generate_http_request(**kwargs: typing.Any) -> bytes:
    method = kwargs.get("method", "POST")
    host = kwargs.get("host", "example.com")
    path = kwargs.get("path", "/")
    http_version = kwargs.get("http_version", "HTTP/1.1")
    headers = kwargs.get("headers", {"Host": host, "Connection": "close", "User-Agent": "qtraycetest"})
    body = kwargs.get("body", "HELLO WORLD")

    request_line = f"{method} {path} {http_version}\r\n"
    header_lines = "\r\n".join(f"{key}: {value}" for key, value in headers.items())
    http_request = f"{request_line}{header_lines}\r\n\r\n{body}"

    return http_request.encode("utf-8")


def generate_http_response(**kwargs: typing.Any) -> bytes:
    status = kwargs.get("status", 200)
    status_msg = kwargs.get("status_msg", "OK")
    headers = kwargs.get("headers", {"Content-Type": "application/json"})
    body = kwargs.get("body", '{"hello":"world"}')

    http_version = kwargs.get("http_version", "HTTP/1.1")

    response = f"{http_version} {status} {status_msg}\r\n"
    for header_name, header_value in headers.items():
        response += f"{header_name}: {header_value}\r\n"

    response += "\r\n"
    response += body

    return response.encode("utf-8")


# def show():
#     widget.show()
#     qtbot.waitExposed(widget)
#     qtbot.wait(3000)
