import sys
from PyQt6 import QtCore
from PyQt6.QtWidgets import QApplication
from main_window import MainWindow
from utils import get_app_path


def main():
    app = QApplication(sys.argv)

    root_path = get_app_path()
    assets_path = root_path.joinpath("assets")
    print("root_path=", root_path)
    QtCore.QDir.addSearchPath("assets", str(assets_path))

    main_window = MainWindow(assets_path)
    main_window.show()
    app.aboutToQuit.connect(main_window.about_to_quit)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
