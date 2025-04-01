import 'dart:convert';
import 'dart:typed_data';

import '../../agent/gen/api.pb.dart' as pb;
import 'flow_response.dart';

/// SQL response with columns and rows
class SQLResponse extends FlowResponse {
  final List<String> columns;
  final List<List<String>> rows;

  const SQLResponse({
    required this.columns,
    required this.rows,
  }) : super();

  /// Creates a SQLResponse from raw JSON bytes
  static SQLResponse fromJson(Uint8List bytes) {
    final values = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return SQLResponse(
      columns: (values['columns'] as List<dynamic>).cast<String>(),
      rows: (values['rows'] as List<dynamic>).map((row) => (row as List<dynamic>).cast<String>()).toList(),
    );
  }

  /// Creates a SQLResponse from a protobuf SQLResponse
  factory SQLResponse.fromProto(pb.SQLResponse res) {
    return SQLResponse(
      columns: res.columns.values,
      rows: res.rows.map((row) => row.values).toList(),
    );
  }

  @override
  Uint8List toJson() {
    final map = {
      'columns': columns,
      'rows': rows,
    };
    return utf8.encode(json.encode(map));
  }

  @override
  String responseCol() {
    return '${rows.length} rows';
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    // Calculate column widths
    final widths = List<int>.filled(columns.length, 0);
    for (var i = 0; i < columns.length; i++) {
      widths[i] = columns[i].length;
      for (final row in rows) {
        widths[i] = widths[i] > row[i].length ? widths[i] : row[i].length;
      }
    }

    // Write header
    for (var i = 0; i < columns.length; i++) {
      buffer.write(columns[i].padRight(widths[i] + 2));
    }
    buffer.writeln();

    // Write separator
    for (var i = 0; i < columns.length; i++) {
      buffer.write('-' * widths[i] + '--');
    }
    buffer.writeln();

    // Write rows
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        buffer.write(row[i].padRight(widths[i] + 2));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
