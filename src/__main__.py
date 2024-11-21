import os
import sys
from PySide6 import QtCore
from PySide6.QtWidgets import QApplication
from db import Database
from main_window import MainWindow
from utils import get_app_path


def main():
    app = QApplication(sys.argv)

    root_path = get_app_path()
    assets_path = root_path.joinpath("assets")
    print("root_path=", root_path)
    QtCore.QDir.addSearchPath("assets", str(assets_path))

    tmp_db_path = 'tmp.db'
    if os.path.isfile(tmp_db_path):
        print(f'[Gui] found existing db at {tmp_db_path}, deleting.')
        os.remove(tmp_db_path)

    db_path = tmp_db_path

    # Create singleton database class
    Database("sqlite:///"+db_path)

    main_window = MainWindow(assets_path)
    main_window.show()
    app.aboutToQuit.connect(main_window.about_to_quit)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
