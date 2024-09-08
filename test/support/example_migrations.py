from sqlalchemy import Connection, text

def migrate_v1_0_0_init_schema(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS one(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS app_version(
        version TEXT NOT NULL
    );
    INSERT INTO app_version VALUES ("1.0.0");
    """
    for statmt in sql.split(";"):
        conn.execute(text(statmt))

def migrate_v1_0_0_two(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS two(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
    )
    """
    conn.execute(text(sql))

def migrate_v1_0_1_three(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS three(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
    )
    """
    conn.execute(text(sql))

def migrate_v1_0_1_four(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS four(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
    )
    """
    conn.execute(text(sql))

def migrate_v1_0_2_five(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS five(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
    )
    """
    conn.execute(text(sql))
