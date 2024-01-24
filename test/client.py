import grpc
from agent import api_pb2_grpc
from agent import api_pb2


def send_flow():
    # Set up a channel and a stub
    channel = grpc.insecure_channel("localhost:50051")  # Adjust the address and port accordingly
    stub = api_pb2_grpc.TrayceAgentStub(channel)

    flow = api_pb2.Flow(
        uuid="1234",
        local_addr="192.168.0.1",
        remote_addr="192.168.0.2",
        l4_protocol="tcp",
        l7_protocol="http",
        request=b"GET",
        response=b"",
    )
    flow_message = api_pb2.Flows(flows=[flow])  # Replace with actual fields

    # Send the message using the stub
    stub.SendFlowsObserved(flow_message)
