from typing import Optional
from PySide6 import QtWidgets, QtCore, QtGui


class Sidebar(QtWidgets.QListWidget):
    def __init__(self, parent: Optional[QtWidgets.QWidget]):
        super(Sidebar, self).__init__(parent)
        self.setup()

    def setup(self):
        print("Setting up sidebar!")
        self.itemSelectionChanged.connect(self.selection_changed)

        self.setObjectName("sideBar")
        self.setViewMode(QtWidgets.QListView.ViewMode.IconMode)
        self.setFlow(QtWidgets.QListView.Flow.TopToBottom)
        self.setMovement(QtWidgets.QListView.Movement.Static)
        self.setUniformItemSizes(True)

        # Network Item
        network_item = QtWidgets.QListWidgetItem(
            QtGui.QIcon("assets:icons/dark/icons8-cloud-backup-restore-50.png"),
            "Network",
            None,
        )
        network_item.setData(QtCore.Qt.ItemDataRole.UserRole, "network")
        network_item.setToolTip("Network")
        # network_item.setSizeHint(QtCore.QSize(72, 72))
        self.addItem(network_item)

        # Editor Item
        editor_item = QtWidgets.QListWidgetItem(QtGui.QIcon("assets:icons/dark/icons8-compose-50.png"), "Editor", None)
        editor_item.setData(QtCore.Qt.ItemDataRole.UserRole, "editor")
        editor_item.setToolTip("Editor")
        self.addItem(editor_item)

        self.setCurrentRow(0)

    # DO not let the user de-select from the sidebar
    def selection_changed(self):
        print("selection changed")
