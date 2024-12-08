
import uuid
from network.models.flow import Flow
from network.models.grpc_request import GrpcRequest
from network.models.grpc_response import GrpcResponse
from network.models.http_request import HttpRequest
from network.models.http_response import HttpResponse
from network.repos.flow_repo import FlowRepo
from google.protobuf.reflection import ParseMessage
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.message import DecodeError
from typing import cast

from support.helpers import hex_dump_to_bytes

message_hex = """00000000  00 00 00 04 01 00 00 00  00 00 00 52 01 04 00 00  |...........R....|
00000010  00 01 83 86 45 9c 60 75  99 7d f6 0f d1 0b 0c c5  |....E..u.}......|
00000020  a9 2c 6e 2d 52 5e 3d 49  19 aa 2d 88 d5 1a 0b 67  |.,n-R^=I..-....g|
00000030  72 c9 41 8c 0b a2 5c 2e  ae 05 d9 b8 d8 00 d8 7f  |r.A.............|
00000040  5f 8b 1d 75 d0 62 0d 26  3d 4c 4d 65 64 7a 8a 9a  |_..u.b.&=LMedz..|
00000050  ca c8 b4 c7 60 2b b8 da  e0 40 02 74 65 86 4d 83  |.....+...@.te.M.|
00000060  35 05 b1 1f 00 00 30 00  01 00 00 00 01 00 00 00  |5.....0.........|
00000070  00 2b 0a 29 0a 04 31 32  33 34 12 06 75 62 75 6e  |.+.)..1234..ubun|
00000080  74 75 1a 0a 31 37 32 2e  30 2e 31 2e 31 39 22 04  |tu..172.0.1.19".|
00000090  65 76 61 6e 2a 07 72 75  6e 6e 69 6e 67           |evan*.running|"""

def describe_flow_repo():
    def saving_an_http_flow(database, cleanup_database):  # type: ignore
        req = HttpRequest(
            method="GET",
            path="/",
            host="172.17.0.3:3001",
            http_version="1.1",
            headers={},
            body="hello world",
        )
        flow = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="http",
            request_raw=req.to_json().encode(),
            response_raw=bytes(),
            request=req,
            response=None,
        )
        FlowRepo().save(flow)

        assert flow.id > 0

    def saving_a_grpc_flow_request(database, cleanup_database):
        payload = bytes([0x0a,0x29,0x0a,0x04,0x31,0x32,0x33,0x34,0x12,0x06,0x75,0x62,0x75,0x6e,0x74,0x75,0x1a,0x0a,0x31,0x37,0x32,0x2e,0x30,0x2e,0x31,0x2e,0x31,0x39,0x22,0x04,0x65,0x76,0x61,0x6e,0x2a,0x07,0x72,0x75,0x6e,0x6e,0x69,0x6e,0x67])
        req = GrpcRequest(
            path="/api.TrayceAgent/SendContainersObserved",
            headers={},
            body=payload,
        )
        flow = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="grpc",
            request_raw=req.to_json().encode(),
            response_raw=bytes(),
            request=req,
            response=None,
        )
        FlowRepo().save(flow)

        assert flow.id > 0

    def saving_a_grpc_flow_request_and_response(database, cleanup_database):
        payload_req = bytes([0x0a,0x29,0x0a,0x04,0x31,0x32,0x33,0x34,0x12,0x06,0x75,0x62,0x75,0x6e,0x74,0x75,0x1a,0x0a,0x31,0x37,0x32,0x2e,0x30,0x2e,0x31,0x2e,0x31,0x39,0x22,0x04,0x65,0x76,0x61,0x6e,0x2a,0x07,0x72,0x75,0x6e,0x6e,0x69,0x6e,0x67])
        req = GrpcRequest(
            path="/api.TrayceAgent/SendContainersObserved",
            headers={},
            body=payload_req,
        )
        payload_resp=bytes([0x00, 0x00, 0x00, 0x00, 0x0a, 0x0a, 0x08, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x20])
        resp = GrpcResponse(
            headers={},
            body=payload_resp,
        )
        flow = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="grpc",
            request_raw=req.to_json().encode(),
            response_raw=resp.to_json().encode(),
            request=req,
            response=resp,
        )
        FlowRepo().save(flow)

        assert flow.id > 0

    def fetching_multiple_grpc_flows(database, cleanup_database):  # type: ignore
        payload = bytes([0x0a,0x29,0x0a,0x04,0x31,0x32,0x33,0x34,0x12,0x06,0x75,0x62,0x75,0x6e,0x74,0x75,0x1a,0x0a,0x31,0x37,0x32,0x2e,0x30,0x2e,0x31,0x2e,0x31,0x39,0x22,0x04,0x65,0x76,0x61,0x6e,0x2a,0x07,0x72,0x75,0x6e,0x6e,0x69,0x6e,0x67])
        req = GrpcRequest(
            path="/api.TrayceAgent/SendContainersObserved",
            headers={},
            body=payload,
        )
        flow1 = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="grpc",
            request_raw=req.to_json().encode(),
            response_raw=bytes(),
            request=req,
            response=None,
        )
        payload_resp=bytes([0x00, 0x00, 0x00, 0x00, 0x0a, 0x0a, 0x08, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x20])
        resp = GrpcResponse(
            headers={},
            body=payload_resp,
        )
        flow2 = Flow(
            uuid=flow1.uuid,
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="grpc",
            request_raw=req.to_json().encode(),
            response_raw=resp.to_json().encode(),
            request=req,
            response=resp,
        )
        FlowRepo().save(flow1)
        FlowRepo().save(flow2)

        flows = FlowRepo().find_all()
        assert len(flows) == 1
        assert flows[0].uuid == flow1.uuid
        assert flows[0].source_addr=="192.168.0.1"
        assert flows[0].dest_addr=="192.168.0.2"
        assert flows[0].l4_protocol=="tcp"
        assert flows[0].l7_protocol=="grpc"
        # assert flows[0].created_at > 0

        grpc_request = cast(GrpcRequest, flows[0].request)
        assert grpc_request.path == "/api.TrayceAgent/SendContainersObserved"
        assert grpc_request.body == payload

        grpc_response = cast(GrpcResponse, flows[0].response)
        assert grpc_response.body == payload_resp

    def fetching_multiple_http_flows(database, cleanup_database):  # type: ignore
        req = HttpRequest(
            method="GET",
            path="/",
            host="172.17.0.3:3001",
            http_version="1.1",
            headers={},
            body="hello world",
        )
        flow1 = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="http",
            request_raw=req.to_json().encode(),
            response_raw=bytes(),
            request=req,
            response=None,
        )
        resp = HttpResponse(
            status=200,
            status_msg="OK",
            http_version="1.1",
            headers={},
            body="hello",
        )
        flow2 = Flow(
            uuid=str(uuid.uuid4()),
            source_addr="192.168.0.1",
            dest_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="http",
            request_raw=req.to_json().encode(),
            response_raw=resp.to_json().encode(),
            request=req,
            response=resp,
        )
        FlowRepo().save(flow1)
        FlowRepo().save(flow2)

        flows = FlowRepo().find_all()
        assert len(flows) == 2
        assert flows[0].uuid == flow2.uuid
        assert flows[0].source_addr=="192.168.0.1"
        assert flows[0].dest_addr=="192.168.0.2"
        assert flows[0].l4_protocol=="tcp"
        assert flows[0].l7_protocol=="http"
        # assert flow1.created_at > 0

        http_request = cast(HttpRequest, flow1.request)
        assert http_request.path == "/"
        assert http_request.body == "hello world"

        assert flows[1].uuid == flow1.uuid
        assert flows[1].source_addr=="192.168.0.1"
        assert flows[1].dest_addr=="192.168.0.2"
        assert flows[1].l4_protocol=="tcp"
        assert flows[1].l7_protocol=="http"
        # assert flow2.created_at > 0

        http_request = cast(HttpRequest, flow2.request)
        assert http_request.path == "/"
        assert http_request.body == "hello world"

        http_response = cast(HttpResponse, flow2.response)
        assert http_response.body == "hello"
