import 'package:petitparser/petitparser.dart';

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

  BodyType bodyType;
  switch (bodyTypeStr) {
    case 'json':
      bodyType = BodyType.json;
      break;
    case 'text':
      bodyType = BodyType.text;
      break;
    case 'xml':
      bodyType = BodyType.xml;
      break;
    case 'sparql':
      bodyType = BodyType.sparql;
      break;
    case 'graphql':
      bodyType = BodyType.graphql;
      break;
    case 'form-urlencoded':
      bodyType = BodyType.formUrlEncoded;
      break;
    case 'multipart-form':
      bodyType = BodyType.multipartForm;
      break;
    case 'file':
      bodyType = BodyType.file;
      break;
    default:
      bodyType = BodyType.none;
  }
  print('===> url: $url, bodyType: $bodyType');
  final auth = parseAuth(result, authType);

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
    auth: auth,
    params: params,
    headers: headers,
    requestVars: requestVars,
    responseVars: responseVars,
    assertions: assertions,
    script: script,
    tests: tests,
    docs: docs,

    bodyType: bodyType,

    bodyText: bodyText,
    bodyJson: bodyJson,
    bodyXml: bodyXml,
    bodySparql: bodySparql,
    bodyGraphql: bodyGraphql,
    bodyFormUrlEncoded: bodyFormUrlEncoded,
    bodyMultipartForm: bodyMultipartForm,
    bodyFile: bodyFile,
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

Param _createParam(MapEntry<String, dynamic> entry, String type) {
  final enabled = !(entry.key.startsWith('~'));
  final name = enabled ? entry.key : entry.key.substring(1);
  return Param(name: name, value: entry.value.toString(), type: type, enabled: enabled);
}

List<Param> parseParams(Result<dynamic> result) {
  List<Param> params = [];
  if (result.value['params:query'] != null) {
    params.addAll((result.value['params:query'] as Map<String, dynamic>).entries.map((e) => _createParam(e, 'query')));
  }
  if (result.value['params:path'] != null) {
    params.addAll((result.value['params:path'] as Map<String, dynamic>).entries.map((e) => _createParam(e, 'path')));
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
    params.addAll((result.value[bodyKey] as Map<String, dynamic>).entries.map((e) => _createParam(e, 'form')));
  }
  return FormUrlEncodedBody(params: params);
}

Body? parseBodyMultipartForm(Result<dynamic> result) {
  const bodyKey = 'body:multipart-form';
  if (result.value[bodyKey] == null) return null;

  List<Param> params = [];
  if (result.value[bodyKey] != null) {
    params.addAll((result.value[bodyKey] as Map<String, dynamic>).entries.map((e) => _createParam(e, 'form')));
  }
  return MultipartFormBody(params: params);
}

Body? parseBodyFile(Result<dynamic> result) {
  const bodyKey = 'body:file';
  if (result.value[bodyKey] == null) return null;

  List<FileBodyItem> files = [];
  final bodyFiles = result.value['body:file'];
  if (bodyFiles != null) {
    if (bodyFiles['file'] != null) {
      final selectedFiles = bodyFiles['file'] as List<String>;
      files.addAll(selectedFiles.map((e) => FileBodyItem.fromBruLine(e, true)));
    }
    if (bodyFiles['~file'] != null) {
      final unSelectedFiles = bodyFiles['~file'] as List<dynamic>;
      files.addAll(unSelectedFiles.map((e) => FileBodyItem.fromBruLine(e, false)));
    }
  }
  return FileBody(files: files);
}

Auth? parseAuth(Result<dynamic> result, String? authType) {
  if (authType == null) return null;

  // Map authType to the correct key in the parsed result
  String? authKey;
  switch (authType) {
    case 'awsv4':
      authKey = 'auth:awsv4';
      break;
    case 'basic':
      authKey = 'auth:basic';
      break;
    case 'bearer':
      authKey = 'auth:bearer';
      break;
    case 'digest':
      authKey = 'auth:digest';
      break;
    case 'oauth2':
      authKey = 'auth:oauth2';
      break;
    case 'wsse':
      authKey = 'auth:wsse';
      break;
    // Add more cases as needed
    default:
      authKey = null;
  }

  Auth? auth;
  if (authKey != null && result.value[authKey] != null) {
    final authBlock = result.value[authKey];
    switch (authType) {
      case 'awsv4':
        auth = AwsV4Auth(
          accessKeyId: authBlock['accessKeyId'] ?? '',
          secretAccessKey: authBlock['secretAccessKey'] ?? '',
          sessionToken: authBlock['sessionToken'] ?? '',
          service: authBlock['service'] ?? '',
          region: authBlock['region'] ?? '',
          profileName: authBlock['profileName'] ?? '',
        );
        break;
      case 'basic':
        auth = BasicAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
        break;
      case 'bearer':
        auth = BearerAuth(token: authBlock['token'] ?? '');
        break;
      case 'digest':
        auth = DigestAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
        break;
      case 'oauth2':
        auth = OAuth2Auth(
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
        break;
      case 'wsse':
        auth = WsseAuth(username: authBlock['username'] ?? '', password: authBlock['password'] ?? '');
        break;
      // Add more cases as needed
    }
  }

  return auth;
}
