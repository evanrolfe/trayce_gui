import pathlib
import signal

from PyQt6 import QtWidgets, QtGui, QtCore
from ui_main_window import Ui_MainWindow
from network.network_page import NetworkPage
from editor.editor_page import EditorPage
from stylesheet_loader import StyleheetLoader

signal.signal(signal.SIGINT, signal.SIG_DFL)


class MainWindow(QtWidgets.QMainWindow):
    # reload_style = QtCore.Signal()
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

    def sidebar_item_clicked(self, item: QtWidgets.QListWidgetItem, prev: QtWidgets.QListWidgetItem):
        item_value = item.data(QtCore.Qt.ItemDataRole.UserRole)

        if item_value == "network":
            self.ui.stackedWidget.setCurrentWidget(self.network_page)
        elif item_value == "editor":
            self.ui.stackedWidget.setCurrentWidget(self.editor_page)

    def load_style(self):
        style_loader = StyleheetLoader(self.assets_path)
        stylesheet = style_loader.load_theme("dark")
        if stylesheet != "":
            self.setStyleSheet(stylesheet)

    def about_to_quit(self):
        self.network_page.about_to_quit()
        self.editor_page.about_to_quit()
