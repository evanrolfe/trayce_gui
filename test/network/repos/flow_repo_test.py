
from network.models.flow import Flow
from network.repos.flow_repo import FlowRepo
from google.protobuf.reflection import ParseMessage
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.message import DecodeError

from helpers import hex_dump_to_bytes

message_hex = """00000000  00 00 00 04 01 00 00 00  00 00 00 52 01 04 00 00  |...........R....|
00000010  00 01 83 86 45 9c 60 75  99 7d f6 0f d1 0b 0c c5  |....E..u.}......|
00000020  a9 2c 6e 2d 52 5e 3d 49  19 aa 2d 88 d5 1a 0b 67  |.,n-R^=I..-....g|
00000030  72 c9 41 8c 0b a2 5c 2e  ae 05 d9 b8 d8 00 d8 7f  |r.A...\.........|
00000040  5f 8b 1d 75 d0 62 0d 26  3d 4c 4d 65 64 7a 8a 9a  |_..u.b.&=LMedz..|
00000050  ca c8 b4 c7 60 2b b8 da  e0 40 02 74 65 86 4d 83  |.....+...@.te.M.|
00000060  35 05 b1 1f 00 00 30 00  01 00 00 00 01 00 00 00  |5.....0.........|
00000070  00 2b 0a 29 0a 04 31 32  33 34 12 06 75 62 75 6e  |.+.)..1234..ubun|
00000080  74 75 1a 0a 31 37 32 2e  30 2e 31 2e 31 39 22 04  |tu..172.0.1.19".|
00000090  65 76 61 6e 2a 07 72 75  6e 6e 69 6e 67           |evan*.running|"""

# def describe_flow_repo():
#     # def saving_a_flow(database, cleanup_database):  # type: ignore
#     #     flow = Flow(
#     #         uuid="1234",
#     #         source_addr="192.168.0.1",
#     #         dest_addr="192.168.0.2",
#     #         l4_protocol="tcp",
#     #         l7_protocol="http",
#     #         request_raw=b"GET /index.html HTTP/1.1",
#     #         response_raw=b"",
#     #         request=None,
#     #         response=None
#     #     )
#     #     FlowRepo().save(flow)

#     def my_test():
#         # Deserialize the descriptor
#         file_descriptor_proto = descriptor_pb2.FileDescriptorProto()
#         file_descriptor_proto.ParseFromString(serialized_descriptor)

#         ParseMessage("", hex_dump_to_bytes(message_hex))
#         assert 1 == 1
