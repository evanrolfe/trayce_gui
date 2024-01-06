import typing
from PyQt6 import QtCore


class FlowsTableModel(QtCore.QAbstractTableModel):
    def __init__(self, parent: typing.Optional[QtCore.QObject] = None):
        super().__init__(parent)
        self.columns = ["#", "Protocol", "Source", "Destination", "Operation", "Response"]

    def rowCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()):
        return 5000

    def columnCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()):
        return len(self.columns)

    def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = 0) -> typing.Any:
        if role == QtCore.Qt.ItemDataRole.DisplayRole and orientation == QtCore.Qt.Orientation.Horizontal:
            return self.columns[section]

        return QtCore.QVariant()

    def data(self, index: QtCore.QModelIndex, role: int = 0) -> typing.Any:
        if role == QtCore.Qt.ItemDataRole.DisplayRole:
            return f"Row {index.row() + 1}"

        return QtCore.QVariant()
