import socket
import grpc
import sys
import traceback
from concurrent import futures
from PyQt6 import QtCore
from async_worker import WorkerSignals
from . import api_pb2_grpc
from agent.agent import Agent


def get_local_ip_addr() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 1))
    local_ip_addr = s.getsockname()[0]

    return str(local_ip_addr)


class AgentThread(QtCore.QRunnable):
    server: grpc.aio.Server
    agent: Agent

    def __init__(self):
        super(AgentThread, self).__init__()

        # Store constructor arguments (re-used for processing)
        self.signals = WorkerSignals()
        self.alive = True
        self.agent = Agent()

    def stop(self):
        print("GRPC server stopping")
        _ = self.server.stop(0.0)
        # TODO: This should close all connections

    def run(self):
        # Retrieve args/kwargs here; and fire processing using them
        try:
            ip = get_local_ip_addr()
            port = "50051"

            self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))  # type:ignore
            api_pb2_grpc.add_TrayceAgentServicer_to_server(self.agent, self.server)
            self.server.add_insecure_port("[::]:" + port)
            self.server.start()
            print("GRPC server starting, listening on " + ip + ":" + port)
            self.server.wait_for_termination()

        except:  # noqa: E722
            exctype, value = sys.exc_info()[:2]
            self.signals.error.emit((exctype, value, traceback.format_exc()))
