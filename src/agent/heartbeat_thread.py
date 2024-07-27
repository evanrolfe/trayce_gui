import time
from PySide6 import QtCore
from async_proc import AsyncSignals
from agent.agent import Agent


class HeartbeatThread(QtCore.QRunnable):
    signals: AsyncSignals
    agent: Agent

    def __init__(self, agent: Agent):
        super(HeartbeatThread, self).__init__()

        # Store constructor arguments (re-used for processing)
        self.signals = AsyncSignals()
        self.alive = True
        self.agent = agent

    def stop(self):
        print("Heartbeat check stopping")
        self.alive = False

    def run(self):
        while self.alive:
            self.agent.check_heartbeat()
            time.sleep(0.25)
