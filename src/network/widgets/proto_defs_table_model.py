import typing
from PySide6 import QtCore
from network.models.proto_def import ProtoDef

IndexArg = QtCore.QModelIndex | QtCore.QPersistentModelIndex


class ProtoDefsTableModel(QtCore.QAbstractTableModel):
    proto_defs: list[ProtoDef]

    def __init__(self, parent: typing.Optional[QtCore.QObject] = None):
        super().__init__(parent)
        self.columns = ["Name"]
        self.proto_defs = []

    def set_proto_defs(self, proto_defs: list[ProtoDef]):
        self.proto_defs = proto_defs
        self.layoutChanged.emit()

    def flags(self, index: IndexArg) -> QtCore.Qt.ItemFlag:
        flags = super().flags(index)

        if index.row() > len(self.proto_defs):
            return flags

        return flags

    def rowCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.proto_defs)

    def columnCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.columns)

    def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = 0) -> typing.Any:
        if role == QtCore.Qt.ItemDataRole.DisplayRole and orientation == QtCore.Qt.Orientation.Horizontal:
            return self.columns[section]

    def data(self, index: IndexArg, role: int = 0) -> typing.Any:
        if not index.isValid():
            return None

        if index.row() > len(self.proto_defs):
            return None

        proto_def = self.proto_defs[index.row()]

        if role == QtCore.Qt.ItemDataRole.DisplayRole:
            if index.column() == 0:
                return proto_def.name
