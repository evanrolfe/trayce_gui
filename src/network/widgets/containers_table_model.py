import typing
from PySide6 import QtCore
from network.models.container import Container

IndexArg = QtCore.QModelIndex | QtCore.QPersistentModelIndex


class ContainersTableModel(QtCore.QAbstractTableModel):
    containers: list[Container]

    def __init__(self, parent: typing.Optional[QtCore.QObject] = None):
        super().__init__(parent)
        self.columns = ["ID", "Image", "IP", "Name", "Status", "Intercepted?"]
        self.containers = []

    def table_cell_clicked(self, index: QtCore.QModelIndex):
        if index.row() > len(self.containers):
            return None

        container = self.containers[index.row()]

        if index.column() == 5 and not container.is_trayce_agent():
            container.intercepted = not container.intercepted
            self.dataChanged.emit(index, index)

    def set_containers(self, containers: list[Container]):
        self.containers = containers
        self.layoutChanged.emit()

    def merge_containers(self, new_containers: list[Container]):
        # Add new containers
        for new_container in new_containers:
            if new_container.short_id not in [c.short_id for c in self.containers]:
                print("New container", new_container.short_id)
                self.containers.append(new_container)

        # Remove deleted ones
        for old_container in self.containers:
            if old_container.short_id not in [c.short_id for c in new_containers]:
                print("Removed container", old_container.short_id)
                self.containers.remove(old_container)

        self.layoutChanged.emit()

    def flags(self, index: IndexArg) -> QtCore.Qt.ItemFlag:
        flags = super().flags(index)

        if index.row() > len(self.containers):
            return flags

        if index.column() == 5:
            flags |= QtCore.Qt.ItemFlag.ItemIsUserCheckable

        return flags

    def rowCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.containers)

    def columnCount(self, parent: IndexArg = QtCore.QModelIndex()):
        return len(self.columns)

    def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = 0) -> typing.Any:
        if role == QtCore.Qt.ItemDataRole.DisplayRole and orientation == QtCore.Qt.Orientation.Horizontal:
            return self.columns[section]

    def data(self, index: IndexArg, role: int = 0) -> typing.Any:
        if not index.isValid():
            return None

        if index.row() > len(self.containers):
            return None

        container = self.containers[index.row()]

        if role == QtCore.Qt.ItemDataRole.CheckStateRole:
            if index.column() == 5:
                if container.intercepted and not container.is_trayce_agent():
                    return QtCore.Qt.CheckState.Checked
                else:
                    return QtCore.Qt.CheckState.Unchecked

        if role == QtCore.Qt.ItemDataRole.DisplayRole:
            if index.column() == 0:
                return str(container.short_id)
            elif index.column() == 1:
                return str(container.image)
            elif index.column() == 2:
                return str(container.ip)
            elif index.column() == 3:
                return str(container.name)
            elif index.column() == 4:
                return str(container.status)
            elif index.column() == 5:
                return "yes" if container.intercepted else "no"

    # def setData(
    #     self,
    #     index: QtCore.QModelIndex,
    #     value: typing.Any,
    #     role: int = QtCore.Qt.ItemDataRole.EditRole,
    # ) -> bool:
    #     if role == QtCore.Qt.ItemDataRole.CheckStateRole and index.column() == 5:
    #         container = self.containers[index.row()]

    #         check_state = QtCore.Qt.CheckState(value)
    #         checked = check_state == QtCore.Qt.CheckState.Checked
    #         container.intercepted = checked
    #         return True

    #     return False
