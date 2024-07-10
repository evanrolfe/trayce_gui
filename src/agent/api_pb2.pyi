from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Flow(_message.Message):
    __slots__ = ("uuid", "local_addr", "remote_addr", "l4_protocol", "l7_protocol", "request", "response")
    UUID_FIELD_NUMBER: _ClassVar[int]
    LOCAL_ADDR_FIELD_NUMBER: _ClassVar[int]
    REMOTE_ADDR_FIELD_NUMBER: _ClassVar[int]
    L4_PROTOCOL_FIELD_NUMBER: _ClassVar[int]
    L7_PROTOCOL_FIELD_NUMBER: _ClassVar[int]
    REQUEST_FIELD_NUMBER: _ClassVar[int]
    RESPONSE_FIELD_NUMBER: _ClassVar[int]
    uuid: str
    local_addr: str
    remote_addr: str
    l4_protocol: str
    l7_protocol: str
    request: bytes
    response: bytes
    def __init__(self, uuid: _Optional[str] = ..., local_addr: _Optional[str] = ..., remote_addr: _Optional[str] = ..., l4_protocol: _Optional[str] = ..., l7_protocol: _Optional[str] = ..., request: _Optional[bytes] = ..., response: _Optional[bytes] = ...) -> None: ...

class Flows(_message.Message):
    __slots__ = ("flows",)
    FLOWS_FIELD_NUMBER: _ClassVar[int]
    flows: _containers.RepeatedCompositeFieldContainer[Flow]
    def __init__(self, flows: _Optional[_Iterable[_Union[Flow, _Mapping]]] = ...) -> None: ...

class Reply(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: str
    def __init__(self, status: _Optional[str] = ...) -> None: ...

class AgentStarted(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class NooP(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

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
