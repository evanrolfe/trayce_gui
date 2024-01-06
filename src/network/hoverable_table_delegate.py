import typing
from PyQt6 import QtWidgets, QtCore, QtGui


class HoverableTableDelegate(QtWidgets.QStyledItemDelegate):
    HOVER_COLOUR = "#252526"

    hovered_index: QtCore.QModelIndex
    parentTable: QtWidgets.QTableView

    def __init__(self, parent: QtWidgets.QTableView):
        super(HoverableTableDelegate, self).__init__(parent)
        self.parentTable = parent
        self.hovered_index = QtCore.QModelIndex()
        self.prev_hovered_index = QtCore.QModelIndex()

    def highlight_index(self, index: QtCore.QModelIndex):
        self.hovered_index = index
        viewport = self.parentTable.viewport()
        if viewport:
            viewport.update()

    def initStyleOption(self, option: typing.Optional[QtWidgets.QStyleOptionViewItem], index: QtCore.QModelIndex):
        super().initStyleOption(option, index)

        if option and self.hovered_index.row() == index.row():
            option.backgroundBrush = QtGui.QBrush(QtGui.QColor(self.HOVER_COLOUR))
