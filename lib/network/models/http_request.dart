import 'dart:convert';
import 'dart:typed_data';

import 'package:trayce/common/utils.dart';
import 'package:trayce/network/models/flow_request.dart';

import '../../agent/gen/api.pb.dart' as pb;

class HttpRequest extends FlowRequest {
  final String method;
  final String host;
  final String path;
  final String httpVersion;
  final Map<String, List<String>> headers;
  final String body;

  const HttpRequest({
    required this.method,
    required this.host,
    required this.path,
    required this.httpVersion,
    required this.headers,
    required this.body,
  }) : super();

  /// Creates an HttpRequest from raw JSON bytes
  static HttpRequest fromJson(Uint8List bytes) {
    final values = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return HttpRequest(
      method: values['method'] as String,
      path: values['path'] as String,
      host: values['host'] as String,
      httpVersion: values['http_version'] as String,
      headers: (values['headers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      ),
      body: values['body'] as String,
    );
  }

  /// Creates an HttpRequest from a protobuf HTTPRequest
  factory HttpRequest.fromProto(pb.HTTPRequest req) {
    // Convert headers from protobuf repeated fields to Map<String, List<String>>
    final headers = <String, List<String>>{};
    for (var entry in req.headers.entries) {
      headers[entry.key] = entry.value.values.map((v) => v.toString()).toList();
    }

    // Convert body from bytes to UTF-8 string if present
    final body = req.payload.isEmpty ? '' : utf8.decode(req.payload);

    return HttpRequest(
      method: req.method,
      path: req.path,
      host: req.host,
      httpVersion: req.httpVersion,
      headers: headers,
      body: body,
    );
  }

  @override
  Uint8List toJson() {
    final map = {
      'method': method,
      'path': path,
      'host': host,
      'http_version': httpVersion,
      'headers': headers,
      'body': body,
    };
    return utf8.encode(json.encode(map));
  }

  @override
  String toString() {
    var out = '$method $path HTTP/$httpVersion\n';

    out += formatSortedHeaders(headers);

    out += '\r\n';
    if (body.isNotEmpty) {
      out += body;
    }

    return out;
  }

  @override
  String operationCol() {
    return "$method $path";
  }
}
