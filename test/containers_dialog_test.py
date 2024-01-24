from PySide6 import QtCore
from unittest.mock import patch
from pytestqt.qtbot import QtBot

from network.widgets.containers_dialog import ContainersDialog
from factories.container_factory import ContainerFactory


def describe_containers_dialog():
    def it_displays_the_containers(qtbot: QtBot):  # type: ignore
        with patch("network.widgets.containers_dialog.ContainerRepo") as MockContainerRepo:
            container1 = ContainerFactory.build()
            container2 = ContainerFactory.build(intercepted=True)

            mock_repo = MockContainerRepo.return_value
            mock_repo.get_all.return_value = [container1, container2]

            widget = ContainersDialog()

            # widget.show()
            # qtbot.waitExposed(widget)
            # qtbot.wait(500)

            table_model = widget.table_model
            widget.about_to_quit()
            check_state = QtCore.Qt.ItemDataRole.CheckStateRole

            assert table_model.rowCount() == 2
            assert table_model.data(table_model.index(0, 0)) == container1.short_id
            assert table_model.data(table_model.index(0, 1)) == container1.image
            assert table_model.data(table_model.index(0, 2)) == container1.ip
            assert table_model.data(table_model.index(0, 3)) == container1.name
            assert table_model.data(table_model.index(0, 4)) == container1.status
            assert table_model.data(table_model.index(0, 5), check_state) == QtCore.Qt.CheckState.Unchecked

            assert table_model.data(table_model.index(1, 0)) == container2.short_id
            assert table_model.data(table_model.index(1, 1)) == container2.image
            assert table_model.data(table_model.index(1, 2)) == container2.ip
            assert table_model.data(table_model.index(1, 3)) == container2.name
            assert table_model.data(table_model.index(1, 4)) == container2.status
            assert table_model.data(table_model.index(1, 5), check_state) == QtCore.Qt.CheckState.Checked
