from typing import Callable, OrderedDict
from sqlalchemy import create_engine, Connection, text
import sqlalchemy

MigrationSet = OrderedDict[str, list[Callable[[Connection], None]]]

def init_db() -> Connection:
    engine = create_engine('sqlite:///tmp.db')
    conn = engine.connect()
    return conn

def run_migrations(conn: Connection, migrations: MigrationSet):
    try:
        result = conn.execute(text("SELECT * FROM app_version;"))
        rows = result.fetchall()
        if len(rows) != 1:
            print("ERROR wrong number of wrongs in app_version table")
            old_version = '0.0.0'
        else:
            old_version = rows[0][0]
    except sqlalchemy.exc.OperationalError:
        old_version = '0.0.0'

    latest_version = old_version
    old_version_seen = False
    for version, migrations2 in migrations.items():
        if old_version != '0.0.0' and version == old_version:
            old_version_seen = True

        if old_version != '0.0.0' and not old_version_seen:
            print("Skipping version:", version)
            continue

        if old_version == version:
            print("Skipping version:", version)
            continue

        print("Running migrations for version:", version)
        latest_version = version

        # TODO: Make these all run in a single transaction
        for migrate in migrations2:
            migrate(conn)

    conn.execute(text("UPDATE app_version SET version = :version"), {"version": latest_version})
