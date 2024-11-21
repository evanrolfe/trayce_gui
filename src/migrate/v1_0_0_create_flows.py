from sqlalchemy import Connection, text

def migrate_v1_0_0_create_flows(conn: Connection):
    sql = """
    CREATE TABLE IF NOT EXISTS flows(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
	    uuid TEXT NOT NULL UNIQUE,
        source_addr TEXT NOT NULL,
        dest_addr TEXT NOT NULL,
        l4_protocol TEXT NOT NULL,
        l7_protocol TEXT NOT NULL,
        request_raw BLOB NOT NULL ,
        response_raw BLOB
    );
    """
    for statmt in sql.split(";"):
        conn.execute(text(statmt))
    conn.commit()

