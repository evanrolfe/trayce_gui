import os
import sqlite3
from typing import OrderedDict
from sqlalchemy import create_engine, Connection, text
from db_migrate import run_migrations
from migrate.v1_0_0_create_flows import migrate_v1_0_0_create_flows
from migrate.v1_0_0_init_schema import migrate_v1_0_0_init_schema
from db_migrate import MigrationSet, run_migrations

migrations: MigrationSet = OrderedDict()
migrations['1.0.0'] = [migrate_v1_0_0_init_schema, migrate_v1_0_0_create_flows]

class Database:
    # Singleton method stuff:
    __instance = None

    conn: Connection

    @staticmethod
    def get_instance():
        # Static access method.
        if Database.__instance is None:
            raise Exception("Database class is a singleton!")
        return Database.__instance

    def __init__(self, db_path):
        self.db_path = db_path
        self.connect()
        self.migrate()

        # Virtually private constructor.
        if Database.__instance is not None:
            raise Exception("Database class is a singleton!")
        else:
            Database.__instance = self
    # /Singleton method stuff

    def connect(self):
        engine = create_engine(self.db_path)
        self.conn = engine.connect()

    def migrate(self):
        run_migrations(self.conn, migrations)

    def close(self):
        self.conn.close()
