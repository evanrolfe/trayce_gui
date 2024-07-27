import typing
from PySide6 import QtCore
from network.widgets.containers_table_model import IndexArg
from network.models.flow import Flow


class FlowsTableModel(QtCore.QAbstractTableModel):
    flows: list[Flow]

    def __init__(self, parent: typing.Optional[QtCore.QObject] = None):
        super().__init__(parent)
        self.columns = ["#", "Protocol", "Destination", "Operation", "Path", "Response"]
        self.flows = []

    def set_flows(self, flows: list[Flow]):
        self.flows = flows
        self.layoutChanged.emit()

    def add_flows(self, flows: list[Flow]):
        for flow in flows:
            self.__add_flow(flow)
        print("Total flows:", len(self.flows))
        self.layoutChanged.emit()

    def __add_flow(self, flow: Flow):
        if flow.is_request():
            print("Added request flow ", flow.uuid)
            self.flows.append(flow)
            return

        matching_request_flows = [f for f in self.flows if f.uuid == flow.uuid]
        if len(matching_request_flows) > 0:
            print("Found matching request flow for", flow.uuid)
            matching_request_flows[0].add_response(flow)
        else:
            print("No matching request flow found!", flow.uuid)

    def get_flow(self, index: QtCore.QModelIndex) -> typing.Optional[Flow]:
        if not index.isValid():
            return None

        if index.row() > len(self.flows):
            return None

        return self.flows[index.row()]

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
