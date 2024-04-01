import grpc
import sys
import traceback
from concurrent import futures
from PySide6 import QtCore
from async_proc import AsyncSignals
from . import api_pb2_grpc
from agent.agent import Agent
from agent.helpers import get_local_ip_addr


class AgentThread(QtCore.QRunnable):
    agent: Agent
    executor: futures.ThreadPoolExecutor
    server: grpc.aio.Server
    signals: AsyncSignals

    def __init__(self):
        super(AgentThread, self).__init__()

        # Store constructor arguments (re-used for processing)
        self.signals = AsyncSignals()
        self.alive = True
        self.agent = Agent()

        port = "50051"

        self.executor = futures.ThreadPoolExecutor(max_workers=10)
        self.server = grpc.server(self.executor)  # type:ignore
        api_pb2_grpc.add_TrayceAgentServicer_to_server(self.agent, self.server)
        self.server.add_insecure_port("[::]:" + port)

    def stop(self):
        print("GRPC server stopping")
        _ = self.server.stop(grace=0)

    def run(self):
        try:
            port = "50051"
            _ = self.server.start()
            print("GRPC server starting, listening on " + get_local_ip_addr() + ":" + port)
            _ = self.server.wait_for_termination()
            self.agent.stop()
            self.executor.shutdown(wait=False, cancel_futures=True)
            print("GRPC server stopped")
        except:  # noqa: E722
            exctype, value = sys.exc_info()[:2]
            self.signals.error.emit((exctype, value, traceback.format_exc()))
