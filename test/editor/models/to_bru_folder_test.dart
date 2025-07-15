import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_folder.dart';

void main() {
  test('saves a folder to folder.bru', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/folder.bru');
    final bruData = await bruFile.readAsString();

    // Parse the BRU data
    final folder = parseFolder(bruData, bruFile, Directory('test/editor/models/fixtures'));

    final bru = folder.toBru();
    expect(bru, bruData);
  });
}
