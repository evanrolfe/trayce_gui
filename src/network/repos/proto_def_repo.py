import json
import subprocess
from typing import Any, Optional
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, LargeBinary, insert, select
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.message import DecodeError, Message
from google.protobuf.descriptor_pool import DescriptorPool

from network.models.proto_def import ProtoDef
from shared.base_repo import BaseRepo

class ProtoDefRepo(BaseRepo):
    table = Table(
        'proto_defs',
        MetaData(),
        Column('id', Integer, primary_key=True),
        Column('name', String()),
        Column('file_path', String()),
        Column('raw', LargeBinary()),
        Column('created_at', String()),
    )

    def find_all(self) -> list[ProtoDef]:
        select_stmt = select(self.table).order_by(self.table.c.name)
        results = self.conn.execute(select_stmt).fetchall()

        proto_defs = []
        for row in results:
            proto_def = ProtoDef(name=row[1], file_path=row[2], raw=row[3])
            proto_def.id = row[0]
            proto_defs.append(proto_def)

        return proto_defs

    def find_by_id(self, id: int) -> Optional[ProtoDef]:
        select_stmt = select(self.table).where(self.table.c.id == id)
        result = self.conn.execute(select_stmt).fetchone()
        if result is None:
            return

        proto_def = ProtoDef(name=result[1], file_path=result[2], raw=result[3])
        proto_def.id = result[0]
        return proto_def

    def save(self, proto_def: ProtoDef):
        values = proto_def.values_for_db()
        insert_stmt = insert(self.table).values(values)

        result = self.conn.execute(insert_stmt)
        self.conn.commit()
        proto_def.id = result.lastrowid

    def upload(self, name: str, proto_file_path: str) -> ProtoDef:
        # TODO: Use an absolute path to a tmp location
        descriptor_file_path = "/Users/evan/Code/trayce/gui/descriptor.pb"
        cmd = ["protoc",f"--descriptor_set_out={descriptor_file_path}","--include_imports", proto_file_path]

        try:
            # Run the command
            result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print("Command ran successfully!")
            print(result.stdout.decode())  # Print standard output if needed
        except subprocess.CalledProcessError as e:
            print("Error running command:")
            print(e.stderr.decode())  # Print error output if the command fails

        # Step 1: Load the descriptor file (descriptor.pb) into a FileDescriptorSet
        proto_def = ProtoDef(name=name, file_path=proto_file_path, raw=bytes())
        with open(descriptor_file_path, "rb") as f:
            proto_def.raw = f.read()

        self.save(proto_def)

        return proto_def
        # # Step 2: Register the descriptor in a DescriptorPool
        # pool: DescriptorPool = descriptor_pool.Default()
        # for file_descriptor_proto in file_descriptor_set.file:
        #     pool.Add(file_descriptor_proto)
        #     # print("==============> file_descriptor_proto:", file_descriptor_proto)

        return


def load_descriptor_from_file(descriptor_file_path: str) -> DescriptorPool:
    # Step 1: Load the descriptor file (descriptor.pb) into a FileDescriptorSet
    with open(descriptor_file_path, "rb") as f:
        file_descriptor_set = descriptor_pb2.FileDescriptorSet()
        file_descriptor_set.ParseFromString(f.read())

    # Step 2: Register the descriptor in a DescriptorPool
    pool: DescriptorPool = descriptor_pool.DescriptorPool()
    for file_descriptor_proto in file_descriptor_set.file:
        pool.Add(file_descriptor_proto)

    return pool
