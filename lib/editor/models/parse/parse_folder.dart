import 'dart:io';

import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/request.dart';

import '../folder.dart';
import 'grammar_collection.dart';
import 'parse_request.dart';

Folder parseFolder(String folderBru, File file, Directory dir) {
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

  // Parse auth
  final authMode = result.value['auth']?['mode'];
  AuthType authTypeEnum;
  switch (authMode) {
    case 'none':
      authTypeEnum = AuthType.none;
      break;
    case 'awsv4':
      authTypeEnum = AuthType.awsV4;
      break;
    case 'basic':
      authTypeEnum = AuthType.basic;
      break;
    case 'bearer':
      authTypeEnum = AuthType.bearer;
      break;
    case 'digest':
      authTypeEnum = AuthType.digest;
      break;
    case 'oauth2':
      authTypeEnum = AuthType.oauth2;
      break;
    case 'wsse':
      authTypeEnum = AuthType.wsse;
      break;
    default:
      authTypeEnum = AuthType.none;
  }
  final authAwsV4 = parseAuthAwsV4(result);
  final authBasic = parseAuthBasic(result);
  final authBearer = parseAuthBearer(result);
  final authDigest = parseAuthDigest(result);
  final authOauth2 = parseAuthOauth2(result);
  final authWsse = parseAuthWsse(result);

  final script = parseScript(result);

  final tests = parseTests(result);

  final docs = parseDocs(result);

  return Folder(
    file: file,
    dir: dir,
    type: type,
    meta: meta,
    headers: headers,
    query: query,
    authType: authTypeEnum,
    authAwsV4: authAwsV4,
    authBasic: authBasic,
    authBearer: authBearer,
    authDigest: authDigest,
    authOauth2: authOauth2,
    authWsse: authWsse,
    requestVars: requestVars,
    responseVars: responseVars,
    script: script,
    tests: tests,
    docs: docs,
  );
}
