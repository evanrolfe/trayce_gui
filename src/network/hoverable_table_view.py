import typing

from PyQt6 import QtCore, QtGui, QtWidgets

from network.hoverable_table_delegate import HoverableTableDelegate


class HoverableTableView(QtWidgets.QTableView):
    hover_index_changed = QtCore.pyqtSignal(object)

    def __init__(self, parent: typing.Optional[QtWidgets.QWidget] = None):
        super(HoverableTableView, self).__init__(parent)
        self.hover_index = None

        # Make table hoverable
        delegate = HoverableTableDelegate(self)
        self.setMouseTracking(True)
        self.setItemDelegate(delegate)
        self.hover_index_changed.connect(delegate.highlight_index)

    def mouseMoveEvent(self, e: typing.Optional[QtGui.QMouseEvent]):
        if not e:
            return
        index = self.indexAt(e.pos())

        if index != self.hover_index:
            self.hover_index = index
            self.hover_index_changed.emit(self.hover_index)

    def leaveEvent(self, a0: typing.Optional[QtCore.QEvent]):
        if self.hover_index is not None:
            self.hover_index = QtCore.QModelIndex()  # blank index
            self.hover_index_changed.emit(self.hover_index)
