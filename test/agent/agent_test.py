import pathlib
from typing import Optional
from PySide6 import QtCore

from pytestqt.qtbot import QtBot
from agent import api_pb2
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from helpers import generate_http_response, send_flow_over_grpc, generate_http_request
from factories.agent_flow_factory import AgentFlowFactory
from network.repos.proto_def_repo import ProtoDefRepo

def describe_agent():
    def receiving_an_http_flow_request(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        flow1 = AgentFlowFactory.build_request(
            api_pb2.HTTPRequest(
                method="GET",
                path="/",
                host="172.17.0.3:3001",
                http_version="1.1",
                headers={},
                payload=bytes(),
            ),
            uuid="abcd-1234",
        )

        signal = EventBusGlobal.get().flows_received
        with qtbot.waitSignal(signal, timeout=1000) as blocker:
            send_flow_over_grpc(flow1)

        assert blocker.args is not None
        flows = blocker.args[0]

        assert len(flows) == 1
        assert flows[0].uuid == "abcd-1234"
        assert flows[0].source_addr == "192.168.0.1"
        assert flows[0].dest_addr == "192.168.0.2"
        assert flows[0].l4_protocol == "tcp"
        assert flows[0].l7_protocol == "http"

        assert flows[0].http_request.method == "GET"
        assert flows[0].http_request.path == "/"
        assert flows[0].http_request.host == "172.17.0.3:3001"
        assert flows[0].http_request.http_version == "1.1"

        main_window.about_to_quit()

    def receiving_an_http_flow_response(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        payload = '{"hello":"world","how":"areyou","ok":123,"enabled": false}'.encode()
        flow1 = AgentFlowFactory.build_response(
            api_pb2.HTTPResponse(
                status=200,
                status_msg="OK",
                http_version="1.1",
                headers={},
                payload=payload,
            ),
            uuid="abcd-1234",
        )

        signal = EventBusGlobal.get().flows_received
        with qtbot.waitSignal(signal, timeout=1000) as blocker:
            send_flow_over_grpc(flow1)

        assert blocker.args is not None
        flows = blocker.args[0]

        assert len(flows) == 1
        assert flows[0].uuid == "abcd-1234"
        assert flows[0].source_addr == "192.168.0.1"
        assert flows[0].dest_addr == "192.168.0.2"
        assert flows[0].l4_protocol == "tcp"
        assert flows[0].l7_protocol == "http"

        assert flows[0].http_response.status == 200
        assert flows[0].http_response.status_msg == "OK"
        assert flows[0].http_response.http_version == "1.1"
        assert flows[0].http_response.payload == payload

        main_window.about_to_quit()

    def receiving_a_grpc_flow_request(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        headers: dict[str, api_pb2.StringList] = {}
        payload = bytes([0x0a,0x29,0x0a,0x04,0x31,0x32,0x33,0x34,0x12,0x06,0x75,0x62,0x75,0x6e,0x74,0x75,0x1a,0x0a,0x31,0x37,0x32,0x2e,0x30,0x2e,0x31,0x2e,0x31,0x39,0x22,0x04,0x65,0x76,0x61,0x6e,0x2a,0x07,0x72,0x75,0x6e,0x6e,0x69,0x6e,0x67])
        flow1 = AgentFlowFactory.build_grpc_request(
            api_pb2.GRPCRequest(
                path="/api.TrayceAgent/SendContainersObserved",
                headers=headers,
                payload=payload,
            ),
            uuid="abcd-1234",
        )

        signal = EventBusGlobal.get().flows_received
        with qtbot.waitSignal(signal, timeout=1000) as blocker:
            send_flow_over_grpc(flow1)

        assert blocker.args is not None
        flows = blocker.args[0]

        assert len(flows) == 1
        assert flows[0].uuid == "abcd-1234"
        assert flows[0].source_addr == "192.168.0.1"
        assert flows[0].dest_addr == "192.168.0.2:50051"
        assert flows[0].l4_protocol == "tcp"
        assert flows[0].l7_protocol == "grpc"

        assert flows[0].grpc_request.path == "/api.TrayceAgent/SendContainersObserved"
        assert flows[0].grpc_request.payload == payload

        main_window.about_to_quit()

    def receiving_a_grpc_flow_response(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        headers: dict[str, api_pb2.StringList] = {}
        payload = bytes([0x0a, 0x08, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x20])
        flow = AgentFlowFactory.build_grpc_response(
            api_pb2.GRPCResponse(
                headers=headers,
                payload=payload,
            ),
            uuid="abcd-1234",
        )
        signal = EventBusGlobal.get().flows_received
        with qtbot.waitSignal(signal, timeout=1000) as blocker:
            send_flow_over_grpc(flow)

        assert blocker.args is not None
        flows = blocker.args[0]

        assert len(flows) == 1
        assert flows[0].uuid == "abcd-1234"
        assert flows[0].source_addr == "192.168.0.1"
        assert flows[0].dest_addr == "192.168.0.2"
        assert flows[0].l4_protocol == "tcp"
        assert flows[0].l7_protocol == "grpc"

        assert flows[0].grpc_response.payload == payload

        main_window.about_to_quit()
