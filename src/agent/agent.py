import typing
import grpc
import queue
from agent.api_pb2 import AgentStarted, Request, Reply, NooP, Command, Settings, Flows
from . import api_pb2_grpc

FlowObservedContext = grpc.aio.ServicerContext[Flows, Reply]
AgentStartedContext = grpc.aio.ServicerContext[AgentStarted, Reply]
CommandStreamContext = grpc.aio.ServicerContext[NooP, Command]


class Agent(api_pb2_grpc.TrayceAgentServicer):
    stream_queue: queue.SimpleQueue[Command]

    def __init__(self):
        super().__init__()
        self.stream_queue = queue.SimpleQueue()

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

        for cmd in iter(self.stream_queue.get, None):
            print("[GRPC] sending settings")
            yield cmd

    def send_settings(self, settings: Settings):
        cmd = Command(type="set_settings", settings=settings)
        print("queueing settings")
        self.stream_queue.put(cmd)
