from PySide6 import QtCore


class EventBusGlobal(QtCore.QObject):
    # Signals
    intercept_containers = QtCore.Signal(list)
    flows_received = QtCore.Signal(list)

    # Singleton method stuff:
    __instance = None

    @staticmethod
    def get():
        # Static access method.
        if EventBusGlobal.__instance is None:
            return EventBusGlobal()
        return EventBusGlobal.__instance

    def __init__(self):
        # Put constructor code here
        super(EventBusGlobal, self).__init__()

        # Virtually private constructor.
        if EventBusGlobal.__instance is None:
            EventBusGlobal.__instance = self

    # /Singleton method stuff
