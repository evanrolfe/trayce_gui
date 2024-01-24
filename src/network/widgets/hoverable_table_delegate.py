from PySide6 import QtCore, QtGui, QtWidgets

from network.widgets.containers_table_model import IndexArg


class HoverableTableDelegate(QtWidgets.QStyledItemDelegate):
    HOVER_COLOUR = "#252526"

    hovered_index: QtCore.QModelIndex
    parentTable: QtWidgets.QTableView

    def __init__(self, parent: QtWidgets.QTableView):
        super(HoverableTableDelegate, self).__init__(parent)
        self.parentTable = parent
        self.hovered_index = QtCore.QModelIndex()

    def highlight_index(self, index: QtCore.QModelIndex):
        self.hovered_index = index
        viewport = self.parentTable.viewport()
        if viewport:
            viewport.update()

    def initStyleOption(self, option: QtWidgets.QStyleOptionViewItem, index: IndexArg):
        super().initStyleOption(option, index)
        if option and self.hovered_index.row() == index.row():
            option.backgroundBrush = QtGui.QBrush(QtGui.QColor(self.HOVER_COLOUR))  # type:ignore
