import sys
from PyQt6 import QtCore
from PyQt6.QtWidgets import QApplication
from main_window import MainWindow


def main():
    app = QApplication(sys.argv)

    # Load assets & styles
    QtCore.QDir.addSearchPath("assets", "src/assets")

    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
