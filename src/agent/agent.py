import typing
import grpc
import queue
from agent.api_pb2 import AgentStarted, Request, Reply, NooP, Command, Settings, Flows
from event_bus_global import EventBusGlobal

from . import api_pb2_grpc

FlowObservedContext = grpc.aio.ServicerContext[Flows, Reply]
AgentStartedContext = grpc.aio.ServicerContext[AgentStarted, Reply]
CommandStreamContext = grpc.aio.ServicerContext[NooP, Command]


class Agent(api_pb2_grpc.TrayceAgentServicer):
    stream_queue: queue.SimpleQueue[Command]
    settings: Settings

    def __init__(self):
        super().__init__()
        self.stream_queue = queue.SimpleQueue()
        self.settings = Settings(container_ids=[])

        EventBusGlobal.get().intercept_containers.connect(self.set_settings)

    def SendFlowsObserved(self, request: Flows, context: FlowObservedContext):
        print("[GRPC] FlowsObserved:", len(request.flows))
        EventBusGlobal.get().flows_received.emit(list(request.flows))

        return Reply(status="success")

    def SendAgentStarted(self, request: Request, context: AgentStartedContext):
        print("[GRPC] AgentStarted")
        return Reply(status="success")

    def OpenCommandStream(
        self, request_iterator: typing.Iterator[NooP], context: CommandStreamContext
    ) -> typing.Iterable[Command]:
        print("[GRPC] OpenCommandStream")
        self.send_settings()

        for cmd in iter(self.stream_queue.get, None):
            print("[GRPC] sending settings")
            yield cmd

    def set_settings(self, container_ids: list[str]):
        self.settings = Settings(container_ids=container_ids)
        self.send_settings()

    def send_settings(self):
        cmd = Command(type="set_settings", settings=self.settings)
        print("queueing settings:", self.settings.container_ids)
        self.stream_queue.put(cmd)

    def stop(self):
        # Otherwise the loop will stay running and the program will not fully exit when you close it
        self.stream_queue.put(None)  # type:ignore
