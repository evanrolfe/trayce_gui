import typing
from PySide6 import QtCore
from event_bus_global import EventBusGlobal
from network.repos.flow_repo import FlowRepo
from network.widgets.containers_table_model import IndexArg
from network.models.flow import Flow
from agent.api_pb2 import Flow as AgentFlow
from shared.debounce import debounce

class FlowsTableModel(QtCore.QAbstractTableModel):
    flows: list[Flow]

    def __init__(self, parent: typing.Optional[QtCore.QObject] = None):
        super().__init__(parent)
        self.columns = ["#", "Protocol", "Destination", "Operation", "Path", "Response"]
        self.flows = []
        EventBusGlobal.get().flows_received.connect(self.__receive_flows)
        self.load_flows()

    @debounce(0.2)
    def load_flows(self):
        self.flows = FlowRepo().find_all()
        print("Total flows:", len(self.flows))
        self.layoutChanged.emit()

    def get_flow(self, index: QtCore.QModelIndex) -> typing.Optional[Flow]:
        if not index.isValid():
            return None

        if index.row() > len(self.flows):
            return None

        return self.flows[index.row()]

    def __receive_flows(self, agent_flows: list[AgentFlow]):
        for agent_flow in agent_flows:
            flow = Flow.from_agent_flow(agent_flow)
            FlowRepo().save(flow)

        self.load_flows()

    def rowCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.flows)

    def columnCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.columns)

    def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = 0) -> typing.Any:
        if role == QtCore.Qt.ItemDataRole.DisplayRole and orientation == QtCore.Qt.Orientation.Horizontal:
            return self.columns[section]

    def data(self, index: IndexArg, role: int = 0) -> typing.Any:
        if not index.isValid():
            return None

        if index.row() > len(self.flows):
            return None

        flow = self.flows[index.row()]

        if role == QtCore.Qt.ItemDataRole.DisplayRole:
            row_values = self.flow_to_row_values(flow)
            if index.column() >= len(row_values):
                return ""

            if index.column() in [3]:  # operation / response columns are drawn by the style delegate
                return ""

            return row_values[index.column()]

    def get_value(self, index: QtCore.QModelIndex) -> typing.Optional[str]:
        if not index.isValid():
            return None

        if index.row() > len(self.flows):
            return None

        flow = self.flows[index.row()]
        row_values = self.flow_to_row_values(flow)
        return row_values[index.column()]

    def flow_to_row_values(self, flow: Flow) -> list[str]:
        return [flow.uuid, flow.l7_protocol, flow.destination(), flow.operation(), flow.path(), flow.response_status()]
