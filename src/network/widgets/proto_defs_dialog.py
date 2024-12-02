import os
import typing
from PySide6 import QtCore, QtWidgets
from network.event_bus import EventBus
from network.models.proto_def import ProtoDef
from network.repos.proto_def_repo import ProtoDefRepo
from network.ui.ui_proto_defs_dialog import Ui_ProtoDefsDialog
from agent.api_pb2 import Container as AgentContainer
from network.widgets.proto_defs_table_model import ProtoDefsTableModel


class ProtoDefsDialog(QtWidgets.QDialog):
    app_running: bool
    agent_running: bool
    table_model: ProtoDefsTableModel

    def __init__(self, *args: typing.Any, **kwargs: typing.Any):
        super(ProtoDefsDialog, self).__init__(*args, **kwargs)

        self.ui = Ui_ProtoDefsDialog()
        self.ui.setupUi(self)
        self.setModal(True)

        self.table_model = ProtoDefsTableModel()
        self.ui.protoDefsTable.setModel(self.table_model)

        self.ui.closeButton.clicked.connect(self.close)
        self.ui.uploadButton.clicked.connect(self.upload_clicked)

    def show(self):
        proto_defs = ProtoDefRepo().find_all()
        self.table_model.set_proto_defs(proto_defs)
        super().show()

    def upload_clicked(self):
        file = QtWidgets.QFileDialog.getOpenFileName(
            self,
            "Open .proto file",
            "~/",
            "Protobuf files (*.proto)"
        )

        file_path = file[0]
        file_name = os.path.basename(file_path)
        proto_def = ProtoDefRepo().upload(file_name, file_path)

        print("Uploaded proto def:", file_path, proto_def.id)
        EventBus.get().proto_defs_changed.emit()

    def about_to_quit(self):
        self.app_running = False
