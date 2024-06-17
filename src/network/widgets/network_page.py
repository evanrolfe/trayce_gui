import re
from PySide6 import QtCore, QtGui, QtWidgets
from network.event_bus import EventBus
from network.models.flow import Flow

from network.ui.ui_network_page import Ui_NetworkPage
from agent.agent_thread import AgentThread
from network.widgets.containers_dialog import ContainersDialog

# class DarkTheme:
#     default_bg = "#1E1E1E"
#     default_color = "#EEFFFF"
#     darker_color = "#545454"
#     key_color = "#C792EA"
#     value_color = "#C3E88D"
#     number_color = "#FF5370"
#     operator_color = "#569CD6"
#     invalid_color = "#f14721"
#     selected_secondary_color = "#4E5256"
#     other_color = "#FFCB6B"

#     bg_dark = "#252526"
#     bg_input = "#404040"
#     bg_input_hover = "#3A3A3A"


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

    def __init__(self, parent: QtWidgets.QWidget):
        super(NetworkPage, self).__init__(parent)

        # Call the constructor to setup this singleton class
        self.ui = Ui_NetworkPage()
        self.ui.setupUi(self)

        self.containers_dialog = ContainersDialog(self)
        # Theme colours
        # default_bg = "#1E1E1E"
        # default_color = "#EEFFFF"
        # darker_color = "#545454"
        # key_color = "#C792EA"
        # value_color = "#C3E88D"
        # number_color = "#FF5370"
        # operator_color = "#569CD6"
        # invalid_color = "#f14721"
        # selected_secondary_color = "#4E5256"
        # other_color = "#FFCB6B"
        # bg_dark = "#252526"
        # bg_input = "#404040"
        # bg_input_hover = "#3A3A3A"

        # self.ui.requestText.setPaper(QtGui.QColor(default_bg))
        # self.ui.requestText.setColor(QtGui.QColor(default_color))
        # self.ui.requestText.setCaretForegroundColor(QtGui.QColor(default_color))
        # self.ui.requestText.setMarginsForegroundColor(QtGui.QColor(default_color))
        # self.ui.requestText.setMarginsBackgroundColor(QtGui.QColor(default_bg))

        # self.ui.responseText.setPaper(QtGui.QColor(default_bg))
        # self.ui.responseText.setColor(QtGui.QColor(default_color))
        # self.ui.responseText.setCaretForegroundColor(QtGui.QColor(default_color))
        # self.ui.responseText.setMarginsForegroundColor(QtGui.QColor(default_color))
        # self.ui.responseText.setMarginsBackgroundColor(QtGui.QColor(default_bg))

        # self.ui.requestText.setUtf8(True)
        # self.ui.requestText.setAutoIndent(True)
        # self.ui.requestText.setIndentationsUseTabs(False)
        # self.ui.requestText.setIndentationWidth(4)
        # self.ui.requestText.setIndentationGuides(True)
        # self.ui.requestText.setBackspaceUnindents(True)
        # self.ui.requestText.setEdgeColumn(79)
        # self.ui.requestText.setMarginWidth(0, 0)
        # self.ui.requestText.setBraceMatching(Qsci.QsciScintilla.BraceMatch.SloppyBraceMatch)
        # ui.requestText->setMarginLineNumbers(0, true);

        # Start the GRPC server
        self.thread_pool = QtCore.QThreadPool()
        self.grpc_worker = AgentThread()
        self.thread_pool.start(self.grpc_worker)

        doc = self.ui.responseBodyText.document()
        JsonHighlighter(doc)

        self.ui.responseTabs.setCurrentIndex(1)
        EventBus.get().flow_selected.connect(self.flow_selected)

    def flow_selected(self, flow: Flow):
        self.ui.requestText.setPlainText(flow.request_str())
        self.ui.responseText.setPlainText(flow.response_str())

        self.ui.requestBodyText.setPlainText(flow.request_body_formatted())
        self.ui.responseBodyText.setPlainText(flow.response_body_formatted())

    def about_to_quit(self):
        self.grpc_worker.stop()
        self.containers_dialog.about_to_quit()
