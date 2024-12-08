import pathlib
import sys
import pytest
from sqlalchemy import text

from PySide6.QtWidgets import QApplication
from main_window import MainWindow
from db import Database

@pytest.fixture(scope="session")
def database():
    database = Database('sqlite:///test.db')
    print("\n[Test] DB Setup")
    yield
    print("[Test] DB Teardown")
    database.close()

@pytest.fixture(scope="function")
def cleanup_database():
    conn = Database.get_instance().conn
    conn.execute(text("DELETE FROM 'flows'"))
    conn.execute(text("DELETE FROM 'proto_defs'"))
    conn.commit()

    yield

@pytest.fixture(scope="function")
def main_window(qapp):
    main_window = MainWindow(pathlib.Path("./assets"))
    yield main_window
    main_window.about_to_quit()
