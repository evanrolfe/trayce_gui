import 'dart:io';

import 'package:trayce/editor/models/parse/parse_request.dart';
import 'package:trayce/editor/models/request.dart';

class RequestRepo {
  Request load(File file) {
    final requestStr = file.readAsStringSync();
    final request = parseRequest(requestStr);

    request.file = file;

    return request;
  }

  void save(Request request) {
    if (request.file == null) return;

    // request.name = name.replaceAll('.bru', '');
    final bruStr = request.toBru();
    final file = request.file!;

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);
  }
}
