import typing
from PySide6 import QtCore, QtWidgets

from network.ui.ui_flow_table_container import Ui_FlowTableContainer
from network.widgets.flows_table_model import FlowsTableModel
from agent.api_pb2 import Flow as AgentFlow
from network.models.flow import Flow


class FlowTableContainer(QtWidgets.QWidget):
    send_flow_to_editor = QtCore.Signal(object)
    send_flow_to_fuzzer = QtCore.Signal(object)

    table_model: FlowsTableModel

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(FlowTableContainer, self).__init__(*args, **kwargs)

        self.ui = Ui_FlowTableContainer()
        self.ui.setupUi(self)

        self.table_model = FlowsTableModel()
        self.ui.tableView.setModel(self.table_model)

        # Set selection behavior
        self.ui.tableView.setSelectionBehavior(QtWidgets.QAbstractItemView.SelectionBehavior.SelectRows)

        # Configure horizontal header
        horizontalHeader = self.ui.tableView.horizontalHeader()
        if horizontalHeader:
            horizontalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Interactive)
            horizontalHeader.setSortIndicator(0, QtCore.Qt.SortOrder.DescendingOrder)
            horizontalHeader.setHighlightSections(False)
            horizontalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            horizontalHeader.setSectionResizeMode(4, QtWidgets.QHeaderView.ResizeMode.Stretch)

        # Configure vertical header
        verticalHeader = self.ui.tableView.verticalHeader()
        if verticalHeader:
            verticalHeader.setVisible(False)
            verticalHeader.setDefaultAlignment(QtCore.Qt.AlignmentFlag.AlignLeft)
            verticalHeader.setDefaultSectionSize(25)
            verticalHeader.setSectionResizeMode(QtWidgets.QHeaderView.ResizeMode.Fixed)

        # Set other table view properties
        self.ui.tableView.setSortingEnabled(False)
        self.ui.tableView.setVerticalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)
        self.ui.tableView.setHorizontalScrollMode(QtWidgets.QAbstractItemView.ScrollMode.ScrollPerPixel)

        # Set column widths
        self.ui.tableView.setColumnWidth(0, 50)  # #
        self.ui.tableView.setColumnWidth(1, 75)  # Protocol
        self.ui.tableView.setColumnWidth(2, 150)  # Source
        self.ui.tableView.setColumnWidth(3, 150)  # Destination
        self.ui.tableView.setColumnWidth(4, 150)  # Operation
        self.ui.tableView.setColumnWidth(5, 75)  # Response

    def flows_received(self, agent_flows: list[AgentFlow]):
        flows = [Flow.from_agent_flow(af) for af in agent_flows]
        self.table_model.add_flows(flows)
