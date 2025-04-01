import 'dart:convert';
import 'dart:typed_data';

import 'package:trayce/common/utils.dart';
import 'package:trayce/network/models/proto_def.dart';

import '../../agent/gen/api.pb.dart' as pb;
import 'flow_request.dart';

/// gRPC request with parsed fields
class GrpcRequest extends FlowRequest {
  final String path;
  final Map<String, List<String>> headers;
  final Uint8List body;

  const GrpcRequest({
    required this.path,
    required this.headers,
    required this.body,
  }) : super();

  /// Creates a GrpcRequest from raw JSON bytes
  static GrpcRequest fromJson(Uint8List bytes) {
    final values = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return GrpcRequest(
      path: values['path'] as String,
      headers: (values['headers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      ),
      body: Uint8List.fromList(base64.decode(values['payload'] as String)),
    );
  }

  /// Creates a GrpcRequest from a protobuf GRPCRequest
  factory GrpcRequest.fromProto(pb.GRPCRequest req) {
    // Convert headers from protobuf repeated fields to Map<String, List<String>>
    final headers = <String, List<String>>{};
    for (var entry in req.headers.entries) {
      headers[entry.key] = entry.value.values.map((v) => v.toString()).toList();
    }

    return GrpcRequest(
      path: req.path,
      headers: headers,
      body: Uint8List.fromList(req.payload),
    );
  }

  @override
  Uint8List toJson() {
    final map = {
      'path': path,
      'headers': headers,
      'payload': base64.encode(body),
    };
    return utf8.encode(json.encode(map));
  }

  @override
  String toString() {
    var out = 'GRPC $path\n';

    out += formatSortedHeaders(headers);

    out += '\r\n';
    if (body.isNotEmpty) {
      out += utf8.decode(body);
    }

    return out;
  }

  String toStringParsed(ProtoDef protoDef) {
    var out = 'GRPC $path\n';

    out += formatSortedHeaders(headers);

    out += '\r\n';
    if (body.isNotEmpty) {
      try {
        final parsedBody = protoDef.parseGRPCMessage(body, path, false);
        // Try to parse the body as JSON and format it with indentation
        final jsonObj = json.decode(parsedBody);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObj);
        out += '\n$prettyJson';
      } catch (e) {
        print(e);
        out += '\nFailed to parse using ${protoDef.name}';
      }
    }

    return out;
  }

  @override
  String operationCol() {
    return path;
  }
}
