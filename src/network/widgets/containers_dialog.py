from time import sleep
import typing
from PySide6 import QtCore, QtWidgets
from event_bus_global import EventBusGlobal
from network.event_bus import EventBus
from network.ui.ui_containers_dialog import Ui_ContainersDialog
from network.widgets.containers_table_model import ContainersTableModel
from network.repos.container_repo import ContainerRepo
from async_proc import AsyncProc, AsyncSignals


class ContainersDialog(QtWidgets.QDialog):
    app_running: bool
    table_model: ContainersTableModel
    __reload = QtCore.Signal()

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(ContainersDialog, self).__init__(*args, **kwargs)

        self.ui = Ui_ContainersDialog()
        self.ui.setupUi(self)
        self.setModal(True)

        self.table_model = ContainersTableModel()
        self.ui.containersTable.setModel(self.table_model)

        self.ui.saveButton.clicked.connect(self.save_clicked)
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

        self.ui.containersTable.clicked.connect(self.table_model.table_cell_clicked)

        containers = ContainerRepo().get_all()
        self.table_model.set_containers(containers)

        self.__reload.connect(self.load_containers)

        self.app_running = True
        self.reload_proc = AsyncProc(self.load_containers_periodically)
        self.threadpool = QtCore.QThreadPool()
        self.threadpool.start(self.reload_proc)

        EventBus.get().containers_btn_clicked.connect(self.show)

    def load_containers(self):
        # Load docker containers to table
        containers = ContainerRepo().get_all()
        self.table_model.merge_containers(containers)

    def load_containers_periodically(self, signals: AsyncSignals):
        while self.app_running:
            self.__reload.emit()
            sleep(0.5)

    def save_clicked(self):
        container_ids = [c.short_id for c in self.table_model.containers if c.intercepted]
        EventBusGlobal.get().intercept_containers.emit(container_ids)
        self.close()

    def about_to_quit(self):
        self.app_running = False
