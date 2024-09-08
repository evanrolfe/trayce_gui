import os
from collections import OrderedDict
from sqlalchemy import text
from support import example_migrations

from db_migrate import init_db, run_migrations, MigrationSet

migrations1: MigrationSet = OrderedDict()
migrations1['1.0.0'] = [example_migrations.migrate_v1_0_0_init_schema, example_migrations.migrate_v1_0_0_two]
migrations1['1.0.1'] = [example_migrations.migrate_v1_0_1_three, example_migrations.migrate_v1_0_1_four]

migrations2: MigrationSet = OrderedDict()
migrations2['1.0.0'] = [example_migrations.migrate_v1_0_0_init_schema, example_migrations.migrate_v1_0_0_two]
migrations2['1.0.1'] = [example_migrations.migrate_v1_0_1_three, example_migrations.migrate_v1_0_1_four]
migrations2['1.0.2'] = [example_migrations.migrate_v1_0_2_five]

def describe_migrations():
    def running_migrations_on_a_new_db():  # type: ignore
        db_path = './tmp.db'
        if os.path.exists(db_path):
            os.remove(db_path)

        conn = init_db()
        run_migrations(conn, migrations2)

        # Check the version is correct
        result = conn.execute(text("SELECT * FROM app_version;"))
        rows = result.fetchall()
        assert len(rows) == 1
        assert rows[0][0] == "1.0.2"

        # Check all migrations have been ran
        result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table';"))

        # Fetch and print all table names
        table_names = [r[0] for r in result.fetchall()]
        assert len(table_names) == 7
        assert 'one' in table_names
        assert 'two' in table_names
        assert 'three' in table_names
        assert 'four' in table_names
        assert 'five' in table_names

    def running_migrations_from_1_to_2():  # type: ignore
        db_path = './tmp.db'
        if os.path.exists(db_path):
            os.remove(db_path)
        conn = init_db()

        # -------------------------------------------
        # Run migration set #1
        # -------------------------------------------
        run_migrations(conn, migrations1)

        # Check the version is correct
        result = conn.execute(text("SELECT * FROM app_version;"))
        rows = result.fetchall()
        assert len(rows) == 1
        assert rows[0][0] == "1.0.1"

        # Check all migrations have been ran
        result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table';"))

        # Fetch and print all table names
        table_names = [r[0] for r in result.fetchall()]
        assert len(table_names) == 6
        assert 'one' in table_names
        assert 'two' in table_names
        assert 'three' in table_names
        assert 'four' in table_names

        # -------------------------------------------
        # Run migration set #2
        # -------------------------------------------
        run_migrations(conn, migrations2)

        # Check the version is correct
        result = conn.execute(text("SELECT * FROM app_version;"))
        rows = result.fetchall()
        assert len(rows) == 1
        assert rows[0][0] == "1.0.2"

        # Check all migrations have been ran
        result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table';"))

        # Fetch and print all table names
        table_names = [r[0] for r in result.fetchall()]
        assert len(table_names) == 7
        assert 'one' in table_names
        assert 'two' in table_names
        assert 'three' in table_names
        assert 'four' in table_names
        assert 'five' in table_names
