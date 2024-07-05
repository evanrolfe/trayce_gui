from typing import Union
from PySide6 import QtCore, QtGui, QtWidgets

from network.utils import get_method_colour, get_status_colour
from network.widgets.containers_table_model import IndexArg
from network.widgets.flows_table_model import FlowsTableModel


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

    def paint(
        self,
        painter: QtGui.QPainter,
        option: QtWidgets.QStyleOptionViewItem,
        index: Union[QtCore.QModelIndex, QtCore.QPersistentModelIndex],
    ):
        super().paint(painter, option, index)

        model: FlowsTableModel = index.model()  # type: ignore
        value = model.get_value(index)  # type:ignore

        x = self.parentTable.columnViewportPosition(index.column())

        # Method column
        if index.column() == 3:
            color = get_method_colour(str(value))

            label = QtWidgets.QLabel(value)
            label.setAutoFillBackground(True)
            label.setObjectName("mylabel")
            label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
            label.setMinimumWidth(50)
            label.setStyleSheet(f"color: {color}; background: transparent;")

            x_offest = 0
            y_offset = 5
            painter.drawPixmap(x + x_offest, option.rect.y() + y_offset, label.grab())  # type: ignore

        # Response status column
        elif index.column() == 5:
            if value is None or value == "":
                return

            bg_color = get_status_colour(int(value))

            label = QtWidgets.QLabel(str(value))
            label.setAutoFillBackground(True)
            label.setObjectName("responseStatusLabelTable")
            label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
            label.setMinimumWidth(30)
            label.setStyleSheet(f"background-color: {bg_color};")

            x_offest = 0
            y_offset = 5
            painter.drawPixmap(x + x_offest, option.rect.y() + y_offset, label.grab())  # type:ignore
