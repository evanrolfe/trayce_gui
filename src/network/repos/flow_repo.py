import json
from typing import Any
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, LargeBinary, insert, insert_sentinel
from network.models.flow import Flow
from shared.base_repo import BaseRepo
from shared.model import Model

class FlowRepo(BaseRepo):
    table = Table(
        'flows',
        MetaData(),
        Column('id', Integer, primary_key=True),
        Column('uuid', String()),
        Column('source_addr', String()),
        Column('dest_addr', String()),
        Column('l4_protocol', String()),
        Column('l7_protocol', String()),
        Column('request_raw', LargeBinary()),
        Column('response_raw', LargeBinary()),
    )

    def save(self, flow: Flow):
        values = flow.values_for_db()
        insert_stmt = insert(self.table).values(values)

        self.conn.execute(insert_stmt)
        self.conn.commit()

