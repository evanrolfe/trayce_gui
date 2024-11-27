
import re
from typing import Tuple
from google.protobuf import descriptor_pb2, descriptor_pool, message_factory
from google.protobuf.message import DecodeError, Message
from google.protobuf.descriptor import FileDescriptor
from google.protobuf.descriptor_pool import DescriptorPool

def extract_grpc_path_info(grpc_path: str) -> Tuple[str, str, str]:
    """
    Extract package name(s), service name, and method name from a gRPC path.

    :param grpc_path: The gRPC path (e.g., "/api.TrayceAgent/SendContainersObserved")
    :return: A tuple containing (package_name, service_name, method_name)
    """
    # Define the regex pattern to match the gRPC path
    pattern = r"^/((?:[a-zA-Z0-9_.]+)\.)?([a-zA-Z0-9_]+)\/([a-zA-Z0-9_]+)$"
    match = re.match(pattern, grpc_path)

    if not match:
        raise ValueError(f"Invalid gRPC path format: {grpc_path}")

    # Extract components
    package_and_service = match.group(1)  # Package and service name combined
    service_name = match.group(2)        # Service name
    method_name = match.group(3)         # Method name

    # Split package name and service name
    package_name = package_and_service[:-1] if package_and_service else ""  # Remove trailing dot

    return package_name, service_name, method_name

def decode_grpc_data(raw_data: bytes, file_descriptor: FileDescriptor, msg_name: str) -> str:
    try:
        message_descriptor = file_descriptor.message_types_by_name[msg_name]
        message_class = message_factory.GetMessageClass(message_descriptor)
    except KeyError:
        return f"Message type '{msg_name}' not found in descriptor."

    # Create an instance of the message and parse the byte array
    message = message_class()
    try:
        message.ParseFromString(raw_data)
    except DecodeError as e:
        return f"Failed to decode: {e}"

    return str(message)
