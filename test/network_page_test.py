import pathlib
from typing import Optional
from PySide6 import QtCore

from pytestqt.qtbot import QtBot
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from helpers import generate_http_response, send_flow_over_grpc, generate_http_request
from factories.agent_flow_factory import AgentFlowFactory

default_headers = headers = {
    "User-Agent": "Python HTTP Client",
    "Accept": "application/json",
    "Content-Type": "application/x-www-form-urlencoded",
}

resp_body = """{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "phone": "555-1234",
      "address": {
        "street": "123 Main St",
        "city": "Anytown",
        "state": "Anystate",
        "zip": "12345"
      },
      "preferences": {
        "newsletter": true,
        "notifications": false,
        "theme": "dark"
      }
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane.smith@example.com",
      "phone": "555-5678",
      "address": {
        "street": "456 Elm St",
        "city": "Othertown",
        "state": "Otherstate",
        "zip": "67890"
      },
      "preferences": {
        "newsletter": false,
        "notifications": true,
        "theme": "light"
      }
    },
    {
      "id": 3,
      "name": "Alice Johnson",
      "email": "alice.johnson@example.com",
      "phone": "555-8765",
      "address": {
        "street": "789 Oak St",
        "city": "Anothertown",
        "state": "Anotherstate",
        "zip": "13579"
      },
      "preferences": {
        "newsletter": true,
        "notifications": true,
        "theme": "dark"
      }
    }
    ]
}
"""


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

    def it_demo(qtbot: QtBot):  # type: ignore
        root_path = pathlib.Path("/home/evan/Code/trayce_gui")
        assets_path = root_path.joinpath("assets")
        print("root_path=", root_path)
        QtCore.QDir.addSearchPath("assets", str(assets_path))

        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        rows = [
            ["1", "http", "localhost:3000", "GET", "/users.json", 200],
            ["1", "http", "localhost:3000", "POST", "/login", 401],
            ["1", "http", "user-service:443", "GET", "/users.json", 200],
            ["1", "http", "user-service:443", "GET", "/users.json", 200],
            ["1", "http", "user-service:443", "GET", "/users.json", 401],
            ["1", "http", "localhost:3000", "GET", "/users.json", 200],
            ["1", "http", "trayce.dev", "GET", "/index.html", 200],
            ["1", "http", "trayce.dev", "GET", "/blog.html", 200],
            ["1", "http", "localhost:3000", "GET", "/notfound", 404],
            ["1", "http", "localhost:3000", "POST", "/login", 500],
            ["1", "http", "localhost:3000", "GET", "/users.json", 200],
            ["1", "http", "localhost:3000", "GET", "/login", 200],
            ["1", "http", "localhost:3000", "GET", "/blog.html", 200],
            ["1", "http", "localhost:3000", "GET", "/index.html", 200],
            ["1", "http", "localhost:3000", "GET", "/index.html", 200],
        ]
        # TODO: Improve these factories also generate the uuid properly
        for i, row in enumerate(rows):
            req = generate_http_request(row[3], row[4], row[2], default_headers)
            flow1 = AgentFlowFactory.build(uuid=str(i), request=req)
            resp = generate_http_response(status=row[5], body=resp_body)
            flow2 = AgentFlowFactory.build_response(uuid=str(i), response=resp)

            signal = EventBusGlobal.get().flows_received
            with qtbot.waitSignal(signal, timeout=1000):
                send_flow_over_grpc(flow1)
                send_flow_over_grpc(flow2)

        # Subject
        main_window.show()
        qtbot.waitExposed(main_window)
        qtbot.wait(30000)

        main_window.about_to_quit()


# TODO: Remove this duplicate function
def generate_http_request(method: str, path: str, host: str, headers: dict[str, str], body: Optional[str] = None):
    # Start with the request line
    request_line = f"{method} {path} HTTP/1.1\r\n"

    # Add the Host header
    header_lines = f"Host: {host}\r\n"

    # Add any additional headers
    for header, value in headers.items():
        header_lines += f"{header}: {value}\r\n"

    # Add the body if provided, with appropriate Content-Length header
    if body:
        if "Content-Length" not in headers:
            header_lines += f"Content-Length: {len(body)}\r\n"
        request = f"{request_line}{header_lines}\r\n{body}"
    else:
        request = f"{request_line}{header_lines}\r\n"

    # Convert the request to bytes
    return request.encode("utf-8")
