import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';
import 'package:trayce/editor/models/request.dart';

void main() {
  test('parses request.bru and matches request.json', () async {
    // Load the BRU file
    final bruFile = File('test/editor/models/fixtures/request.bru');
    final bruData = await bruFile.readAsString();

    // Load the expected JSON file
    final jsonFile = File('test/editor/models/fixtures/request.json');
    final jsonData = await jsonFile.readAsString();
    final expected = json.decode(jsonData);

    // Parse the BRU data
    final result = parseRequest(bruData);

    expect(result.name, expected['meta']['name']);
    expect(result.type, expected['meta']['type']);
    expect(result.seq, int.parse(expected['meta']['seq']));
    expect(result.method, expected['http']['method']);
    expect(result.url, expected['http']['url']);

    // Check params
    final expectedParams = expected['params'] as List;
    expect(result.params.length, expectedParams.length);
    for (int i = 0; i < expectedParams.length; i++) {
      final ep = expectedParams[i];
      final rp = result.params[i];
      expect(rp.name, ep['name']);
      expect(rp.value, ep['value']);
      expect(rp.type, ep['type']);
      expect(rp.enabled, ep['enabled']);
    }

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
      expect(rv.local, ev['local']);
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
      expect(rv.local, ev['local']);
    }

    // Check body
    final expectedBody = expected['body'];
    final body = result.getBody();
    expect(body is JsonBody, isTrue);
    expect((body as JsonBody).content, expectedBody['json']);

    expect(result.bodyType, BodyType.json);
    expect(body, isNotNull);
    expect(result.bodyJson?.toString(), expectedBody['json']);
    expect(result.bodyText?.toString(), expectedBody['text']);

    // Check auth
    final expectedAuth = expected['auth']['bearer'];
    final auth = result.auth;
    expect(auth, isNotNull);

    // Check for JSON body
    expect(auth is BearerAuth, isTrue);
    expect((auth as BearerAuth).token, expectedAuth['token']);

    // Check assertions
    final expectedAssertions = expected['assertions'] as List;
    expect(result.assertions.length, expectedAssertions.length);
    for (int i = 0; i < expectedAssertions.length; i++) {
      final ea = expectedAssertions[i];
      final ra = result.assertions[i];
      expect(ra.name, ea['name']);
      expect(ra.value, ea['value']);
      expect(ra.enabled, ea['enabled']);
    }

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
