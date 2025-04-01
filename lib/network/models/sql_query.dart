import 'dart:convert';
import 'dart:typed_data';

import '../../agent/gen/api.pb.dart' as pb;
import 'flow_request.dart';

class SQLQuery extends FlowRequest {
  final String query;
  final List<String> params;

  const SQLQuery({
    required this.query,
    required this.params,
  });

  factory SQLQuery.fromProto(pb.SQLQuery proto) {
    return SQLQuery(
      query: proto.query,
      params: proto.params.values,
    );
  }

  factory SQLQuery.fromJson(Uint8List bytes) {
    final values = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return SQLQuery(
      query: values['query'] as String,
      params: (values['params'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  Uint8List toJson() {
    final jsonMap = {
      'query': query,
      'params': params,
    };
    return utf8.encode(json.encode(jsonMap));
  }

  @override
  String operationCol() {
    // Return the first line or first 50 chars of the query for the operation column
    final firstLine = query.split('\n').first;
    if (firstLine.length > 10) {
      return firstLine.substring(0, 10);
    }
    return firstLine;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(query);
    if (params.isNotEmpty) {
      buffer.writeln('\nParameters:');
      for (var i = 0; i < params.length; i++) {
        buffer.writeln('  \$${i + 1}: ${params[i]}');
      }
    }
    return buffer.toString();
  }
}
