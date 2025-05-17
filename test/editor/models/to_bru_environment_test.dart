import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_environment.dart';

void main() {
  test('saves an Environment to environment.bru', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/environment.bru');
    final bruData = await bruFile.readAsString();

    // Parse the BRU data
    final environment = parseEnvironment(bruData);

    final bru = environment.toBru();
    expect(bru, bruData);
  });
}
