import 'dart:typed_data';

/// Base class for all flow request types
abstract class FlowRequest {
  const FlowRequest();

  /// Creates a FlowRequest instance from raw JSON bytes
  static FlowRequest fromJson(Uint8List bytes) {
    throw UnimplementedError();
  }

  /// Converts the request to JSON bytes
  Uint8List toJson();

  @override
  String toString();

  String operationCol();
}
