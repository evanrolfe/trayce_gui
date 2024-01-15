import typing
from PyQt6 import QtCore, QtWidgets
from network.ui_containers_dialog import Ui_ContainersDialog
from network.containers_table_model import ContainersTableModel
from network.container_repo import ContainerRepo


class ContainersDialog(QtWidgets.QDialog):
    proxify_containers = QtCore.pyqtSignal(list)

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(ContainersDialog, self).__init__(*args, **kwargs)

        self.ui = Ui_ContainersDialog()
        self.ui.setupUi(self)
        self.setModal(True)

        model = ContainersTableModel()
        self.ui.containersTable.setModel(model)

        self.ui.cancelButton.clicked.connect(self.close)

        # Configure horizontal header
        horizontalHeader = self.ui.containersTable.horizontalHeader()
        if horizontalHeader:
            horizontalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Interactive)
            horizontalHeader.setSortIndicator(0, QtCore.Qt.SortOrder.DescendingOrder)
            horizontalHeader.setHighlightSections(False)
            horizontalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            horizontalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Fixed)
            horizontalHeader.setSectionResizeMode(1, QtWidgets.QHeaderView.ResizeMode.Stretch)

        # Configure vertical header
        verticalHeader = self.ui.containersTable.verticalHeader()
        if verticalHeader:
            verticalHeader.setVisible(False)
            verticalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            verticalHeader.setDefaultSectionSize(25)
            verticalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Fixed)

        # Set other table view properties
        self.ui.containersTable.setSortingEnabled(False)
        self.ui.containersTable.setVerticalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)
        self.ui.containersTable.setHorizontalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)
        self.ui.containersTable.setSelectionMode(QtWidgets.QAbstractItemView.SelectionMode.NoSelection)
        self.ui.containersTable.setFocusPolicy(QtCore.Qt.FocusPolicy.NoFocus)

        # Load docker containers to table
        containers = ContainerRepo().get_all()
        model.set_containers(containers)

        self.ui.containersTable.clicked.connect(model.table_cell_clicked)
