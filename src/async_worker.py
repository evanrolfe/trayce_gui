from PyQt6 import QtCore


class WorkerSignals(QtCore.QObject):
    finished = QtCore.pyqtSignal()
    error = QtCore.pyqtSignal(tuple)
    result = QtCore.pyqtSignal(object)

    # Only used by FuzzHttpRequest
    response_received = QtCore.pyqtSignal(object)


# TODO
# class AsyncWorker(QtCore.QRunnable):
#     def __init__(self, fn, *args, **kwargs):
#         super(AsyncWorker, self).__init__()

#         # Store constructor arguments (re-used for processing)
#         self.fn = fn
#         self.args = args
#         self.kwargs = kwargs
#         self.signals = WorkerSignals()
#         self.alive = True

#     def kill(self):
#         self.alive = False

#     def run(self):
#         # Retrieve args/kwargs here; and fire processing using them
#         try:
#             result = self.fn(self.signals)

#             # Hacky way of allow us to "cancel" a worker
#             if not self.alive:
#                 return
#         except:  # noqa: E722
#             exctype, value = sys.exc_info()[:2]
#             self.signals.error.emit((exctype, value, traceback.format_exc()))
#         else:
#             # Return the result of the processing
#             self.signals.result.emit(result)
#         finally:
#             self.signals.finished.emit()
