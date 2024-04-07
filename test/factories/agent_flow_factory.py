import typing
from agent import api_pb2
from helpers import hex_dump_to_bytes

request_hex = """00000000  47 45 54 20 2f 20 48 54  54 50 2f 31 2e 31 0d 0a  |GET / HTTP/1.1..|
00000010  48 6f 73 74 3a 20 31 37  32 2e 31 37 2e 30 2e 33  |Host: 172.17.0.3|
00000020  3a 33 30 30 31 0d 0a 55  73 65 72 2d 41 67 65 6e  |:3001..User-Agen|
00000030  74 3a 20 63 75 72 6c 2f  37 2e 38 31 2e 30 0d 0a  |t: curl/7.81.0..|
00000040  41 63 63 65 70 74 3a 20  2a 2f 2a 0d 0a 0d 0a     |Accept: */*....|"""

response_hex = """00000000  48 54 54 50 2f 31 2e 31  20 32 30 30 20 4f 4b 0d  |HTTP/1.1 200 OK.|
00000010  0a 53 65 72 76 65 72 3a  20 57 65 72 6b 7a 65 75  |.Server: Werkzeu|
00000020  67 2f 33 2e 30 2e 31 20  50 79 74 68 6f 6e 2f 33  |g/3.0.1 Python/3|
00000030  2e 31 30 2e 31 32 0d 0a  44 61 74 65 3a 20 54 75  |.10.12..Date: Tu|
00000040  65 2c 20 33 30 20 4a 61  6e 20 32 30 32 34 20 31  |e, 30 Jan 2024 1|
00000050  32 3a 34 32 3a 34 36 20  47 4d 54 0d 0a 43 6f 6e  |2:42:46 GMT..Con|
00000060  74 65 6e 74 2d 54 79 70  65 3a 20 74 65 78 74 2f  |tent-Type: text/|
00000070  68 74 6d 6c 3b 20 63 68  61 72 73 65 74 3d 75 74  |html; charset=ut|
00000080  66 2d 38 0d 0a 43 6f 6e  74 65 6e 74 2d 4c 65 6e  |f-8..Content-Len|
00000090  67 74 68 3a 20 31 32 0d  0a 43 6f 6e 6e 65 63 74  |gth: 12..Connect|
000000a0  69 6f 6e 3a 20 63 6c 6f  73 65 0d 0a 0d 0a 48 65  |ion: close....He|
000000b0  6c 6c 6f 20 57 6f 72 6c  64 21                    |lo World!|"""


class AgentFlowFactory:
    IMAGES = ["ubuntu", "alpine", "scratch", "debian"]

    @classmethod
    def build(cls, **kwargs: typing.Any) -> api_pb2.Flow:
        flow = api_pb2.Flow(
            uuid="1234",
            local_addr="192.168.0.1",
            remote_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="http",
            request=hex_dump_to_bytes(request_hex),
            response=b"",
        )

        for key, value in kwargs.items():
            setattr(flow, key, value)

        return flow

    @classmethod
    def build_response(cls, **kwargs: typing.Any) -> api_pb2.Flow:
        flow = api_pb2.Flow(
            uuid="1234",
            local_addr="192.168.0.1",
            remote_addr="192.168.0.2",
            l4_protocol="tcp",
            l7_protocol="http",
            response=hex_dump_to_bytes(response_hex),
        )

        for key, value in kwargs.items():
            setattr(flow, key, value)

        return flow
