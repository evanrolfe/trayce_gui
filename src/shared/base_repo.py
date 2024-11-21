import json
import time
import sqlite3
from typing import Any, Optional
from sqlalchemy import create_engine, Connection, text

from db import Database

class BaseRepo:
    conn: Connection

    def __init__(self):
        self.conn = Database.get_instance().conn
