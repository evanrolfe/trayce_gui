import re
from typing import Optional
from PySide6 import QtCore, QtGui, QtWidgets
from agent.heartbeat_thread import HeartbeatThread
from network.event_bus import EventBus
from network.models.flow import Flow

from network.models.grpc_request import GrpcRequest
from network.models.grpc_response import GrpcResponse
from network.models.proto_def import ProtoDef
from network.repos.proto_def_repo import ProtoDefRepo
from network.ui.ui_network_page import Ui_NetworkPage
from agent.agent_thread import AgentThread
from network.widgets.containers_dialog import ContainersDialog
from network.widgets.proto_defs_dialog import ProtoDefsDialog

class JsonHighlighter(QtGui.QSyntaxHighlighter):
    highlightingRules: list[tuple[QtCore.QRegularExpression, QtGui.QTextCharFormat]]
    mappings: dict[str, QtGui.QTextCharFormat]

    def __init__(self, parent: QtGui.QTextDocument):
        super().__init__(parent)
        self.highlightingRules = []

        string_regex = r'"(?:\\.|[^"\\])*"'
        string_format = QtGui.QTextCharFormat()
        string_format.setForeground(QtGui.QColor("#C3E88D"))

        number_regex = r"\b-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?\b"
        number_format = QtGui.QTextCharFormat()
        number_format.setForeground(QtGui.QColor("#FF5370"))

        keyword_regex = r"\b(true|false|null)\b"
        keyword_format = QtGui.QTextCharFormat()
        keyword_format.setForeground(QtGui.QColor("#C792EA"))

        self.mappings = {string_regex: string_format, number_regex: number_format, keyword_regex: keyword_format}

    def highlightBlock(self, text: str):
        for pattern, format in self.mappings.items():
            for match in re.finditer(pattern, text):
                start, end = match.span()
                self.setFormat(start, end - start, format)


class NetworkPage(QtWidgets.QWidget):
    thread_pool: QtCore.QThreadPool
    grpc_worker: AgentThread
    selected_proto_def: Optional[ProtoDef]
    selected_flow: Optional[Flow]
    proto_file_dropdown_prev_index: int

    def __init__(self, parent: QtWidgets.QWidget):
        super(NetworkPage, self).__init__(parent)

        # Call the constructor to setup this singleton class
        self.ui = Ui_NetworkPage()
        self.ui.setupUi(self)

        self.containers_dialog = ContainersDialog(self)
        self.proto_defs_dialog = ProtoDefsDialog(self)
        self.selected_proto_def = None
        self.selected_flow = None

        # Start the GRPC server
        self.thread_pool = QtCore.QThreadPool()
        self.grpc_worker = AgentThread()
        self.heartbeat_check = HeartbeatThread(self.grpc_worker.agent)
        self.thread_pool.start(self.grpc_worker)
        self.thread_pool.start(self.heartbeat_check)

        doc = self.ui.responseBodyText.document()
        JsonHighlighter(doc)

        self.ui.responseTabs.setCurrentIndex(1)
        EventBus.get().flow_selected.connect(self.flow_selected)
        EventBus.get().proto_defs_changed.connect(self.load_proto_defs)

        # GRPC dropdown
        self.proto_file_dropdown = QtWidgets.QComboBox()
        self.proto_file_dropdown.setContentsMargins(10, 10, 10, 10)
        self.proto_file_dropdown.setObjectName('protoFileDropdown')
        self.proto_file_dropdown_prev_index = 0
        self.proto_file_dropdown.currentIndexChanged.connect(self.proto_file_dropdown_changed)
        self.proto_file_dropdown.hide()
        self.load_proto_defs()


        self.ui.requestTabs.setCornerWidget(self.proto_file_dropdown)

    def flow_selected(self, flow: Flow):
        self.selected_flow = flow
        self.reload_flow()

    def reload_flow(self):
        flow = self.selected_flow
        if not flow:
            return

        self.ui.requestText.setPlainText(str(flow.request))
        self.ui.requestBodyText.setPlainText(flow.request_body_formatted())

        is_grpc = isinstance(flow.request, GrpcRequest) and isinstance(flow.response, GrpcResponse)
        self.proto_file_dropdown.setVisible(is_grpc)

        if isinstance(flow.request, GrpcRequest) and isinstance(flow.response, GrpcResponse) and self.selected_proto_def:
            proto_file = self.selected_proto_def.file_descriptor()

            req_body_decoded = flow.request.decode_body(proto_file, flow.request.path)
            resp_body_decoded = flow.response.decode_body(proto_file, flow.request.path)

            self.ui.requestText.setPlainText(flow.request.header_str() + "\r\n" + req_body_decoded)
            self.ui.requestBodyText.setPlainText(req_body_decoded)

            self.ui.responseText.setPlainText(str(flow.response.header_str() + "\r\n" + resp_body_decoded))
            self.ui.responseBodyText.setPlainText(resp_body_decoded)

        else:
            self.ui.requestText.setPlainText(str(flow.request))
            self.ui.requestBodyText.setPlainText(flow.request_body_formatted())

            self.ui.responseText.setPlainText(str(flow.response))
            self.ui.responseBodyText.setPlainText(flow.response_body_formatted())

    def load_proto_defs(self):
        proto_defs = ProtoDefRepo().find_all()

        self.proto_file_dropdown.clear()
        self.proto_file_dropdown.addItem("Select .proto file", userData=0)
        for proto_def in proto_defs:
            self.proto_file_dropdown.addItem(proto_def.name, userData=proto_def)
        self.proto_file_dropdown.addItem("Upload new", userData=0)

        self.proto_file_dropdown.setCurrentIndex(0)

    def proto_file_dropdown_changed(self, index: int):
        if index == 0:
            self.selected_proto_def = None
            self.proto_file_dropdown_prev_index = 0

        elif index == self.proto_file_dropdown.count() - 1: # if its the last time
            self.proto_file_dropdown.setCurrentIndex(self.proto_file_dropdown_prev_index)
            self.proto_defs_dialog.show()

        else:
            proto_def: ProtoDef = self.proto_file_dropdown.itemData(index)
            self.selected_proto_def = proto_def
            self.reload_flow()
            self.proto_file_dropdown_prev_index = index

    def about_to_quit(self):
        self.grpc_worker.stop()
        self.heartbeat_check.stop()
        self.containers_dialog.about_to_quit()
