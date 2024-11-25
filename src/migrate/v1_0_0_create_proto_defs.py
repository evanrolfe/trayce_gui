from sqlalchemy import Connection, text

def migrate_v1_0_0_create_proto_defs(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS proto_defs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        raw BLOB NOT NULL,
        created_at TEXT NOT NULL
    );
    """
    for statmt in sql.split(";"):
        conn.execute(text(statmt))
    conn.commit()

