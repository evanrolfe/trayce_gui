import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';

void main() {
  test('parses collection.bru and matches collection.json', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/collection.bru');
    final bruData = await bruFile.readAsString();

    // Load the expected JSON file
    final jsonFile = File('test/editor/models/fixtures/collection.json');
    final jsonData = await jsonFile.readAsString();
    final expected = json.decode(jsonData);

    // Parse the BRU data
    final result = parseCollection(bruData, bruFile, Directory('test/editor/models/fixtures'), []);

    expect(result.type, expected['meta']['type']);

    // Check headers
    final expectedHeaders = expected['headers'] as List;
    expect(result.headers.length, expectedHeaders.length);
    for (int i = 0; i < expectedHeaders.length; i++) {
      final eh = expectedHeaders[i];
      final rh = result.headers[i];
      expect(rh.name, eh['name']);
      expect(rh.value, eh['value']);
      expect(rh.enabled, eh['enabled']);
    }

    // Check requestVars
    final expectedReqVars = expected['vars']['req'] as List;
    expect(result.requestVars.length, expectedReqVars.length);
    for (int i = 0; i < expectedReqVars.length; i++) {
      final ev = expectedReqVars[i];
      final rv = result.requestVars[i];
      expect(rv.name, ev['name']);
      expect(rv.value, ev['value']);
      expect(rv.enabled, ev['enabled']);
    }

    // Check responseVars
    final expectedResVars = expected['vars']['res'] as List;
    expect(result.responseVars.length, expectedResVars.length);
    for (int i = 0; i < expectedResVars.length; i++) {
      final ev = expectedResVars[i];
      final rv = result.responseVars[i];
      expect(rv.name, ev['name']);
      expect(rv.value, ev['value']);
      expect(rv.enabled, ev['enabled']);
    }

    // Check auth
    final expectedAuth = expected['auth']['basic'];
    final auth = result.getAuth();
    expect(auth, isNotNull);
    expect(auth is BasicAuth, isTrue);
    expect((auth as BasicAuth).username, expectedAuth['username']);
    expect(auth.password, expectedAuth['password']);

    // Check script
    final expectedScript = expected['script']?['req'];
    if (expectedScript != null) {
      expect(result.script, isNotNull);
      expect(result.script!.req, expectedScript);
    }

    // Check tests
    final expectedTests = expected['tests'];
    if (expectedTests != null) {
      expect(result.tests, expectedTests);
    }

    // Check docs
    final expectedDocs = expected['docs'];
    if (expectedDocs != null) {
      expect(result.docs, expectedDocs);
    }
  });
}
