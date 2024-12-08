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


def describe_network_page_demo():
    pass
    # default_headers = headers = {
    #     "User-Agent": "Python HTTP Client",
    #     "Accept": "application/json",
    #     "Content-Type": "application/x-www-form-urlencoded",
    # }

    # resp_body = """{
    # "users": [
    #     {
    #     "id": 1,
    #     "name": "John Doe",
    #     "email": "john.doe@example.com",
    #     "phone": "555-1234",
    #     "address": {
    #         "street": "123 Main St",
    #         "city": "Anytown",
    #         "state": "Anystate",
    #         "zip": "12345"
    #     },
    #     "preferences": {
    #         "newsletter": true,
    #         "notifications": false,
    #         "theme": "dark"
    #     }
    #     },
    #     {
    #     "id": 2,
    #     "name": "Jane Smith",
    #     "email": "jane.smith@example.com",
    #     "phone": "555-5678",
    #     "address": {
    #         "street": "456 Elm St",
    #         "city": "Othertown",
    #         "state": "Otherstate",
    #         "zip": "67890"
    #     },
    #     "preferences": {
    #         "newsletter": false,
    #         "notifications": true,
    #         "theme": "light"
    #     }
    #     },
    #     {
    #     "id": 3,
    #     "name": "Alice Johnson",
    #     "email": "alice.johnson@example.com",
    #     "phone": "555-8765",
    #     "address": {
    #         "street": "789 Oak St",
    #         "city": "Anothertown",
    #         "state": "Anotherstate",
    #         "zip": "13579"
    #     },
    #     "preferences": {
    #         "newsletter": true,
    #         "notifications": true,
    #         "theme": "dark"
    #     }
    #     }
    #     ]
    # }
    # """
    # def it_demo(qtbot: QtBot):  # type: ignore
    #     root_path = pathlib.Path("/home/evan/Code/trayce_gui")
    #     assets_path = root_path.joinpath("assets")
    #     print("root_path=", root_path)
    #     QtCore.QDir.addSearchPath("assets", str(assets_path))

    #     # Setup
    #     main_window = MainWindow(pathlib.Path("./assets"))

    #     rows = [
    #         ["1", "http", "localhost:3000", "GET", "/users.json", 200],
    #         ["1", "http", "localhost:3000", "POST", "/login", 401],
    #         ["1", "http", "user-service:443", "GET", "/users.json", 200],
    #         ["1", "http", "user-service:443", "GET", "/users.json", 200],
    #         ["1", "http", "user-service:443", "GET", "/users.json", 401],
    #         ["1", "http", "localhost:3000", "GET", "/users.json", 200],
    #         ["1", "http", "trayce.dev", "GET", "/index.html", 200],
    #         ["1", "http", "trayce.dev", "GET", "/blog.html", 200],
    #         ["1", "http", "localhost:3000", "GET", "/notfound", 404],
    #         ["1", "http", "localhost:3000", "POST", "/login", 500],
    #         ["1", "http", "localhost:3000", "GET", "/users.json", 200],
    #         ["1", "http", "localhost:3000", "GET", "/login", 200],
    #         ["1", "http", "localhost:3000", "GET", "/blog.html", 200],
    #         ["1", "http", "localhost:3000", "GET", "/index.html", 200],
    #         ["1", "http", "localhost:3000", "GET", "/index.html", 200],
    #     ]
    #     # TODO: Improve these factories also generate the uuid properly
    #     for i, row in enumerate(rows):
    #         req = generate_http_request2(str(row[3]), str(row[4]), str(row[2]), default_headers)
    #         flow1 = AgentFlowFactory.build(uuid=str(i), request=req)
    #         resp = generate_http_response(status=row[5], body=resp_body)
    #         flow2 = AgentFlowFactory.build_response(uuid=str(i), response=resp)

    #         signal = EventBusGlobal.get().flows_received
    #         with qtbot.waitSignal(signal, timeout=1000):
    #             send_flow_over_grpc(flow1)
    #             send_flow_over_grpc(flow2)

    #     # Subject
    #     main_window.show()
    #     qtbot.waitExposed(main_window)
    #     qtbot.wait(30000)

    #     main_window.about_to_quit()

    # # TODO: Remove this duplicate function
    # def generate_http_request2(method: str, path: str, host: str, headers: dict[str, str], body: Optional[str] = None):
    #     # Start with the request line
    #     request_line = f"{method} {path} HTTP/1.1\r\n"

    #     # Add the Host header
    #     header_lines = f"Host: {host}\r\n"

    #     # Add any additional headers
    #     for header, value in headers.items():
    #         header_lines += f"{header}: {value}\r\n"

    #     # Add the body if provided, with appropriate Content-Length header
    #     if body:
    #         if "Content-Length" not in headers:
    #             header_lines += f"Content-Length: {len(body)}\r\n"
    #         request = f"{request_line}{header_lines}\r\n{body}"
    #     else:
    #         request = f"{request_line}{header_lines}\r\n"

    #     # Convert the request to bytes
    #     return request.encode("utf-8")
