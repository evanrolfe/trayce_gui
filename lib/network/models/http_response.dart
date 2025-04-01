import 'dart:convert';
import 'dart:typed_data';

import 'package:trayce/common/utils.dart';
import 'package:trayce/network/models/flow_response.dart';

import '../../agent/gen/api.pb.dart' as pb;

/// HTTP response with parsed fields
class HttpResponse extends FlowResponse {
  final String httpVersion;
  final int status;
  final String statusMsg;
  final Map<String, List<String>> headers;
  final String body;

  const HttpResponse({
    required this.httpVersion,
    required this.status,
    required this.statusMsg,
    required this.headers,
    required this.body,
  }) : super();

  /// Creates an HttpResponse from raw JSON bytes
  static HttpResponse fromJson(Uint8List bytes) {
    final values = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return HttpResponse(
      httpVersion: values['http_version'] as String,
      status: values['status'] as int,
      statusMsg: values['status_msg'] as String,
      headers: (values['headers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      ),
      body: values['body'] as String,
    );
  }

  /// Creates an HttpResponse from a protobuf HTTPResponse
  factory HttpResponse.fromProto(pb.HTTPResponse resp) {
    // Convert headers from protobuf repeated fields to Map<String, List<String>>
    final headers = <String, List<String>>{};
    for (var entry in resp.headers.entries) {
      headers[entry.key] = entry.value.values.map((v) => v.toString()).toList();
    }

    // Convert body from bytes to UTF-8 string if present
    final body = resp.payload.isEmpty ? '' : utf8.decode(resp.payload);

    return HttpResponse(
      httpVersion: resp.httpVersion,
      status: resp.status,
      statusMsg: resp.statusMsg,
      headers: headers,
      body: body,
    );
  }

  @override
  Uint8List toJson() {
    final map = {
      'http_version': httpVersion,
      'status': status,
      'status_msg': statusMsg,
      'headers': headers,
      'body': body,
    };
    return utf8.encode(json.encode(map));
  }

  @override
  String toString() {
    var out = 'HTTP/$httpVersion $status $statusMsg\n';

    out += formatSortedHeaders(headers);

    out += '\r\n';
    if (body.isNotEmpty) {
      out += body;
    }

    return out;
  }

  @override
  String responseCol() {
    return status.toString();
  }
}
