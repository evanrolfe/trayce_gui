from sqlalchemy import Connection, text

def migrate_v1_0_0_init_schema(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS app_version(
        version TEXT NOT NULL
    );
    INSERT INTO app_version VALUES ("1.0.0");
    """
    for statmt in sql.split(";"):
        conn.execute(text(statmt))
