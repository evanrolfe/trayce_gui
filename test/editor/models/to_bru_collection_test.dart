import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';

void main() {
  test('saves a Collection to collection.bru', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/collection_saved.bru');
    final bruData = await bruFile.readAsString();

    // Parse the BRU data
    final collection = parseCollection(bruData, []);

    final bru = collection.toBru();
    expect(bru, bruData);
  });
}
