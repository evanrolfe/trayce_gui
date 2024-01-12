import typing
import grpc
from agent.api_pb2 import AgentStarted, Request, Reply, NooP, Command, Settings, Flows
from . import api_pb2_grpc

FlowObservedContext = grpc.aio.ServicerContext[Flows, Reply]
AgentStartedContext = grpc.aio.ServicerContext[AgentStarted, Reply]
CommandStreamContext = grpc.aio.ServicerContext[NooP, Command]


class Agent(api_pb2_grpc.TrayceAgentServicer):
    streams: list[CommandStreamContext]

    def __init__(self):
        super().__init__()
        self.streams = []

    def SendFlowsObserved(self, request: Request, context: FlowObservedContext):
        print("[GRPC] FlowsObserved:", request)
        return Reply(status="success")

    def SendAgentStarted(self, request: Request, context: AgentStartedContext):
        print("[GRPC] AgentStarted")
        return Reply(status="success")

    def OpenCommandStream(
        self, request_iterator: typing.Iterator[NooP], context: CommandStreamContext
    ) -> typing.Iterable[Command]:
        print("[GRPC] OpenCommandStream")
        try:
            _ = next(request_iterator)
        except StopIteration:
            raise RuntimeError("Failed to receive request")

        self.streams.append(context)
        s = Settings(container_ids=["de86adec6389"])
        response = Command(type="set_settings", settings=s)

        yield response

    async def send_settings(self):
        for stream in self.streams:
            s = Settings(container_ids=["de86adec6389"])
            cmd = Command(type="set_settings", settings=s)

            await stream.write(message=cmd)
