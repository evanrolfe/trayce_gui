from ast import main
import pathlib
import time
import uuid
from typing import Optional
from PySide6 import QtCore

from pytestqt.qtbot import QtBot
from agent import api_pb2
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from support.factories.agent_flow_factory import AgentFlowFactory
from network.repos.proto_def_repo import ProtoDefRepo

def describe_network_page():
    def receiving_a_single_request_flow(database, cleanup_database, main_window: MainWindow, qtbot: QtBot):  # type: ignore
        # Setup
        flow1 = AgentFlowFactory.build_request(
            api_pb2.HTTPRequest(
                method="GET",
                path="/",
                host="172.17.0.3:3001",
                http_version="1.1",
                headers={},
                payload=bytes(),
            ),
            uuid=str(uuid.uuid4()),
        )

        EventBusGlobal.get().flows_received.emit([flow1])
        qtbot.wait(200)

        # Subject

        # Assert
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        assert table_model.rowCount() == 1
        # assert table_model.data(table_model.index(0, 0)) == "1111"
        assert table_model.data(table_model.index(0, 1)) == "http"
        assert table_model.data(table_model.index(0, 2)) == "172.17.0.3:3001"
        # assert table_model.data(table_model.index(0, 3)) == "GET"
        assert table_model.data(table_model.index(0, 4)) == "/"
        # assert table_model.data(table_model.index(0, 5)) == "200"

    def it_displays_an_http_flow_received(database, cleanup_database, main_window: MainWindow, qtbot: QtBot):  # type: ignore
        # Setup
        n = 3
        # TODO: Improve these factories also generate the uuid properly
        for i in range(n):
            flow1 = AgentFlowFactory.build_request(
                api_pb2.HTTPRequest(
                    method="GET",
                    path="/",
                    host="172.17.0.3:3001",
                    http_version="1.1",
                    headers={},
                    payload=bytes(),
                ),
                uuid=str(uuid.uuid4()),
            )
            flow2 = AgentFlowFactory.build_response(
                api_pb2.HTTPResponse(
                    status=200,
                    status_msg="OK",
                    http_version="1.1",
                    headers={},
                    payload='{"hello":"world","how":"areyou","ok":123,"enabled": false}'.encode(),
                ),
                uuid=flow1.uuid,
            )

            EventBusGlobal.get().flows_received.emit([flow1, flow2])
            qtbot.wait(200)

        # Subject

        # Assert
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        assert table_model.rowCount() == n
        # assert table_model.data(table_model.index(0, 0)) == "1111"
        assert table_model.data(table_model.index(0, 1)) == "http"
        assert table_model.data(table_model.index(0, 2)) == "172.17.0.3:3001"
        # assert table_model.data(table_model.index(0, 3)) == "GET"
        assert table_model.data(table_model.index(0, 4)) == "/"
        # assert table_model.data(table_model.index(0, 5)) == "200"

    def it_displays_a_grpc_flow_received(database, cleanup_database, main_window: MainWindow, qtbot: QtBot):  # type: ignore
        n = 3

        # TODO: Improve these factories also generate the uuid properly
        for i in range(n):
            headers: dict[str, api_pb2.StringList] = {}
            flow1 = AgentFlowFactory.build_grpc_request(
                api_pb2.GRPCRequest(
                    path="/trayce.api/SendFlows",
                    headers=headers,
                    payload=bytes(),
                ),
                uuid=str(uuid.uuid4()),
            )

            flow2 = AgentFlowFactory.build_grpc_response(
                api_pb2.GRPCResponse(
                    headers=headers,
                    payload=bytes([0x00, 0x00, 0x00, 0x00, 0x0a, 0x0a, 0x08, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x20]),
                ),
                uuid=flow1.uuid,
            )

            EventBusGlobal.get().flows_received.emit([flow1, flow2])
            qtbot.wait(200)

        # Subject

        # Assert
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        assert table_model.rowCount() == n
        # assert table_model.data(table_model.index(0, 0)) == "1111"
        assert table_model.data(table_model.index(0, 1)) == "grpc"
        assert table_model.data(table_model.index(0, 2)) == "192.168.0.2:50051"
        # assert table_model.data(table_model.index(0, 3)) == "GET"
        assert table_model.data(table_model.index(0, 4)) == "/trayce.api/SendFlows"
        # assert table_model.data(table_model.index(0, 5)) == "200"

        main_window.about_to_quit()

    def it_lets_you_select_an_http_flow(database, cleanup_database, main_window: MainWindow, qtbot: QtBot):
        # Setup
        flow1 = AgentFlowFactory.build_request(
            api_pb2.HTTPRequest(
                method="POST",
                path="/",
                host="172.17.0.3:3001",
                http_version="1.1",
                headers={},
                payload='{"hello":"world","how":"areyou","ok":123}'.encode(),
            )
        )
        EventBusGlobal.get().flows_received.emit([flow1])

        flow2 = AgentFlowFactory.build_response(
            api_pb2.HTTPResponse(
                status=200,
                status_msg="OK",
                http_version="1.1",
                headers={},
                payload='{"hello":"world","how":"areyou","ok":123,"enabled": false}'.encode(),
            ),
            uuid=flow1.uuid
        )
        EventBusGlobal.get().flows_received.emit([flow2])
        qtbot.wait(200) # have to wait for the flows to be async loaded

        # Subject
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        table = main_window.network_page.ui.flowTableContainer.ui.flowsTable
        rect = table.visualRect(table_model.index(1, 0))
        qtbot.mouseClick(table.viewport(), QtCore.Qt.MouseButton.LeftButton, pos=rect.center())

        # Assert
        request_text = main_window.network_page.ui.requestText.toPlainText()
        request_body_text = main_window.network_page.ui.requestBodyText.toPlainText()
        response_text = main_window.network_page.ui.responseText.toPlainText()
        response_body_text = main_window.network_page.ui.responseBodyText.toPlainText()

        assert "POST / HTTP/1.1" in request_text
        assert "hello" in request_body_text

        assert "HTTP/1.1 200 OK" in response_text
        assert "123" in response_body_text

    def it_lets_you_select_a_grpc_flow(database, cleanup_database, main_window: MainWindow, qtbot: QtBot):
        # Setup
        proto_def = ProtoDefRepo().upload("api.TrayceAgent", "src/agent/api.proto")
        main_window.network_page.load_proto_defs()

        # Selecte the .proto file
        assert main_window.network_page.proto_file_dropdown.count() == 3
        main_window.network_page.proto_file_dropdown.setCurrentIndex(1)

        # Create flows
        headers: dict[str, api_pb2.StringList] = {}
        flow1 = AgentFlowFactory.build_grpc_request(
            api_pb2.GRPCRequest(
                path="/api.TrayceAgent/SendContainersObserved",
                headers=headers,
                payload=bytes([0x0a,0x29,0x0a,0x04,0x31,0x32,0x33,0x34,0x12,0x06,0x75,0x62,0x75,0x6e,0x74,0x75,0x1a,0x0a,0x31,0x37,0x32,0x2e,0x30,0x2e,0x31,0x2e,0x31,0x39,0x22,0x04,0x65,0x76,0x61,0x6e,0x2a,0x07,0x72,0x75,0x6e,0x6e,0x69,0x6e,0x67]),
            ),
            uuid=str(uuid.uuid4()),
        )

        flow2 = AgentFlowFactory.build_grpc_response(
            api_pb2.GRPCResponse(
                headers=headers,
                payload=bytes([0x0a, 0x08, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x20]),
            ),
            uuid=flow1.uuid,
        )
        EventBusGlobal.get().flows_received.emit([flow1, flow2])
        qtbot.wait(200) # have to wait for the flows to be async loaded

        # Subject
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        table = main_window.network_page.ui.flowTableContainer.ui.flowsTable
        rect = table.visualRect(table_model.index(1, 0))
        qtbot.mouseClick(table.viewport(), QtCore.Qt.MouseButton.LeftButton, pos=rect.center())

        # Assert
        request_text = main_window.network_page.ui.requestText.toPlainText()
        request_body_text = main_window.network_page.ui.requestBodyText.toPlainText()
        response_text = main_window.network_page.ui.responseText.toPlainText()
        response_body_text = main_window.network_page.ui.responseBodyText.toPlainText()

        assert "GRPC /api.TrayceAgent/SendContainersObserved" in request_text
        assert "containers {" in request_body_text
        assert 'id: "1234"' in request_body_text

        assert "success" in response_text
        assert 'status: "success "' in response_body_text
