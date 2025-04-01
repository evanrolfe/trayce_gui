import 'dart:typed_data';

/// Base class for all flow response types
abstract class FlowResponse {
  const FlowResponse();

  /// Creates a FlowResponse instance from raw JSON bytes
  static FlowResponse fromJson(Uint8List bytes) {
    throw UnimplementedError();
  }

  /// Converts the response to JSON bytes
  Uint8List toJson();

  @override
  String toString();

  String responseCol();
}
