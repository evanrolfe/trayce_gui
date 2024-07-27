import typing
import grpc
import queue
import uuid

from agent.api_pb2 import AgentStarted, Containers, Request, Reply, NooP, Command, Settings, Flows
from event_bus_global import EventBusGlobal
from . import api_pb2_grpc
from datetime import datetime

FlowObservedContext = grpc.aio.ServicerContext[Flows, Reply]
ContainersObservedContext = grpc.aio.ServicerContext[Containers, Reply]
AgentStartedContext = grpc.aio.ServicerContext[AgentStarted, Reply]
CommandStreamContext = grpc.aio.ServicerContext[NooP, Command]


class Agent(api_pb2_grpc.TrayceAgentServicer):
    settings: Settings
    active_stream_queue: queue.Queue[Command]
    old_stream_queues: list[queue.Queue[Command]]
    last_heartbeat: typing.Optional[datetime]
    agent_running: bool

    def __init__(self):
        super().__init__()
        self.settings = Settings(container_ids=[])
        self.old_stream_queues = []
        self.agent_running = False
        self.last_heartbeat = None

        EventBusGlobal.get().intercept_containers.connect(self.set_settings)
        EventBusGlobal.get().agent_connected.connect(self.send_settings)

    def SendFlowsObserved(self, request: Flows, context: FlowObservedContext):
        print("[GRPC] FlowsObserved:", len(request.flows))
        EventBusGlobal.get().flows_received.emit(list(request.flows))

        return Reply(status="success")

    def SendAgentStarted(self, request: Request, context: AgentStartedContext):
        print("[GRPC] AgentStarted")
        return Reply(status="success")

    def SendContainersObserved(self, request: Containers, context: ContainersObservedContext):
        EventBusGlobal.get().containers_observed.emit(request.containers)
        if not self.agent_running:
            EventBusGlobal.get().agent_running.emit(True)

        self.last_heartbeat = datetime.now()
        self.agent_running = True
        return Reply(status="success")

    def OpenCommandStream(
        self, request_iterator: typing.Iterator[NooP], context: CommandStreamContext
    ) -> typing.Iterable[Command]:
        stream_id = uuid.uuid4()
        print("[GRPC] OpenCommandStream: agent connected from:", context.peer(), "ID:", stream_id)
        # Work-around: the Queue class here has weird behaviour, and a new queue gets created everytime a new GRPC stream is opened,
        # so we what we do here is keep track of all the old queues so that we can close them all in the stop() method on program exit.
        # Otherwise the program will keep running even after closing it.
        self.active_stream_queue = queue.Queue()
        self.old_stream_queues.append(self.active_stream_queue)

        # Work-around: if you try and call self.send_settings here it causes weirdness with the queue where it doesn't
        # always receive the settings later on
        EventBusGlobal.get().agent_connected.emit()

        for cmd in iter(self.active_stream_queue.get, None):
            print("[GRPC] sending settings")
            yield cmd

        print("[GRPC] command stream closed ID:", stream_id)

    def set_settings(self, container_ids: list[str]):
        self.settings = Settings(container_ids=container_ids)
        self.send_settings()

    def send_settings(self):
        cmd = Command(type="set_settings", settings=self.settings)
        print("queueing settings:", self.settings.container_ids)
        self.active_stream_queue.put(cmd)

    def stop(self):
        # Close all the queues otherwise the queues will stay running and the program will not fully exit when you close it
        for queue in self.old_stream_queues:
            queue.put(None)  # type:ignore

    # This gets called every 250ms by the heartbeat thread
    def check_heartbeat(self):
        if self.last_heartbeat:
            diff = datetime.now() - self.last_heartbeat
            if diff.total_seconds() >= 1.0 and self.agent_running:
                print("Agent disconnected!")
                self.agent_running = False
                self.last_heartbeat = None
                EventBusGlobal.get().agent_running.emit(False)
