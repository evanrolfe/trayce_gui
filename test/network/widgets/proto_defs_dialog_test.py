import pathlib
from unittest.mock import patch
from PySide6 import QtCore, QtWidgets
from pytestqt.qtbot import QtBot
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from support.helpers import send_containers_over_grpc
from agent.api_pb2 import Container as AgentContainer
from network.repos.proto_def_repo import ProtoDefRepo


def describe_proto_defs_dialog():
    def it_displays_the_proto_defs(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))
        proto_def1 = ProtoDefRepo().upload("api.TrayceAgent", "src/agent/api.proto")
        proto_def2 = ProtoDefRepo().upload("api.TrayceAgent2", "src/agent/api.proto")

        # Subject
        dialog = main_window.network_page.proto_defs_dialog
        dialog.show()

        # with patch("PySide6.QtWidgets.QFileDialog.getOpenFileName", return_value=("from_test.proto", "")):
        #     button = dialog.ui.uploadButton
        #     qtbot.mouseClick(button, QtCore.Qt.MouseButton.LeftButton, pos=button.rect().center())

        # main_window.show()
        # qtbot.waitExposed(main_window)
        # qtbot.wait(3000)

        table_model = dialog.table_model
        assert table_model.rowCount() == 2
        assert table_model.data(table_model.index(0, 0)) == "api.TrayceAgent"
        assert table_model.data(table_model.index(1, 0)) == "api.TrayceAgent2"

        main_window.about_to_quit()

    def it_uploads_a_proto_def(database, cleanup_database, qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        # Subject
        dialog = main_window.network_page.proto_defs_dialog
        dialog.show()

        with patch("PySide6.QtWidgets.QFileDialog.getOpenFileName", return_value=("src/agent/api.proto", "")):
            button = dialog.ui.uploadButton
            qtbot.mouseClick(button, QtCore.Qt.MouseButton.LeftButton, pos=button.rect().center())

        # main_window.show()
        # qtbot.waitExposed(main_window)
        # qtbot.wait(3000)

        # table_model = dialog.table_model
        # assert table_model.rowCount() == 2
        # assert table_model.data(table_model.index(0, 0)) == "api.TrayceAgent"
        # assert table_model.data(table_model.index(1, 0)) == "api.TrayceAgent2"

        main_window.about_to_quit()
