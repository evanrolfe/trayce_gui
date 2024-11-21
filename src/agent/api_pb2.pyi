from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Flow(_message.Message):
    __slots__ = ("uuid", "source_addr", "dest_addr", "l4_protocol", "l7_protocol", "response_raw", "http_request", "grpc_request", "http_response", "grpc_response")
    UUID_FIELD_NUMBER: _ClassVar[int]
    SOURCE_ADDR_FIELD_NUMBER: _ClassVar[int]
    DEST_ADDR_FIELD_NUMBER: _ClassVar[int]
    L4_PROTOCOL_FIELD_NUMBER: _ClassVar[int]
    L7_PROTOCOL_FIELD_NUMBER: _ClassVar[int]
    RESPONSE_RAW_FIELD_NUMBER: _ClassVar[int]
    HTTP_REQUEST_FIELD_NUMBER: _ClassVar[int]
    GRPC_REQUEST_FIELD_NUMBER: _ClassVar[int]
    HTTP_RESPONSE_FIELD_NUMBER: _ClassVar[int]
    GRPC_RESPONSE_FIELD_NUMBER: _ClassVar[int]
    uuid: str
    source_addr: str
    dest_addr: str
    l4_protocol: str
    l7_protocol: str
    response_raw: bytes
    http_request: HTTPRequest
    grpc_request: GRPCRequest
    http_response: HTTPResponse
    grpc_response: GRPCResponse
    def __init__(self, uuid: _Optional[str] = ..., source_addr: _Optional[str] = ..., dest_addr: _Optional[str] = ..., l4_protocol: _Optional[str] = ..., l7_protocol: _Optional[str] = ..., response_raw: _Optional[bytes] = ..., http_request: _Optional[_Union[HTTPRequest, _Mapping]] = ..., grpc_request: _Optional[_Union[GRPCRequest, _Mapping]] = ..., http_response: _Optional[_Union[HTTPResponse, _Mapping]] = ..., grpc_response: _Optional[_Union[GRPCResponse, _Mapping]] = ...) -> None: ...

class Flows(_message.Message):
    __slots__ = ("flows",)
    FLOWS_FIELD_NUMBER: _ClassVar[int]
    flows: _containers.RepeatedCompositeFieldContainer[Flow]
    def __init__(self, flows: _Optional[_Iterable[_Union[Flow, _Mapping]]] = ...) -> None: ...

class StringList(_message.Message):
    __slots__ = ("values",)
    VALUES_FIELD_NUMBER: _ClassVar[int]
    values: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, values: _Optional[_Iterable[str]] = ...) -> None: ...

class HTTPRequest(_message.Message):
    __slots__ = ("method", "host", "path", "http_version", "headers", "payload")
    class HeadersEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: StringList
        def __init__(self, key: _Optional[str] = ..., value: _Optional[_Union[StringList, _Mapping]] = ...) -> None: ...
    METHOD_FIELD_NUMBER: _ClassVar[int]
    HOST_FIELD_NUMBER: _ClassVar[int]
    PATH_FIELD_NUMBER: _ClassVar[int]
    HTTP_VERSION_FIELD_NUMBER: _ClassVar[int]
    HEADERS_FIELD_NUMBER: _ClassVar[int]
    PAYLOAD_FIELD_NUMBER: _ClassVar[int]
    method: str
    host: str
    path: str
    http_version: str
    headers: _containers.MessageMap[str, StringList]
    payload: bytes
    def __init__(self, method: _Optional[str] = ..., host: _Optional[str] = ..., path: _Optional[str] = ..., http_version: _Optional[str] = ..., headers: _Optional[_Mapping[str, StringList]] = ..., payload: _Optional[bytes] = ...) -> None: ...

class HTTPResponse(_message.Message):
    __slots__ = ("http_version", "status", "status_msg", "headers", "payload")
    class HeadersEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: StringList
        def __init__(self, key: _Optional[str] = ..., value: _Optional[_Union[StringList, _Mapping]] = ...) -> None: ...
    HTTP_VERSION_FIELD_NUMBER: _ClassVar[int]
    STATUS_FIELD_NUMBER: _ClassVar[int]
    STATUS_MSG_FIELD_NUMBER: _ClassVar[int]
    HEADERS_FIELD_NUMBER: _ClassVar[int]
    PAYLOAD_FIELD_NUMBER: _ClassVar[int]
    http_version: str
    status: int
    status_msg: str
    headers: _containers.MessageMap[str, StringList]
    payload: bytes
    def __init__(self, http_version: _Optional[str] = ..., status: _Optional[int] = ..., status_msg: _Optional[str] = ..., headers: _Optional[_Mapping[str, StringList]] = ..., payload: _Optional[bytes] = ...) -> None: ...

class GRPCRequest(_message.Message):
    __slots__ = ("path", "headers", "payload")
    class HeadersEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: str
        def __init__(self, key: _Optional[str] = ..., value: _Optional[str] = ...) -> None: ...
    PATH_FIELD_NUMBER: _ClassVar[int]
    HEADERS_FIELD_NUMBER: _ClassVar[int]
    PAYLOAD_FIELD_NUMBER: _ClassVar[int]
    path: str
    headers: _containers.ScalarMap[str, str]
    payload: bytes
    def __init__(self, path: _Optional[str] = ..., headers: _Optional[_Mapping[str, str]] = ..., payload: _Optional[bytes] = ...) -> None: ...

class GRPCResponse(_message.Message):
    __slots__ = ("headers", "payload")
    class HeadersEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: str
        def __init__(self, key: _Optional[str] = ..., value: _Optional[str] = ...) -> None: ...
    HEADERS_FIELD_NUMBER: _ClassVar[int]
    PAYLOAD_FIELD_NUMBER: _ClassVar[int]
    headers: _containers.ScalarMap[str, str]
    payload: bytes
    def __init__(self, headers: _Optional[_Mapping[str, str]] = ..., payload: _Optional[bytes] = ...) -> None: ...

class Reply(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: str
    def __init__(self, status: _Optional[str] = ...) -> None: ...

class AgentStarted(_message.Message):
    __slots__ = ("version",)
    VERSION_FIELD_NUMBER: _ClassVar[int]
    version: str
    def __init__(self, version: _Optional[str] = ...) -> None: ...

class Command(_message.Message):
    __slots__ = ("type", "settings")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    type: str
    settings: Settings
    def __init__(self, type: _Optional[str] = ..., settings: _Optional[_Union[Settings, _Mapping]] = ...) -> None: ...

class Settings(_message.Message):
    __slots__ = ("container_ids",)
    CONTAINER_IDS_FIELD_NUMBER: _ClassVar[int]
    container_ids: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, container_ids: _Optional[_Iterable[str]] = ...) -> None: ...

class Request(_message.Message):
    __slots__ = ("num",)
    NUM_FIELD_NUMBER: _ClassVar[int]
    num: int
    def __init__(self, num: _Optional[int] = ...) -> None: ...

class Response(_message.Message):
    __slots__ = ("result",)
    RESULT_FIELD_NUMBER: _ClassVar[int]
    result: int
    def __init__(self, result: _Optional[int] = ...) -> None: ...

class Container(_message.Message):
    __slots__ = ("id", "image", "ip", "name", "status")
    ID_FIELD_NUMBER: _ClassVar[int]
    IMAGE_FIELD_NUMBER: _ClassVar[int]
    IP_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    STATUS_FIELD_NUMBER: _ClassVar[int]
    id: str
    image: str
    ip: str
    name: str
    status: str
    def __init__(self, id: _Optional[str] = ..., image: _Optional[str] = ..., ip: _Optional[str] = ..., name: _Optional[str] = ..., status: _Optional[str] = ...) -> None: ...

class Containers(_message.Message):
    __slots__ = ("containers",)
    CONTAINERS_FIELD_NUMBER: _ClassVar[int]
    containers: _containers.RepeatedCompositeFieldContainer[Container]
    def __init__(self, containers: _Optional[_Iterable[_Union[Container, _Mapping]]] = ...) -> None: ...
