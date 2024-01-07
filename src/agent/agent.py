from concurrent import futures
import typing
import socket

import grpc
import api_pb2
import api_pb2_grpc

Context = grpc.aio.ServicerContext[typing.Any, typing.Any]


class Agent(api_pb2_grpc.TrayceAgentServicer):
    def SendFlowsObserved(self, request: api_pb2.Request, context: Context):
        print("[GRPC] FlowsObserved:", request)
        return api_pb2.Reply(status="success")

    def SendAgentStarted(self, request: api_pb2.Request, context: Context):
        print("[GRPC] AgentStarted")
        return api_pb2.Reply(status="success")

    def OpenCommandStream(
        self, request_iterator: typing.Iterator[api_pb2.NooP], context: Context
    ) -> typing.Iterable[api_pb2.Command]:
        print("[GRPC] OpenCommandStream")
        try:
            _ = next(request_iterator)
        except StopIteration:
            raise RuntimeError("Failed to receive request")
        print("[GRPC] Sending settings")
        s = api_pb2.Settings(container_ids=["956fba8aa002"])
        response = api_pb2.Command(type="set_settings", settings=s)
        yield response


def get_local_ip_addr() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 1))
    local_ip_addr = s.getsockname()[0]

    return str(local_ip_addr)


def serve():
    ip = get_local_ip_addr()
    port = "50051"

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    api_pb2_grpc.add_TrayceAgentServicer_to_server(Agent(), server)
    server.add_insecure_port("[::]:" + port)
    server.start()
    print("Server started, listening on " + ip + ":" + port)
    server.wait_for_termination()


if __name__ == "__main__":
    serve()
