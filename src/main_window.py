import pathlib
import signal

from PySide6 import QtWidgets, QtGui, QtCore
from network.event_bus import EventBus
from network.models.containers_state import ContainersState
from ui_main_window import Ui_MainWindow
from network.widgets.network_page import NetworkPage
from editor.editor_page import EditorPage
from stylesheet_loader import StyleheetLoader

signal.signal(signal.SIGINT, signal.SIG_DFL)


class MainWindow(QtWidgets.QMainWindow):
    assets_path: pathlib.Path

    def __init__(self, assets_path: pathlib.Path):
        super(MainWindow, self).__init__()

        self.assets_path = assets_path
        self.setWindowTitle("PnTest")
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        self.network_page = NetworkPage(self)
        self.editor_page = EditorPage(self)

        layout = self.ui.centralWidget.layout()
        if layout:
            layout.setContentsMargins(0, 0, 0, 0)

        self.ui.stackedWidget.addWidget(self.network_page)
        self.ui.stackedWidget.addWidget(self.editor_page)
        self.ui.sideBar.currentItemChanged.connect(self.sidebar_item_clicked)

        self.load_style()

        # For testing purposes only:
        keyseq_ctrl_r = QtGui.QShortcut(QtGui.QKeySequence("Ctrl+R"), self)
        keyseq_ctrl_r.activated.connect(self.load_style)

        # Status bar
        self.agent_status = QtWidgets.QPushButton()
        self.agent_status.setText("Trayce Agent: not running")
        self.agent_status.setObjectName("agentStatus")
        self.agent_status.setCursor(QtGui.QCursor(QtCore.Qt.CursorShape.PointingHandCursor))
        self.agent_status.clicked.connect(EventBus.get().containers_btn_clicked)

        self.containers_status = QtWidgets.QPushButton()
        self.containers_status.setText("Containers (0)")
        self.containers_status.setObjectName("containersStatus")
        self.containers_status.setCursor(QtGui.QCursor(QtCore.Qt.CursorShape.PointingHandCursor))
        self.containers_status.clicked.connect(EventBus.get().containers_btn_clicked)

        line1 = QtWidgets.QFrame(self)
        line1.setFrameShape(QtWidgets.QFrame.Shape.VLine)
        line1.setFrameShadow(QtWidgets.QFrame.Shadow.Sunken)
        line1.setLineWidth(1)
        line1.setObjectName("statusBarLine")

        status_layout = QtWidgets.QHBoxLayout()
        status_layout.setSpacing(0)
        status_layout.setContentsMargins(0, 0, 10, 0)
        status_layout.setObjectName("statusLayout")
        status_layout.addWidget(self.containers_status)
        status_layout.addWidget(line1)
        status_layout.addWidget(self.agent_status)

        c = QtWidgets.QWidget()
        c.setLayout(status_layout)

        self.ui.statusBar.setSizeGripEnabled(False)
        self.ui.statusBar.insertPermanentWidget(0, c)

        EventBus.get().container_state_changed.connect(self.container_state_changed)

    def sidebar_item_clicked(self, item: QtWidgets.QListWidgetItem, prev: QtWidgets.QListWidgetItem):
        item_value = item.data(QtCore.Qt.ItemDataRole.UserRole)

        if item_value == "network":
            self.ui.stackedWidget.setCurrentWidget(self.network_page)
        elif item_value == "editor":
            self.ui.stackedWidget.setCurrentWidget(self.editor_page)

    def load_style(self):
        print("loading style")
        style_loader = StyleheetLoader(self.assets_path)
        stylesheet = style_loader.load_theme("dark")
        if stylesheet != "":
            self.setStyleSheet(stylesheet)

    def container_state_changed(self, state: ContainersState):
        self.containers_status.setText(f"Containers {len(state.containers)}")
        if state.is_trayce_agent_running():
            self.agent_status.setText(f"Trayce Agent: running")
        else:
            self.agent_status.setText(f"Trayce Agent: not running")

    def about_to_quit(self):
        self.network_page.about_to_quit()
        self.editor_page.about_to_quit()
