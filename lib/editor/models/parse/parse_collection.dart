import 'dart:io';

import 'package:petitparser/petitparser.dart';

import '../auth.dart';
import '../collection.dart';
import '../environment.dart';
import '../param.dart';
import 'grammar_collection.dart';
import 'parse_request.dart';

Collection parseCollection(String collection, File file, Directory dir, List<Environment> environments) {
  final bruParser = BruCollectionGrammar().build();
  final result = bruParser.parse(collection.trim());

  if (!result.isSuccess) {
    throw Exception(result.message);
  }

  // Parse meta
  final meta = result.value['meta'] ?? {'type': 'collection'};
  final type = meta['type'] ?? '';

  final headers = parseHeaders(result);

  final requestVars = parseRequestVars(result);

  final responseVars = parseResponseVars(result);

  final query = parseQuery(result);

  final authMode = result.value['auth']?['mode'];
  Auth? auth;
  if (authMode != null && authMode != 'none') {
    auth = parseAuth(result, authMode);
  }

  final script = parseScript(result);

  final tests = parseTests(result);

  final docs = parseDocs(result);

  return Collection(
    file: file,
    dir: dir,
    type: type,
    environments: environments,
    meta: meta,
    headers: headers,
    query: query,
    auth: auth,
    requestVars: requestVars,
    responseVars: responseVars,
    script: script,
    tests: tests,
    docs: docs,
  );
}

List<Param> parseQuery(Result<dynamic> result) {
  List<Param> query = [];
  if (result.value['query'] != null) {
    query.addAll(
      (result.value['query'] as Map<String, dynamic>).entries.map((e) {
        final enabled = !(e.key.startsWith('~'));
        final name = enabled ? e.key : e.key.substring(1);
        return Param(name: name, value: e.value.toString(), type: ParamType.query, enabled: enabled);
      }),
    );
  }
  return query;
}
