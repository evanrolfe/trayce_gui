import 'package:petitparser/petitparser.dart';
import 'package:trayce/editor/models/multipart_file.dart';

import '../assertion.dart';
import '../auth.dart';
import '../body.dart';
import '../header.dart';
import '../param.dart';
import '../request.dart';
import '../script.dart';
import '../utils.dart';
import '../variable.dart';
import 'grammar_request.dart';

Request parseRequest(String request) {
  final bruParser = BruRequestGrammar().build();
  final result = bruParser.parse(request.trim());

  if (!result.isSuccess) {
    throw Exception(result.message);
  }

  // List of supported HTTP methods
  const httpMethods = ['get', 'post', 'put', 'delete', 'patch', 'options', 'head', 'connect', 'trace'];

  // Parse meta
  String? method;
  String? url;
  String? bodyTypeStr;
  String? authType;
  Map<String, dynamic>? methodBlock;
  if (result.value != null) {
    for (final m in httpMethods) {
      if (result.value.containsKey(m)) {
        method = m;
        methodBlock = result.value[m];
        url = methodBlock?['url'];
        // Extract bodyType if present
        if (methodBlock != null && methodBlock.containsKey('body')) {
          bodyTypeStr = methodBlock['body']?.toString();
        }
        // Extract authType if present
        if (methodBlock != null && methodBlock.containsKey('auth')) {
          authType = methodBlock['auth']?.toString();
        }
        break;
      }
    }
  }

  final seq = parseSeq(result);

  final params = parseParams(result);

  final headers = parseHeaders(result);

  final requestVars = parseRequestVars(result);

  final responseVars = parseResponseVars(result);

  final bodyJson = parseBodyJSON(result);
  final bodyText = parseBodyText(result);
  final bodyXml = parseBodyXML(result);
  final bodySparql = parseBodySparql(result);
  final bodyGraphql = parseBodyGraphql(result);
  final bodyFormUrlEncoded = parseBodyFormUrlEncoded(result);
  final bodyMultipartForm = parseBodyMultipartForm(result);
  final bodyFile = parseBodyFile(result);

  final authAwsV4 = parseAuthAwsV4(result);
  final authBasic = parseAuthBasic(result);
  final authBearer = parseAuthBearer(result);
  final authDigest = parseAuthDigest(result);
  final authOauth2 = parseAuthOauth2(result);
  final authWsse = parseAuthWsse(result);

  BodyType bodyTypeEnum;
  switch (bodyTypeStr) {
    case 'json':
      bodyTypeEnum = BodyType.json;
      break;
    case 'text':
      bodyTypeEnum = BodyType.text;
      break;
    case 'xml':
      bodyTypeEnum = BodyType.xml;
      break;
    case 'sparql':
      bodyTypeEnum = BodyType.sparql;
      break;
    case 'graphql':
      bodyTypeEnum = BodyType.graphql;
      break;
    case 'form-urlencoded':
      bodyTypeEnum = BodyType.formUrlEncoded;
      break;
    case 'multipart-form':
      bodyTypeEnum = BodyType.multipartForm;
      break;
    case 'file':
      bodyTypeEnum = BodyType.file;
      break;
    default:
      bodyTypeEnum = BodyType.none;
  }

  AuthType authTypeEnum;
  switch (authType) {
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
    case 'inherit':
      authTypeEnum = AuthType.inherit;
      break;
    default:
      authTypeEnum = AuthType.none;
  }

  final assertions = parseAssertions(result);

  final script = parseScript(result);

  final tests = parseTests(result);

  final docs = parseDocs(result);

  return Request(
    name: result.value['meta']['name'],
    type: result.value['meta']['type'],
    seq: seq,
    method: method ?? '',
    url: url ?? '',
    params: params,
    headers: headers,
    requestVars: requestVars,
    responseVars: responseVars,
    assertions: assertions,
    script: script,
    tests: tests,
    docs: docs,

    authType: authTypeEnum,
    bodyType: bodyTypeEnum,

    bodyText: bodyText,
    bodyJson: bodyJson,
    bodyXml: bodyXml,
    bodySparql: bodySparql,
    bodyGraphql: bodyGraphql,
    bodyFormUrlEncoded: bodyFormUrlEncoded,
    bodyMultipartForm: bodyMultipartForm,
    bodyFile: bodyFile,

    authAwsV4: authAwsV4,
    authBasic: authBasic,
    authBearer: authBearer,
    authDigest: authDigest,
    authOauth2: authOauth2,
    authWsse: authWsse,
  );
}

int parseSeq(Result<dynamic> result) {
  int seq = 0;
  final seqValue = result.value['meta']?['seq'];
  if (seqValue != null) {
    if (seqValue is int) {
      seq = seqValue;
    } else if (seqValue is String) {
      seq = int.tryParse(seqValue) ?? 0;
    }
  }
  return seq;
}

Param _createParam(MapEntry<String, dynamic> entry, ParamType type) {
  final enabled = !(entry.key.startsWith('~'));
  final name = enabled ? entry.key : entry.key.substring(1);
  return Param(name: name, value: entry.value.toString(), type: type, enabled: enabled);
}

MultipartFile _createMultipartFile(MapEntry<String, dynamic> entry) {
  final value = entry.value.toString();
  final enabled = !(entry.key.startsWith('~'));

  // Extract file path and content type using regex
  final filePathMatch = RegExp(r'@file\(([^)]+)\)').firstMatch(value);
  final contentTypeMatch = RegExp(r'@contentType\(([^)]+)\)').firstMatch(value);
  final filePath = filePathMatch?.group(1) ?? '';
  final contentType = contentTypeMatch?.group(1);

  final name = enabled ? entry.key : entry.key.substring(1);
  return MultipartFile(name: name, value: filePath, contentType: contentType, enabled: enabled);
}

FileBodyItem _createFile(String value, bool selected) {
  // Extract file path and content type using regex
  final filePathMatch = RegExp(r'@file\(([^)]+)\)').firstMatch(value);
  final contentTypeMatch = RegExp(r'@contentType\(([^)]+)\)').firstMatch(value);
  final filePath = filePathMatch?.group(1) ?? '';
  final contentType = contentTypeMatch?.group(1);

  return FileBodyItem(filePath: filePath, contentType: contentType, selected: selected);
}

List<Param> parseParams(Result<dynamic> result) {
  List<Param> params = [];
  if (result.value['params:query'] != null) {
    params.addAll(
      (result.value['params:query'] as Map<String, dynamic>).entries.map((e) => _createParam(e, ParamType.query)),
    );
  }
  if (result.value['params:path'] != null) {
    params.addAll(
      (result.value['params:path'] as Map<String, dynamic>).entries.map((e) => _createParam(e, ParamType.path)),
    );
  }
  return params;
}

List<Header> parseHeaders(Result<dynamic> result) {
  List<Header> headers = [];
  if (result.value['headers'] != null) {
    headers.addAll(
      (result.value['headers'] as Map<String, dynamic>).entries.map((e) {
        final enabled = !(e.key.startsWith('~'));
        final name = enabled ? e.key : e.key.substring(1);
        return Header(name: name, value: e.value.toString(), enabled: enabled);
      }),
    );
  }

  return headers;
}

List<Variable> parseRequestVars(Result<dynamic> result) {
  List<Variable> requestVars = [];
  if (result.value['vars:pre-request'] != null) {
    requestVars.addAll(
      (result.value['vars:pre-request'] as Map<String, dynamic>).entries.map((e) {
        final enabled = !(e.key.startsWith('~'));
        final key = enabled ? e.key : e.key.substring(1);
        final local = key.startsWith('@');
        final name = local ? key.substring(1) : key;
        return Variable(name: name, value: e.value.toString(), enabled: enabled, local: local);
      }),
    );
  }
  return requestVars;
}

List<Variable> parseResponseVars(Result<dynamic> result) {
  List<Variable> responseVars = [];
  if (result.value['vars:post-response'] != null) {
    responseVars.addAll(
      (result.value['vars:post-response'] as Map<String, dynamic>).entries.map((e) {
        final enabled = !(e.key.startsWith('~'));
        final key = enabled ? e.key : e.key.substring(1);
        final local = key.startsWith('@');
        final name = local ? key.substring(1) : key;
        return Variable(name: name, value: e.value.toString(), enabled: enabled, local: local);
      }),
    );
  }
  return responseVars;
}

List<Assertion> parseAssertions(Result<dynamic> result) {
  List<Assertion> assertions = [];
  if (result.value['assert'] != null) {
    assertions.addAll(
      (result.value['assert'] as Map<String, dynamic>).entries.map((e) {
        final enabled = !(e.key.startsWith('~'));
        final name = enabled ? e.key : e.key.substring(1);
        return Assertion(name: name, value: e.value.toString(), enabled: enabled);
      }),
    );
  }
  return assertions;
}

Script? parseScript(Result<dynamic> result) {
  Script? script;
  String? reqContent;
  String? resContent;

  if (result.value['script:pre-request'] != null) {
    final scriptBlock = result.value['script:pre-request'];
    reqContent = outdentString(scriptBlock['content']);
  }

  if (result.value['script:post-response'] != null) {
    final scriptBlock = result.value['script:post-response'];
    resContent = outdentString(scriptBlock['content']);
  }

  if (reqContent != null || resContent != null) {
    script = Script(req: reqContent, res: resContent);
  }

  return script;
}

String? parseTests(Result<dynamic> result) {
  String? tests;
  if (result.value['tests'] != null) {
    final testsBlock = result.value['tests'];
    final content = outdentString(testsBlock['content']);
    tests = content;
  }
  return tests;
}

String? parseDocs(Result<dynamic> result) {
  String? docs;
  if (result.value['docs'] != null) {
    final docsBlock = result.value['docs'];
    final content = outdentString(docsBlock['content']);
    docs = content;
  }
  return docs;
}

Body? parseBodyJSON(Result<dynamic> result) {
  const bodyKey = 'body:json';
  if (result.value[bodyKey] == null) return null;

  final bodyBlock = result.value[bodyKey];
  final content = outdentString(bodyBlock['content']);

  return JsonBody(content: content);
}

Body? parseBodyText(Result<dynamic> result) {
  const bodyKey = 'body:text';
  if (result.value[bodyKey] == null) return null;

  final bodyBlock = result.value[bodyKey];
  final content = outdentString(bodyBlock['content']);

  return TextBody(content: content);
}

Body? parseBodyXML(Result<dynamic> result) {
  const bodyKey = 'body:xml';
  if (result.value[bodyKey] == null) return null;

  final bodyBlock = result.value[bodyKey];
  final content = outdentString(bodyBlock['content']);

  return XmlBody(content: content);
}

Body? parseBodySparql(Result<dynamic> result) {
  const bodyKey = 'body:sparql';
  if (result.value[bodyKey] == null) return null;

  final bodyBlock = result.value[bodyKey];
  final content = outdentString(bodyBlock['content']);

  return SparqlBody(content: content);
}

Body? parseBodyGraphql(Result<dynamic> result) {
  const bodyKey = 'body:graphql';
  if (result.value[bodyKey] == null) return null;

  final bodyBlock = result.value[bodyKey];
  final content = outdentString(bodyBlock['content']);

  final graphqlVars = result.value['body:graphql:vars']?['content'] ?? '';
  return GraphqlBody(query: content, variables: outdentString(graphqlVars));
}

Body? parseBodyFormUrlEncoded(Result<dynamic> result) {
  const bodyKey = 'body:form-urlencoded';
  if (result.value[bodyKey] == null) return null;

  List<Param> params = [];
  if (result.value[bodyKey] != null) {
    params.addAll((result.value[bodyKey] as Map<String, dynamic>).entries.map((e) => _createParam(e, ParamType.form)));
  }
  return FormUrlEncodedBody(params: params);
}

Body? parseBodyMultipartForm(Result<dynamic> result) {
  const bodyKey = 'body:multipart-form';
  if (result.value[bodyKey] == null) return null;

  List<MultipartFile> files = [];
  if (result.value[bodyKey] != null) {
    files.addAll((result.value[bodyKey] as Map<String, dynamic>).entries.map((e) => _createMultipartFile(e)));
  }
  return MultipartFormBody(files: files);
}

Body? parseBodyFile(Result<dynamic> result) {
  const bodyKey = 'body:file';
  if (result.value[bodyKey] == null) return null;
  final bodyFiles = result.value['body:file'];

  List<FileBodyItem> files = [];
  if (bodyFiles['file'] != null) {
    files.addAll((bodyFiles['file'] as List<String>).map((e) => _createFile(e, true)));
  }
  if (bodyFiles['~file'] != null) {
    files.addAll((bodyFiles['~file'] as List<String>).map((e) => _createFile(e, false)));
  }

  return FileBody(files: files);
}

Auth? parseAuthAwsV4(Result<dynamic> result) {
  const authKey = 'auth:awsv4';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return AwsV4Auth(
    accessKeyId: authBlock['accessKeyId'] ?? '',
    secretAccessKey: authBlock['secretAccessKey'] ?? '',
    sessionToken: authBlock['sessionToken'] ?? '',
    service: authBlock['service'] ?? '',
    region: authBlock['region'] ?? '',
    profileName: authBlock['profileName'] ?? '',
  );
}

Auth? parseAuthBasic(Result<dynamic> result) {
  const authKey = 'auth:basic';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return BasicAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
}

Auth? parseAuthBearer(Result<dynamic> result) {
  const authKey = 'auth:bearer';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return BearerAuth(token: authBlock['token'] ?? '');
}

Auth? parseAuthDigest(Result<dynamic> result) {
  const authKey = 'auth:digest';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return DigestAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
}

Auth? parseAuthOauth2(Result<dynamic> result) {
  const authKey = 'auth:oauth2';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return OAuth2Auth(
    accessTokenUrl: authBlock['access_token_url'] ?? authBlock['accessTokenUrl'] ?? '',
    authorizationUrl: authBlock['authorization_url'] ?? authBlock['authorizationUrl'] ?? '',
    autoFetchToken: parseBool(authBlock['auto_fetch_token']),
    autoRefreshToken: parseBool(authBlock['auto_refresh_token']),
    callbackUrl: authBlock['callback_url'] ?? authBlock['callbackUrl'] ?? '',
    clientId: authBlock['client_id'] ?? authBlock['clientId'] ?? '',
    clientSecret: authBlock['client_secret'] ?? authBlock['clientSecret'] ?? '',
    credentialsId: authBlock['credentials_id'] ?? authBlock['credentialsId'] ?? '',
    credentialsPlacement: authBlock['credentials_placement'] ?? authBlock['credentialsPlacement'] ?? '',
    grantType: authBlock['grant_type'] ?? authBlock['grantType'] ?? '',
    pkce: parseBool(authBlock['pkce']),
    refreshTokenUrl: authBlock['refresh_token_url'] ?? authBlock['refreshTokenUrl'] ?? '',
    scope: authBlock['scope'] ?? '',
    state: authBlock['state'] ?? '',
    tokenHeaderPrefix: authBlock['token_header_prefix'] ?? authBlock['tokenHeaderPrefix'] ?? '',
    tokenPlacement: authBlock['token_placement'] ?? authBlock['tokenPlacement'] ?? '',
    tokenQueryKey: authBlock['token_query_key'] ?? authBlock['tokenQueryKey'] ?? '',
  );
}

Auth? parseAuthWsse(Result<dynamic> result) {
  const authKey = 'auth:wsse';
  if (result.value[authKey] == null) return null;

  final authBlock = result.value[authKey];

  return WsseAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
}
