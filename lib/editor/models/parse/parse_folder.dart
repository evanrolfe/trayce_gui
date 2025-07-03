import 'package:trayce/editor/models/parse/parse_collection.dart';

import '../auth.dart';
import '../folder.dart';
import 'grammar_collection.dart';
import 'parse_request.dart';

Folder parseFolder(String folderBru) {
  final bruParser = BruCollectionGrammar().build();
  final result = bruParser.parse(folderBru.trim());

  if (!result.isSuccess) {
    throw Exception(result.message);
  }

  // Parse meta
  final meta = result.value['meta'] ?? {'type': 'folder'};
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

  return Folder(
    type: type,
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
