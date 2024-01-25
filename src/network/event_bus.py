from PySide6 import QtCore


class EventBus(QtCore.QObject):
    # Signals
    intercept_containers = QtCore.Signal(list)
    flows_received = QtCore.Signal(list)

    # UI interaction signals
    containers_btn_clicked = QtCore.Signal()

    # Singleton method stuff:
    __instance = None

    @staticmethod
    def get():
        # Static access method.
        if EventBus.__instance is None:
            return EventBus()
        return EventBus.__instance

    def __init__(self):
        # Put constructor code here
        super(EventBus, self).__init__()

        # Virtually private constructor.
        if EventBus.__instance is None:
            EventBus.__instance = self

    # /Singleton method stuff
