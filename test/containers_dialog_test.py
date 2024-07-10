import pathlib
from PySide6 import QtCore, QtWidgets
from pytestqt.qtbot import QtBot
from event_bus_global import EventBusGlobal

from main_window import MainWindow
from helpers import send_containers_over_grpc
from agent.api_pb2 import Container as AgentContainer


def describe_containers_dialog():
    def it_displays_the_containers(qtbot: QtBot):  # type: ignore
        # Setup
        main_window = MainWindow(pathlib.Path("./assets"))

        container1 = AgentContainer(
            id="1",
            image="traycer/trayce_agent",
            ip="172.17.0.1",
            name="test1",
            status="running",
        )
        container2 = AgentContainer(
            id="2",
            image="mega_server",
            ip="172.17.0.2",
            name="test2",
            status="running",
        )

        # Subject
        containers_dialog = main_window.network_page.containers_dialog
        containers_dialog.show()

        containers: list[AgentContainer] = [container1, container2]

        signal = EventBusGlobal.get().containers_observed
        with qtbot.waitSignal(signal, timeout=1000):
            send_containers_over_grpc(containers)

        # Assert
        table_model = containers_dialog.table_model
        check_state = QtCore.Qt.ItemDataRole.CheckStateRole
        assert table_model.rowCount() == 2
        assert table_model.data(table_model.index(0, 0)) == container1.id
        assert table_model.data(table_model.index(0, 1)) == container1.image
        assert table_model.data(table_model.index(0, 2)) == container1.ip
        assert table_model.data(table_model.index(0, 3)) == container1.name
        assert table_model.data(table_model.index(0, 4)) == container1.status
        assert table_model.data(table_model.index(0, 5), check_state) == QtCore.Qt.CheckState.Unchecked

        assert table_model.data(table_model.index(1, 0)) == container2.id
        assert table_model.data(table_model.index(1, 1)) == container2.image
        assert table_model.data(table_model.index(1, 2)) == container2.ip
        assert table_model.data(table_model.index(1, 3)) == container2.name
        assert table_model.data(table_model.index(1, 4)) == container2.status
        assert table_model.data(table_model.index(1, 5), check_state) == QtCore.Qt.CheckState.Unchecked

        main_window.about_to_quit()

    # TODO: Get this test working by checking if the GRPC message was sent rather than mocking
    # def it_sends_the_selected_container_ids_to_the_agent(qtbot: QtBot):  # type: ignore
    #     # Setup
    #     main_window = MainWindow(pathlib.Path("./assets"))

    #     container1 = AgentContainer(
    #         id="1",
    #         image="traycer/trayce_agent",
    #         ip="172.17.0.1",
    #         name="test1",
    #         status="running",
    #     )
    #     container2 = AgentContainer(
    #         id="2",
    #         image="mega_server",
    #         ip="172.17.0.2",
    #         name="test2",
    #         status="running",
    #     )

    #     # Subject
    #     containers_dialog = main_window.network_page.containers_dialog
    #     containers_dialog.show()

    #     containers: list[AgentContainer] = [container1, container2]

    #     signal = EventBusGlobal.get().containers_observed
    #     with qtbot.waitSignal(signal, timeout=1000):
    #         send_containers_over_grpc(containers)

    #     # select a container from the table
    #     cell_center = get_table_cell_center(containers_dialog.ui.containersTable, 1, 5)
    #     qtbot.mouseClick(
    #         containers_dialog.ui.containersTable.viewport(), QtCore.Qt.MouseButton.LeftButton, pos=cell_center
    #     )

    #     container_ids_from_signal = []

    #     def capture_signal(container_ids: list[str]) -> bool:
    #         nonlocal container_ids_from_signal
    #         container_ids_from_signal = container_ids
    #         return True

    #     # Subject
    #     signal = EventBusGlobal.get().intercept_containers
    #     with qtbot.waitSignal(signal, timeout=1000, check_params_cb=capture_signal):
    #         button = containers_dialog.ui.saveButton
    #         qtbot.mouseClick(button, QtCore.Qt.MouseButton.LeftButton, pos=button.rect().center())

    #     # Assert
    #     assert container_ids_from_signal == [container2.id]
    #     main_window.about_to_quit()


def get_table_cell_center(table_view: QtWidgets.QTableView, row: int, column: int):
    cell_rect = table_view.visualRect(table_view.model().index(row, column))
    return cell_rect.center()
