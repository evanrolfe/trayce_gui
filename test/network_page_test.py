import pathlib
from PySide6 import QtCore

from pytestqt.qtbot import QtBot
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from helpers import generate_http_response, send_flow_over_grpc, generate_http_request
from factories.agent_flow_factory import AgentFlowFactory


def describe_network_page():
    def it_displays_a_flow_received(qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        n = 3

        # TODO: Improve these factories also generate the uuid properly
        for i in range(n):
            flow1 = AgentFlowFactory.build(uuid=str(i))
            resp = generate_http_response(status=200, body='{"hello":"world","how":"areyou","ok":123,"enabled": false}')
            flow2 = AgentFlowFactory.build_response(uuid=str(i), response=resp)

            signal = EventBusGlobal.get().flows_received
            with qtbot.waitSignal(signal, timeout=1000):
                send_flow_over_grpc(flow1)
                send_flow_over_grpc(flow2)

        # Subject
        main_window.show()
        # qtbot.waitExposed(main_window)
        # qtbot.wait(3000)

        # Assert
        table_model = main_window.network_page.ui.flowTableContainer.table_model
        assert table_model.rowCount() == n
        # assert table_model.data(table_model.index(0, 0)) == "1111"
        assert table_model.data(table_model.index(0, 1)) == "http"
        assert table_model.data(table_model.index(0, 2)) == "172.17.0.3:3001"
        # assert table_model.data(table_model.index(0, 3)) == "GET"
        assert table_model.data(table_model.index(0, 4)) == "/"
        # assert table_model.data(table_model.index(0, 5)) == "200"

        main_window.about_to_quit()

    def it_lets_you_select_a_flow(qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        req = generate_http_request(
            method="POST",
            headers={"Content-Type": "application/json"},
            body='{"hello":"world","how":"areyou","ok":123}',
        )
        flow = AgentFlowFactory.build(request=req)
        send_flow_over_grpc(flow)

        resp = generate_http_response(body='{"hello":"world","how":"areyou","ok":123,"enabled": false}')
        flow = AgentFlowFactory.build_response(response=resp)
        send_flow_over_grpc(flow)

        signal = EventBusGlobal.get().flows_received
        with qtbot.waitSignal(signal, timeout=1000):
            send_flow_over_grpc(flow)

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

        main_window.about_to_quit()
