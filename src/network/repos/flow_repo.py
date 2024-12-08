import json
from typing import Any
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, LargeBinary, desc, select
from sqlalchemy.dialects.sqlite import insert
from network.models.flow import Flow
from network.models.flow_request import FlowRequest
from network.models.grpc_request import GrpcRequest
from network.models.grpc_response import GrpcResponse
from network.models.http_request import HttpRequest
from network.models.http_response import HttpResponse
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
        Column('created_at', String()),
    )

    # save() does an upsert based on the uuid, since the agent sends over a flow with a request and then a flow with a response
    # both of which have the same uuid value set
    def save(self, flow: Flow):
        values = flow.values_for_db()
        upsert_stmt = insert(self.table).values(values).on_conflict_do_update(
            index_elements=['uuid'],
            set_=dict(response_raw=values['response_raw']),
        )
        result = self.conn.execute(upsert_stmt)

        self.conn.commit()
        flow.id = result.lastrowid

    def find_all(self) -> list[Flow]:
        select_stmt = select(self.table).order_by(desc(self.table.c.id))
        results = self.conn.execute(select_stmt).fetchall()

        flows = []
        for row in results:
            l7_protocol = row[5]
            if l7_protocol=='http':
                # Parse request
                request_raw = row[6]
                request = HttpRequest.from_json(request_raw)

                # Parse response (if it exists)
                response_raw = row[7]
                response = None
                if len(response_raw) > 0:
                    response=HttpResponse.from_json(response_raw)

                # Parse to Flow
                flow = Flow(
                    uuid=row[1],
                    source_addr=row[2],
                    dest_addr=row[3],
                    l4_protocol=row[4],
                    l7_protocol=row[5],
                    request_raw=request_raw,
                    response_raw=response_raw,
                    request=request,
                    response=response,
                )
                flow.id = row[0]
                flow.created_at = row[8]
                flows.append(flow)

            elif l7_protocol=='grpc':
                # Parse request
                request_raw = row[6]
                request = GrpcRequest.from_json(request_raw)

                # Parse response (if it exists)
                response_raw = row[7]
                response=None
                if len(response_raw) > 0:
                    response=GrpcResponse.from_json(response_raw)

                flow = Flow(
                    uuid=row[1],
                    source_addr=row[2],
                    dest_addr=row[3],
                    l4_protocol=row[4],
                    l7_protocol=row[5],
                    request_raw=request_raw,
                    response_raw=response_raw,
                    request=request,
                    response=response,
                )
                flow.id = row[0]
                flow.created_at = row[8]
                flows.append(flow)

        return flows

    # SELECT * FROM flows WHERE JSON_EXTRACT(request_raw, '$.method') = 'GET';
