from PyQt6 import QtWidgets
from pytestqt.qtbot import QtBot

from editor.editor_page import EditorPage


def test_answer(qtbot: QtBot):
    parent = QtWidgets.QWidget()
    network_page = EditorPage(parent)
    qtbot.addWidget(network_page)

    network_page.show()
    # qtbot.waitExposed(network_page)
    qtbot.wait(3000)

    assert 5 == 5
