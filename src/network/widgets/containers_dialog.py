from time import sleep
import typing
from PySide6 import QtCore, QtWidgets
import agent
from event_bus_global import EventBusGlobal
from network.event_bus import EventBus
from network.models.container import Container
from network.models.containers_state import ContainersState
from network.ui.ui_containers_dialog import Ui_ContainersDialog
from network.widgets.containers_table_model import ContainersTableModel
from network.repos.container_repo import ContainerRepo
from async_proc import AsyncProc, AsyncSignals
from agent.helpers import get_docker_cmd
from agent.api_pb2 import Container as AgentContainer


class ContainersDialog(QtWidgets.QDialog):
    app_running: bool
    agent_running: bool
    table_model: ContainersTableModel
    container_repo: ContainerRepo

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(ContainersDialog, self).__init__(*args, **kwargs)

        self.ui = Ui_ContainersDialog()
        self.ui.setupUi(self)
        self.setModal(True)

        self.table_model = ContainersTableModel()
        self.ui.containersTable.setModel(self.table_model)

        self.ui.saveButton.clicked.connect(self.save_clicked)
        self.ui.cancelButton.clicked.connect(self.close)
        self.ui.dockerCopyButton.clicked.connect(self.copy_cmd)

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

        self.container_repo = ContainerRepo()
        self.table_model.set_containers(self.container_repo.get_all())

        self.agent_running = False
        self.show_agent_not_running()

        self.app_running = True
        EventBusGlobal.get().containers_observed.connect(self.containers_observed)
        EventBus.get().containers_btn_clicked.connect(self.show)

    def show(self):
        self.ui.dockerCopyButton.setText("Copy")
        super().show()

    def containers_observed(self, agent_containers: list[AgentContainer]):
        containers = []
        for agent_container in agent_containers:
            container = Container(
                short_id=agent_container.id,
                name=agent_container.name,
                status=agent_container.status,
                ports={},
                image=agent_container.image,
                networks=[],
                host_name=agent_container.name,
                ip=agent_container.ip,
                raw_container={},
                intercepted=False,
            )
            containers.append(container)
        self.table_model.merge_containers(containers)
        containers_state = ContainersState(containers=containers)
        agent_running = containers_state.is_trayce_agent_running()

        if agent_running == self.agent_running:
            return

        # TODO: Only publish if it actually changes!!!
        EventBus.get().container_state_changed.emit(containers_state)

        self.agent_running = agent_running
        if self.agent_running:
            self.show_agent_running()
        else:
            self.show_agent_not_running()

    def show_agent_running(self):
        self.ui.dockerStartLabel.hide()
        self.ui.dockerCmdInput.hide()
        self.ui.dockerCopyButton.hide()

        self.ui.selectContainerLabel.show()
        self.ui.selectContainerLine.show()
        self.ui.containersTable.show()

    def show_agent_not_running(self):
        self.ui.dockerCmdInput.setText(get_docker_cmd())
        self.ui.dockerStartLabel.show()
        self.ui.dockerCmdInput.show()
        self.ui.dockerCopyButton.show()

        self.ui.selectContainerLabel.hide()
        self.ui.selectContainerLine.hide()
        self.ui.containersTable.hide()

    def save_clicked(self):
        container_ids = [c.short_id for c in self.table_model.containers if c.intercepted]
        EventBusGlobal.get().intercept_containers.emit(container_ids)
        self.close()

    def copy_cmd(self):
        self.ui.dockerCmdInput.setFocus()
        self.ui.dockerCmdInput.selectAll()
        self.ui.dockerCmdInput.copy()
        self.ui.dockerCopyButton.setText("Copied")

    def about_to_quit(self):
        self.app_running = False
