import re
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


# def show():
#     widget.show()
#     qtbot.waitExposed(widget)
#     qtbot.wait(3000)
