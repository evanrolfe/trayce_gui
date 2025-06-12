import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';

void main() {
  test('saves a Request to request.bru', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/request_saved.bru');
    final bruData = await bruFile.readAsString();

    // Parse the BRU data
    final request = parseRequest(bruData);

    final bru = request.toBru();
    expect(bru, bruData);
  });

  test('parsing multiple bodies', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/request_saved.bru');
    final bruData = await bruFile.readAsString();

    // Parse the BRU data
    final request = parseRequest(bruData);
    final bru = request.toBru();
    expect(bru, bruData);
  });
}
