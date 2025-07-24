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

  void saveCopy(Request request) {
    if (request.file == null) return;

    final bruStr = request.toBru();
    File file = request.file!;

    if (file.existsSync()) {
      // Append ' copy' before the extension, or at the end if no extension
      final dir = file.parent.path;
      final base = file.uri.pathSegments.last;
      final dotIndex = base.lastIndexOf('.');
      String namePart, extPart;
      if (dotIndex > 0) {
        namePart = base.substring(0, dotIndex);
        extPart = base.substring(dotIndex);
      } else {
        namePart = base;
        extPart = '';
      }
      String newBase = '$namePart copy$extPart';
      String newPath = dir + Platform.pathSeparator + newBase;
      int copyIndex = 2;
      while (File(newPath).existsSync()) {
        newBase = '$namePart copy$copyIndex$extPart';
        newPath = dir + Platform.pathSeparator + newBase;
        copyIndex++;
      }
      file = File(newPath);
    }
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);
  }
}
