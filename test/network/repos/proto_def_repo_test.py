
from network.models.flow import Flow
from network.repos.flow_repo import FlowRepo
from google.protobuf.reflection import ParseMessage
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.message import DecodeError

from support.helpers import hex_dump_to_bytes
from network.repos.proto_def_repo import ProtoDefRepo

def describe_proto_def_repo():
    def uploading_a_proto_file(database, cleanup_database):
        proto_def = ProtoDefRepo().upload("test", "src/agent/api.proto")
        assert proto_def.id > 0

    def fetching_a_proto_file(database, cleanup_database):
        proto_def = ProtoDefRepo().upload("test", "src/agent/api.proto")
        proto_def2 = ProtoDefRepo().find_by_id(proto_def.id)

        assert proto_def2 is not None
        assert proto_def.id == proto_def2.id
        assert proto_def.name == "test"
        assert proto_def.file_path == "src/agent/api.proto"

    def fetching_multiple_proto_file(database, cleanup_database):
        proto_def1 = ProtoDefRepo().upload("testA", "src/agent/api.proto")
        proto_def2 = ProtoDefRepo().upload("testB", "src/agent/api.proto")

        result = ProtoDefRepo().find_all()

        assert len(result) == 2
        assert result[0].id == proto_def1.id
        assert result[1].id == proto_def2.id
