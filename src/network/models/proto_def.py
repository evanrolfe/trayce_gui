from __future__ import annotations
from dataclasses import dataclass, field
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.descriptor import FileDescriptor
from google.protobuf.descriptor_pool import DescriptorPool
from google.protobuf.message import DecodeError, Message

from shared.model import Model

@dataclass(kw_only=True)
class ProtoDef(Model):
    id: int = field(init=False, default=0)
    created_at: int = field(init=False, default=0)

    name: str
    file_path: str
    raw: bytes

    meta = {
        "relationship_keys": [],
        "json_columns": [],
        "do_not_save_keys": [],
    }

    def file_descriptor(self) -> FileDescriptor:
        # 1. Load the descriptor file (descriptor.pb) into a FileDescriptorSet
        file_descriptor_set = descriptor_pb2.FileDescriptorSet()
        file_descriptor_set.ParseFromString(self.raw)

        # 2. Register the descriptor in a DescriptorPool
        pool: DescriptorPool = descriptor_pool.DescriptorPool()
        for file_descriptor_proto in file_descriptor_set.file:
            # override the name here because otherwise it uses the relative file path which gets complicated when trying to retrieve this
            file_descriptor_proto.name = "trayce"
            pool.Add(file_descriptor_proto)

        file_descriptor = pool.FindFileByName("trayce")

        return file_descriptor
        #     message_descriptor = file_descriptor.message_types_by_name[message_name]
        #     message_class = message_factory.GetMessageClass(message_descriptor)
        # except KeyError:
        #     raise Exception(f"Message type '{message_name}' not found in descriptor.")
