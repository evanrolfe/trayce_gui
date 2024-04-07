import typing
from PySide6 import QtCore, QtWidgets
from event_bus_global import EventBusGlobal
from network.event_bus import EventBus

from network.ui.ui_flow_table_container import Ui_FlowTableContainer
from network.widgets.flows_table_model import FlowsTableModel
from agent.api_pb2 import Flow as AgentFlow
from network.models.flow import Flow


class FlowTableContainer(QtWidgets.QWidget):
    table_model: FlowsTableModel

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(FlowTableContainer, self).__init__(*args, **kwargs)

        self.ui = Ui_FlowTableContainer()
        self.ui.setupUi(self)

        self.table_model = FlowsTableModel()
        self.ui.flowsTable.setModel(self.table_model)

        # Set selection behavior
        self.ui.flowsTable.setSelectionBehavior(QtWidgets.QAbstractItemView.SelectionBehavior.SelectRows)

        # Configure horizontal header
        horizontalHeader = self.ui.flowsTable.horizontalHeader()
        if horizontalHeader:
            horizontalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Interactive)
            horizontalHeader.setSortIndicator(0, QtCore.Qt.SortOrder.DescendingOrder)
            horizontalHeader.setHighlightSections(False)
            horizontalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            horizontalHeader.setSectionResizeMode(4, QtWidgets.QHeaderView.ResizeMode.Stretch)

        # Configure vertical header
        verticalHeader = self.ui.flowsTable.verticalHeader()
        if verticalHeader:
            verticalHeader.setVisible(False)
            verticalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            verticalHeader.setDefaultSectionSize(25)
            verticalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Fixed)

        # Set other table view properties
        self.ui.flowsTable.setSortingEnabled(False)
        self.ui.flowsTable.setVerticalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)
        self.ui.flowsTable.setHorizontalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)

        # Set column widths
        self.ui.flowsTable.setColumnWidth(0, 50)  # #
        self.ui.flowsTable.setColumnWidth(1, 75)  # Protocol
        self.ui.flowsTable.setColumnWidth(2, 150)  # Source
        self.ui.flowsTable.setColumnWidth(3, 150)  # Destination
        self.ui.flowsTable.setColumnWidth(4, 150)  # Operation
        self.ui.flowsTable.setColumnWidth(5, 75)  # Response

        self.ui.containersBtn.clicked.connect(EventBus.get().containers_btn_clicked)
        EventBusGlobal.get().flows_received.connect(self.flows_received)
        self.ui.flowsTable.selectionModel().selectionChanged.connect(self.flow_selected)

    def flows_received(self, agent_flows: list[AgentFlow]):
        flows = [Flow.from_agent_flow(af) for af in agent_flows]
        self.table_model.add_flows(flows)

    def flow_selected(self, selected: QtCore.QItemSelection, deselecte: QtCore.QItemSelection):
        selected_indexes = self.ui.flowsTable.selectionModel().selectedRows()
        # TODO: Catch IndexError out of range
        flow = self.table_model.get_flow(selected_indexes[0])
        if flow is None:
            return
        EventBus.get().flow_selected.emit(flow)
