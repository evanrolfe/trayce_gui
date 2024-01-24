import typing

# import sys
# import traceback
from PySide6 import QtCore


class AsyncSignals(QtCore.QObject):
    finished = QtCore.Signal()
    error = QtCore.Signal(tuple)
    result = QtCore.Signal(object)


AsyncFunc = typing.Callable[[AsyncSignals], None]


class AsyncProc(QtCore.QRunnable):
    def __init__(self, fn: AsyncFunc):
        super(AsyncProc, self).__init__()

        # Store constructor arguments (re-used for processing)
        self.fn = fn
        self.signals = AsyncSignals()
        self.alive = True

    def kill(self):
        self.alive = False

    def run(self):
        self.fn(self.signals)
        # try:
        #     result = self.fn(self.signals)

        # except:  # noqa: E722
        #     exctype, value = sys.exc_info()[:2]
        #     if self.signals:
        #         self.signals.error.emit((exctype, value, traceback.format_exc()))
        # else:
        #     if self.signals:
        #         self.signals.result.emit(result)
        # finally:
        #     self.signals.finished.emit()
