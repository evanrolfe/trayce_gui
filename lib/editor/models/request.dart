import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/parse/parse_url.dart';
import 'package:trayce/editor/models/send_result.dart';
import 'package:uuid/uuid.dart';

import 'assertion.dart';
import 'auth.dart';
import 'body.dart';
import 'header.dart';
import 'param.dart';
import 'script.dart';
import 'utils.dart';
import 'variable.dart';

// TODO: Move these enums to the body.dart and auth.dart
enum BodyType { none, text, json, xml, sparql, graphql, formUrlEncoded, multipartForm, file }

final bodyTypeEnumToBru = {
  BodyType.none: '',
  BodyType.text: 'text',
  BodyType.json: 'json',
  BodyType.xml: 'xml',
  BodyType.sparql: 'sparql',
  BodyType.graphql: 'graphql',
  BodyType.formUrlEncoded: 'form-urlencoded',
  BodyType.multipartForm: 'multipart-form',
  BodyType.file: 'file',
};

enum AuthType { none, apikey, awsV4, basic, bearer, digest, oauth2, wsse, inherit }

final authTypeEnumToBru = {
  AuthType.none: 'none',
  AuthType.apikey: 'apikey',
  AuthType.awsV4: 'awsv4',
  AuthType.basic: 'basic',
  AuthType.bearer: 'bearer',
  AuthType.digest: 'digest',
  AuthType.oauth2: 'oauth2',
  AuthType.wsse: 'wsse',
  AuthType.inherit: 'inherit',
};

class Request {
  // file properties:
  File? file;
  String name;

  // .bru properties:
  String type;
  int seq;
  String method;
  String url;
  String? tests;
  String? docs;
  BodyType bodyType;
  AuthType authType;

  List<Param> params;
  List<Header> headers;

  List<Variable> requestVars;
  List<Variable> responseVars;

  List<Assertion> assertions;

  Script? script;

  // All Body types
  Body? bodyText;
  Body? bodyJson;
  Body? bodyXml;
  Body? bodySparql;
  Body? bodyGraphql;
  Body? bodyFormUrlEncoded;
  Body? bodyMultipartForm;
  Body? bodyFile;

  // All Auth types
  Auth? authApiKey;
  Auth? authAwsV4;
  Auth? authBasic;
  Auth? authBearer;
  Auth? authDigest;
  Auth? authOauth2;
  Auth? authWsse;

  Duration _timeout = Duration(seconds: 10);
  String _executionMode = 'standalone';
  String _executionPlatform = 'app';

  Request({
    this.file,
    required this.name,
    required this.type,
    required this.seq,
    required this.method,
    required this.url,
    required this.bodyType,
    required this.authType,
    required this.params,
    required this.headers,
    required this.requestVars,
    required this.responseVars,
    required this.assertions,
    this.script,
    this.tests,
    this.docs,

    // All Body types
    this.bodyText,
    this.bodyJson,
    this.bodyXml,
    this.bodySparql,
    this.bodyGraphql,
    this.bodyFormUrlEncoded,
    this.bodyMultipartForm,
    this.bodyFile,

    // All Auth types
    this.authApiKey,
    this.authAwsV4,
    this.authBasic,
    this.authBearer,
    this.authDigest,
    this.authOauth2,
    this.authWsse,
  });

  static Request blank() {
    return Request(
      name: '',
      type: 'http',
      seq: 0,
      method: 'get',
      url: '',
      bodyType: BodyType.none,
      authType: AuthType.none,
      params: [],
      headers: [],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );
  }

  String toBru() {
    var bru = '';

    // Convert meta to bru
    bru += 'meta {\n';
    bru += '  name: $name\n';
    bru += '  type: $type\n';
    bru += '  seq: $seq\n';
    bru += '}\n\n';

    // Convert request to bru
    bru += '$method {\n';
    bru += '  url: $url';

    if (bodyType != BodyType.none) {
      bru += '\n  body: ${bodyTypeEnumToBru[bodyType]}';
    }

    if (authType != AuthType.none) {
      bru += '\n  auth: ${authTypeEnumToBru[authType]}';
    }

    bru += '\n}\n';

    // Convert params to bru
    final queryParams = params.where((p) => p.type == ParamType.query).toList();
    if (queryParams.isNotEmpty) {
      bru += '\n${queryParamsToBru(queryParams)}\n';
    }

    final pathParams = params.where((p) => p.type == ParamType.path).toList();
    if (pathParams.isNotEmpty) {
      bru += '\n${pathParamsToBru(pathParams)}\n';
    }

    // Convert headers to bru
    if (headers.isNotEmpty) {
      bru += '\n${headersToBru(headers)}\n';
    }

    // Convert auth(s) to bru
    if (authApiKey != null && !authApiKey!.isEmpty()) {
      bru += '\n${authApiKey!.toBru()}\n';
    }
    if (authAwsV4 != null && !authAwsV4!.isEmpty()) {
      bru += '\n${authAwsV4!.toBru()}\n';
    }
    if (authBasic != null && !authBasic!.isEmpty()) {
      bru += '\n${authBasic!.toBru()}\n';
    }
    if (authBearer != null && !authBearer!.isEmpty()) {
      bru += '\n${authBearer!.toBru()}\n';
    }
    if (authDigest != null && !authDigest!.isEmpty()) {
      bru += '\n${authDigest!.toBru()}\n';
    }
    if (authOauth2 != null && !authOauth2!.isEmpty()) {
      bru += '\n${authOauth2!.toBru()}\n';
    }
    if (authWsse != null && !authWsse!.isEmpty()) {
      bru += '\n${authWsse!.toBru()}\n';
    }

    // Convert body(s) to bru
    if (bodyText != null && !bodyText!.isEmpty()) {
      bru += '\n${bodyText!.toBru()}\n';
    }
    if (bodyJson != null && !bodyJson!.isEmpty()) {
      bru += '\n${bodyJson!.toBru()}\n';
    }
    if (bodyXml != null && !bodyXml!.isEmpty()) {
      bru += '\n${bodyXml!.toBru()}\n';
    }
    if (bodySparql != null && !bodySparql!.isEmpty()) {
      bru += '\n${bodySparql!.toBru()}\n';
    }
    if (bodyGraphql != null && !bodyGraphql!.isEmpty()) {
      bru += '\n${bodyGraphql!.toBru()}\n';
    }
    if (bodyFormUrlEncoded != null && !bodyFormUrlEncoded!.isEmpty()) {
      bru += '\n${bodyFormUrlEncoded!.toBru()}\n';
    }
    if (bodyMultipartForm != null && !bodyMultipartForm!.isEmpty()) {
      bru += '\n${bodyMultipartForm!.toBru()}\n';
    }
    if (bodyFile != null && !bodyFile!.isEmpty()) {
      bru += '\n${bodyFile!.toBru()}\n';
    }

    // Convert variables to bru
    if (requestVars.isNotEmpty) {
      bru += '\n${variablesToBru(requestVars, 'vars:pre-request')}\n';
    }

    if (responseVars.isNotEmpty) {
      bru += '\n${variablesToBru(responseVars, 'vars:post-response')}\n';
    }

    // Convert assertions to bru
    if (assertions.isNotEmpty) {
      bru += '\n${assertionsToBru(assertions)}\n';
    }

    // Convert script to bru
    if (script != null) {
      if (script!.req != null && script!.req!.isNotEmpty) {
        bru += '\nscript:pre-request {\n${indentString(script!.req!)}\n}\n';
      }

      if (script!.res != null && script!.res!.isNotEmpty) {
        bru += '\nscript:post-response {\n${indentString(script!.res!)}\n}\n';
      }
    }

    // Convert tests to bru
    if (tests != null && tests!.isNotEmpty) {
      bru += '\ntests {\n${indentString(tests!)}\n}\n';
    }

    // Convert docs to bru
    if (docs != null && docs!.isNotEmpty) {
      bru += '\ndocs {\n${indentString(docs!)}\n}\n';
    }

    return bru;
  }

  bool equals(Request other) {
    // tests != other.tests ||
    //         docs != other.docs

    if (name != other.name || type != other.type || seq != other.seq || method != other.method || url != other.url) {
      return false;
    }

    // Compare body
    if (bodyType != other.bodyType) return false;

    final body = getBody();
    final otherBody = other.getBody();

    final bodyEmpty = body == null || body.isEmpty();
    final otherBodyEmpty = otherBody == null || otherBody.isEmpty();

    if (bodyEmpty && !otherBodyEmpty) return false;
    if (!bodyEmpty && otherBodyEmpty) return false;

    if (!bodyEmpty && !otherBodyEmpty) {
      if (!body.equals(otherBody)) return false;
    }

    // Compare auth
    if (authType != other.authType) return false;

    final auth = getAuth();
    final otherAuth = other.getAuth();

    final authEmpty = auth == null || auth.isEmpty();
    final otherauthEmpty = otherAuth == null || otherAuth.isEmpty();

    if (authEmpty && !otherauthEmpty) return false;
    if (!authEmpty && otherauthEmpty) return false;

    if (!authEmpty && !otherauthEmpty) {
      if (!auth.equals(otherAuth)) return false;
    }

    // Compare headers
    if (headers.length != other.headers.length) return false;

    for (var i = 0; i < headers.length; i++) {
      if (!headers[i].equals(other.headers[i])) {
        return false;
      }
    }

    // Compare request variables
    if (requestVars.length != other.requestVars.length) return false;

    for (var i = 0; i < requestVars.length; i++) {
      if (!requestVars[i].equals(other.requestVars[i])) {
        return false;
      }
    }

    // Compare response variables
    // if (responseVars.length != other.responseVars.length) return false;
    // for (var i = 0; i < responseVars.length; i++) {
    //   if (!responseVars[i].equals(other.responseVars[i])) return false;
    // }

    // Compare assertions
    // if (assertions.length != other.assertions.length) return false;
    // for (var i = 0; i < assertions.length; i++) {
    //   if (!assertions[i].equals(other.assertions[i])) return false;
    // }

    // Compare script
    final scriptEmpty = script == null || script!.isEmpty();
    final otherScriptEmpty = other.script == null || other.script!.isEmpty();
    if (scriptEmpty && !otherScriptEmpty) return false;
    if (!scriptEmpty && otherScriptEmpty) return false;

    if (!scriptEmpty && !otherScriptEmpty) {
      if (!script!.equals(other.script!)) return false;
    }
    return true;
  }

  void setQueryParamsOnURL(List<Param> params) {
    final queryString = buildURLQueryString(params);
    final uri = Uri.tryParse(url);
    if (uri != null) {
      // Rebuild the URI with the new query string
      final newUri = uri.replace(query: queryString);
      url = newUri.toString();
    } else {
      // If url is not a valid URI, just append the query string
      if (url.contains('?')) {
        url = url.split('?')[0] + (queryString.isNotEmpty ? '?$queryString' : '');
      } else {
        url = url + (queryString.isNotEmpty ? '?$queryString' : '');
      }
    }

    // Uri.parse will url-encode the {{ and }} around any vars in the url, so we need
    // to manually decode them
    url = url.replaceAll('%7B%7B', '{{').replaceAll('%7D%7D', '}}');
  }

  void interpolatePathParams() {
    final pathParams = getPathParams();
    for (final param in pathParams) {
      url = url.replaceAll(':${param.name}', param.value);
    }
  }

  void setQueryParams(List<Param> newParams) {
    final pathParams = getPathParams();
    params = newParams + pathParams;
  }

  void setPathParams(List<Param> newParams) {
    final queryParams = getQueryParams();
    params = newParams + queryParams;
  }

  List<Param> getQueryParams() {
    return params.where((p) => p.type == ParamType.query).toList();
  }

  List<Param> getPathParams() {
    return params.where((p) => p.type == ParamType.path).toList();
  }

  List<Param> getQueryParamsFromURL() {
    return parseUrlQueryParams(url);
  }

  List<Param> getPathParamsFromURL() {
    return parseUrlPathParams(url);
  }

  Future<SendResult> send() async {
    if (bodyType == BodyType.multipartForm) {
      return _sendMultipart();
    }

    if (bodyType == BodyType.file) {
      return _sendFile();
    }

    final output = await _executePreRequestScript();

    String urlStr = _getInterpolatedString(url);
    urlStr = _addApiKeyAuthToUrl(urlStr);
    final request = http.Request(method, Uri.parse(urlStr));

    _addHeaders(request);
    _addApiKeyAuth(request);
    _addBasicAuth(request);
    _addBearerAuth(request);

    // Set the request body
    Body? body = getBody();
    if (body != null) {
      // Interpolate FormUrlEncodedBody params
      if (body is FormUrlEncodedBody) {
        body = body.deepCopy();
        (body as FormUrlEncodedBody).setParams(
          body.params
              .map(
                (p) => Param(
                  name: _getInterpolatedString(p.name),
                  value: _getInterpolatedString(p.value),
                  type: p.type,
                  enabled: p.enabled,
                ),
              )
              .toList(),
        );
      }
      request.body = _getInterpolatedString(body.toString());
    }

    final client = http.Client();
    final startTime = DateTime.now();
    final streamedResponse = await client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    client.close();

    final result2 = await _executePostResponseScript(response, responseTime);
    output.addAll(result2.output);

    return SendResult(response: result2.response, output: output, responseTime: responseTime);
  }

  String _httpResponseToJson(http.Response response, int responseTime) {
    // Calculate header bytes by encoding each header key-value pair
    int headerBytes = 0;
    response.headers.forEach((key, value) {
      headerBytes += utf8.encode('$key: $value\r\n').length;
    });

    // Calculate body bytes
    int bodyBytes = utf8.encode(response.body).length;

    return jsonEncode({
      'url': response.request?.url.toString(),
      'status': response.statusCode,
      'statusText': response.reasonPhrase,
      'headers': response.headers,
      'body': response.body,
      'size': {'body': bodyBytes, 'headers': headerBytes, 'total': bodyBytes + headerBytes},
      'responseTime': responseTime,
    });
  }

  Future<List<String>> _executePreRequestScript() async {
    final script = this.script;
    if (script == null || script.req == null || script.req!.isEmpty) return [];

    final preReqScript = script.req!;

    // Generate a random UUID
    final uuid = Uuid().v4();
    final tempDir = Directory('/tmp');
    final scriptFile = File('/tmp/trayce_pre_req-$uuid.js');

    try {
      // Ensure /tmp directory exists
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      // Write the script content to the file
      scriptFile.writeAsStringSync(preReqScript);

      // Run the CLI command
      final result = await Process.run('node', ['script_req.js', scriptFile.path, toJson()]);

      final output = <String>[];

      if (result.exitCode == 0) {
        if (result.stdout.isNotEmpty) {
          output.addAll(result.stdout.toString().split('\n').where((line) => line.isNotEmpty));

          processScriptOutputRequest(output.last);
          output.removeLast();
        }
      } else {
        if (result.stderr.isNotEmpty) {
          output.addAll(result.stderr.toString().split('\n').where((line) => line.isNotEmpty));
        }
      }

      return output;
    } catch (e) {
      return ['Failed to execute pre-request script: $e'];
    }
  }

  Future<SendResult> _executePostResponseScript(http.Response response, int responseTime) async {
    final script = this.script;
    if (script == null || script.res == null || script.res!.isEmpty) {
      return SendResult(response: response, output: [], responseTime: responseTime);
    }

    final postRespScript = script.res!;

    // Generate a random UUID
    final uuid = Uuid().v4();
    final tempDir = Directory('/tmp');
    final scriptFile = File('/tmp/trayce_post_resp-$uuid.js');

    try {
      // Ensure /tmp directory exists
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      // Write the script content to the file
      scriptFile.writeAsStringSync(postRespScript);

      // Run the CLI command
      final result = await Process.run('node', [
        'script_req.js',
        scriptFile.path,
        toJson(),
        _httpResponseToJson(response, responseTime),
      ]);

      final output = <String>[];

      if (result.exitCode == 0) {
        if (result.stdout.isNotEmpty) {
          output.addAll(result.stdout.toString().split('\n').where((line) => line.isNotEmpty));

          response = processScriptOutputResponse(response, output.last);
          output.removeLast();
        }
      } else {
        if (result.stderr.isNotEmpty) {
          output.addAll(result.stderr.toString().split('\n').where((line) => line.isNotEmpty));
        }
      }

      return SendResult(response: response, output: output, responseTime: responseTime);
    } catch (e) {
      return SendResult(
        response: response,
        output: ['Failed to execute post-response script: $e'],
        responseTime: responseTime,
      );
    }
  }

  void processScriptOutputRequest(String output) {
    final json = jsonDecode(output);
    if (json['url'] != null) {
      url = json['url'];
    }
    if (json['method'] != null) {
      method = json['method'].toString().toLowerCase();
    }
    if (json['timeout'] != null) {
      _timeout = Duration(milliseconds: json['timeout']);
    }
    if (json['headers'] != null) {
      final headersMap = json['headers'] as Map<String, dynamic>;
      headers =
          headersMap.entries
              .map((entry) => Header(name: entry.key, value: entry.value.toString(), enabled: true))
              .toList();
    }
    if (json['body'] != null) {
      final body = getBody();
      if (body != null) {
        if (body is JsonBody) {
          body.setContent(jsonEncode(json['body']));
        } else {
          body.setContent(json['body']);
        }
      }
    }
  }

  http.Response processScriptOutputResponse(http.Response response, String output) {
    final json = jsonDecode(output);

    if (json['body'] != null) {
      // Create a new response with the modified body
      return http.Response(
        json['body'],
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
      );
    }

    return response;
  }

  String _getInterpolatedString(String value) {
    final regex = RegExp(r'\{\{(.*?)\}\}');
    value = value.replaceAllMapped(regex, (match) {
      final varName = match.group(1);
      final variable = requestVars.firstWhere(
        (v) => v.name == varName && v.enabled,
        orElse: () => Variable(name: varName ?? '', value: null, enabled: false),
      );
      return variable.enabled && variable.value != null ? variable.value! : match.group(0)!;
    });
    return value;
  }

  void _addHeaders(http.BaseRequest request) {
    request.headers.addAll(
      Map.fromEntries(
        headers
            .where((h) => h.enabled)
            .map((h) => MapEntry(_getInterpolatedString(h.name), _getInterpolatedString(h.value))),
      ),
    );
  }

  String _addApiKeyAuthToUrl(String url) {
    if (authType != AuthType.apikey || authApiKey == null) return url;
    final auth = authApiKey as ApiKeyAuth;
    final key = _getInterpolatedString(auth.key);
    final value = _getInterpolatedString(auth.value);

    if (auth.placement != ApiKeyPlacement.queryparams) return url;

    if (url.contains('?')) {
      url = '$url&$key=$value';
    } else {
      url = '$url?$key=$value';
    }

    return url;
  }

  void _addApiKeyAuth(http.BaseRequest request) {
    if (authType != AuthType.apikey || authApiKey == null) return;
    final auth = authApiKey as ApiKeyAuth;
    final key = _getInterpolatedString(auth.key);
    final value = _getInterpolatedString(auth.value);

    if (auth.placement != ApiKeyPlacement.header) return;

    request.headers[key] = value;
  }

  void _addBasicAuth(http.BaseRequest request) {
    if (authType != AuthType.basic || authBasic == null) return;

    final basicAuth = authBasic as BasicAuth;
    final username = _getInterpolatedString(basicAuth.username);
    final password = _getInterpolatedString(basicAuth.password);
    if (username.isNotEmpty || password.isNotEmpty) {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));
      request.headers['Authorization'] = 'Basic $encoded';
    }
  }

  void _addBearerAuth(http.BaseRequest request) {
    if (authType != AuthType.bearer || authBearer == null) return;

    final bearerAuth = authBearer as BearerAuth;
    final token = _getInterpolatedString(bearerAuth.token);
    request.headers['Authorization'] = 'Bearer $token';
  }

  Future<SendResult> _sendMultipart() async {
    final request = http.MultipartRequest(method, Uri.parse(_getInterpolatedString(url)));
    _addHeaders(request);
    _addBasicAuth(request);
    _addBearerAuth(request);
    final output = await _executePreRequestScript();

    final multipartBody = bodyMultipartForm as MultipartFormBody;
    for (var file in multipartBody.files) {
      if (file.enabled) {
        MediaType? contentType;
        if (file.contentType != null) contentType = MediaType.parse(_getInterpolatedString(file.contentType!));

        request.files.add(
          await http.MultipartFile.fromPath(_getInterpolatedString(file.name), file.value, contentType: contentType),
        );
      }
    }

    final client = http.Client();
    final startTime = DateTime.now();
    final streamedResponse = await client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    client.close();

    final result2 = await _executePostResponseScript(response, responseTime);
    output.addAll(result2.output);

    return SendResult(response: result2.response, output: output, responseTime: responseTime);
  }

  Future<SendResult> _sendFile() async {
    final request = http.Request(method, Uri.parse(_getInterpolatedString(url)));

    _addHeaders(request);
    _addBasicAuth(request);
    _addBearerAuth(request);
    final output = await _executePreRequestScript();

    final body = bodyFile as FileBody;
    final selectedFile = body.selectedFile();
    if (selectedFile != null) {
      final data = await File(selectedFile.filePath).readAsBytes();
      request.bodyBytes = data;

      if (selectedFile.contentType != null) {
        request.headers['content-type'] = _getInterpolatedString(selectedFile.contentType!);
      }
    }

    final client = http.Client();
    final startTime = DateTime.now();
    final streamedResponse = await client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    client.close();

    final result2 = await _executePostResponseScript(response, responseTime);
    output.addAll(result2.output);

    return SendResult(response: result2.response, output: output, responseTime: responseTime);
  }

  Body? getBody() {
    switch (bodyType) {
      case BodyType.json:
        return bodyJson;
      case BodyType.text:
        return bodyText;
      case BodyType.xml:
        return bodyXml;
      case BodyType.sparql:
        return bodySparql;
      case BodyType.graphql:
        return bodyGraphql;
      case BodyType.formUrlEncoded:
        return bodyFormUrlEncoded;
      case BodyType.multipartForm:
        return bodyMultipartForm;
      case BodyType.file:
        return bodyFile;
      case BodyType.none:
        return null;
    }
  }

  Auth? getAuth() {
    switch (authType) {
      case AuthType.apikey:
        return authApiKey;
      case AuthType.awsV4:
        return authAwsV4;
      case AuthType.basic:
        return authBasic;
      case AuthType.bearer:
        return authBearer;
      case AuthType.digest:
        return authDigest;
      case AuthType.oauth2:
        return authOauth2;
      case AuthType.wsse:
        return authWsse;
      case AuthType.inherit:
        // TODO: Implement inherit auth
        return null;
      case AuthType.none:
        return null;
    }
  }

  void setAuth(Auth auth) {
    switch (authType) {
      case AuthType.apikey:
        authApiKey = auth;
        break;
      case AuthType.awsV4:
        authAwsV4 = auth;
        break;
      case AuthType.basic:
        authBasic = auth;
        break;
      case AuthType.bearer:
        authBearer = auth;
        break;
      case AuthType.digest:
        authDigest = auth;
        break;
      case AuthType.oauth2:
        authOauth2 = auth;
        break;
      case AuthType.wsse:
        authWsse = auth;
        break;
      case AuthType.inherit:
        break;
      case AuthType.none:
        break;
    }
  }

  void copyValuesFrom(Request request) {
    file = request.file;

    name = request.name;
    type = request.type;
    seq = request.seq;
    method = request.method;
    url = request.url;
    tests = request.tests;
    docs = request.docs;

    // Copy body if it exists
    bodyType = request.bodyType;
    if (request.bodyJson != null) {
      bodyJson = request.bodyJson!.deepCopy();
    }
    if (request.bodyText != null) {
      bodyText = request.bodyText!.deepCopy();
    }
    if (request.bodyXml != null) {
      bodyXml = request.bodyXml!.deepCopy();
    }
    if (request.bodySparql != null) {
      bodySparql = request.bodySparql!.deepCopy();
    }
    if (request.bodyGraphql != null) {
      bodyGraphql = request.bodyGraphql!.deepCopy();
    }
    if (request.bodyFormUrlEncoded != null) {
      bodyFormUrlEncoded = request.bodyFormUrlEncoded!.deepCopy();
    }
    if (request.bodyMultipartForm != null) {
      bodyMultipartForm = request.bodyMultipartForm!.deepCopy();
    }
    if (request.bodyFile != null) {
      bodyFile = request.bodyFile!.deepCopy();
    }

    // Copy auth if it exists
    authType = request.authType;
    if (request.authApiKey != null) {
      authApiKey = request.authApiKey!.deepCopy();
    }
    if (request.authAwsV4 != null) {
      authAwsV4 = request.authAwsV4!.deepCopy();
    }
    if (request.authBasic != null) {
      authBasic = request.authBasic!.deepCopy();
    }
    if (request.authBearer != null) {
      authBearer = request.authBearer!.deepCopy();
    }
    if (request.authDigest != null) {
      authDigest = request.authDigest!.deepCopy();
    }
    if (request.authOauth2 != null) {
      authOauth2 = request.authOauth2!.deepCopy();
    }
    if (request.authWsse != null) {
      authWsse = request.authWsse!.deepCopy();
    }

    // Copy params
    params = List.from(request.params);

    // Copy headers
    headers = List.from(request.headers);

    // Copy variables
    requestVars = List.from(request.requestVars);
    responseVars = List.from(request.responseVars);

    // Copy assertions
    assertions = List.from(request.assertions);

    // Copy script if it exists
    if (request.script != null) {
      script = request.script!.deepCopy();
    }
  }

  void setUrl(String url) {
    this.url = url;
  }

  void setMethod(String method) {
    this.method = method;
  }

  void setHeaders(List<Header> headers) {
    this.headers = headers;
  }

  void setRequestVars(List<Variable> vars) {
    requestVars = vars;
  }

  void setAuthType(AuthType authType) {
    this.authType = authType;
  }

  void setBodyType(BodyType bodyType) {
    this.bodyType = bodyType;
  }

  void setPreRequest(String preRequest) {
    if (script == null) {
      script = Script(req: preRequest);
    } else {
      script!.req = preRequest;
    }
  }

  void setPostResponse(String postResponse) {
    if (script == null) {
      script = Script(res: postResponse);
    } else {
      script!.res = postResponse;
    }
  }

  void setBodyContent(String content) {
    switch (bodyType) {
      case BodyType.json:
        bodyJson ??= JsonBody(content: '');
        bodyJson?.setContent(content);
        break;
      case BodyType.text:
        bodyText ??= TextBody(content: '');
        bodyText?.setContent(content);
        break;
      case BodyType.xml:
        bodyXml ??= XmlBody(content: '');
        bodyXml?.setContent(content);
        break;
      case BodyType.sparql:
        bodySparql ??= SparqlBody(content: '');
        bodySparql?.setContent(content);
        break;
      case BodyType.graphql:
        bodyGraphql ??= GraphqlBody(query: '', variables: '');
        bodyGraphql?.setContent(content);
        break;
      case BodyType.formUrlEncoded:
        bodyFormUrlEncoded ??= FormUrlEncodedBody(params: []);
        bodyFormUrlEncoded?.setContent(content);
        break;
      case BodyType.multipartForm:
        bodyMultipartForm ??= MultipartFormBody(files: []);
        bodyMultipartForm?.setContent(content);
        break;
      case BodyType.file:
        bodyFile ??= FileBody(files: []);
        bodyFile?.setContent(content);
        break;
      case BodyType.none:
        break;
    }
  }

  void setBodyFormURLEncodedContent(List<Param> params) {
    bodyFormUrlEncoded ??= FormUrlEncodedBody(params: []);
    (bodyFormUrlEncoded as FormUrlEncodedBody).setParams(params);
  }

  void setBodyMultipartFormContent(List<MultipartFile> files) {
    bodyMultipartForm ??= MultipartFormBody(files: []);
    (bodyMultipartForm as MultipartFormBody).setFiles(files);
  }

  void setBodyFilesContent(List<FileBodyItem> files) {
    bodyFile ??= FileBody(files: []);
    (bodyFile as FileBody).setFiles(files);
  }

  String toJson() {
    final headersMap = Map.fromEntries(headers.where((h) => h.enabled).map((h) => MapEntry(h.name, h.value)));
    final Map<String, dynamic> json = {
      'name': name,
      'method': method.toUpperCase(),
      'url': url,
      'headers': headersMap,
      'authMode': authTypeEnumToBru[authType]!,
      'mode': bodyType == BodyType.none ? 'none' : bodyTypeEnumToBru[bodyType]!,
      'vars': requestVars.map((v) => jsonDecode(v.toJson())).toList(),
      'timeout': _timeout.inMilliseconds,
      'executionMode': _executionMode,
      'executionPlatform': _executionPlatform,
    };

    // Add auth if present
    final auth = getAuth();
    if (auth != null && !auth.isEmpty()) {
      json['auth'] = jsonDecode(auth.toJson());
    }

    // Add body if present
    final body = getBody();
    if (body != null && !body.isEmpty()) {
      json['body'] = body.toString();
    }

    return jsonEncode(json);
  }
}

String queryParamsToBru(List<Param> params) {
  String bru = '';

  bru += 'params:query {';

  final enabledParams = params.where((p) => p.enabled).toList();
  if (enabledParams.isNotEmpty) {
    bru += '\n${indentString(enabledParams.map((item) => '${item.name}: ${item.value}').join('\n'))}';
  }

  final disabledParams = params.where((p) => !p.enabled).toList();
  if (disabledParams.isNotEmpty) {
    bru += '\n${indentString(disabledParams.map((item) => '~${item.name}: ${item.value}').join('\n'))}';
  }

  bru += '\n}';

  return bru;
}

String pathParamsToBru(List<Param> params) {
  String bru = 'params:path {';
  bru += '\n${indentString(params.map((item) => '${item.name}: ${item.value}').join('\n'))}';
  bru += '\n}';
  return bru;
}

String headersToBru(List<Header> headers) {
  String bru = 'headers {';

  final enabledHeaders = headers.where((h) => h.enabled).toList();
  if (enabledHeaders.isNotEmpty) {
    bru += '\n${indentString(enabledHeaders.map((item) => '${item.name}: ${item.value}').join('\n'))}';
  }

  final disabledHeaders = headers.where((h) => !h.enabled).toList();
  if (disabledHeaders.isNotEmpty) {
    bru += '\n${indentString(disabledHeaders.map((item) => '~${item.name}: ${item.value}').join('\n'))}';
  }

  bru += '\n}';

  return bru;
}

String variablesToBru(List<Variable> vars, String bruKey) {
  String bru = '';

  final varsEnabled = vars.where((v) => v.enabled && !v.local).toList();
  final varsDisabled = vars.where((v) => !v.enabled && !v.local).toList();
  final varsLocalEnabled = vars.where((v) => v.enabled && v.local).toList();
  final varsLocalDisabled = vars.where((v) => !v.enabled && v.local).toList();

  bru += '$bruKey {';

  if (varsEnabled.isNotEmpty) {
    bru += '\n${indentString(varsEnabled.map((item) => '${item.name}: ${item.value}').join('\n'))}';
  }

  if (varsLocalEnabled.isNotEmpty) {
    bru += '\n${indentString(varsLocalEnabled.map((item) => '@${item.name}: ${item.value}').join('\n'))}';
  }

  if (varsDisabled.isNotEmpty) {
    bru += '\n${indentString(varsDisabled.map((item) => '~${item.name}: ${item.value}').join('\n'))}';
  }

  if (varsLocalDisabled.isNotEmpty) {
    bru += '\n${indentString(varsLocalDisabled.map((item) => '~@${item.name}: ${item.value}').join('\n'))}';
  }

  bru += '\n}';

  return bru;
}

String assertionsToBru(List<Assertion> assertions) {
  String bru = '';

  bru += 'assert {';

  final enabledAssertions = assertions.where((a) => a.enabled).toList();
  if (enabledAssertions.isNotEmpty) {
    bru += '\n${indentString(enabledAssertions.map((item) => '${item.name}: ${item.value}').join('\n'))}';
  }

  final disabledAssertions = assertions.where((a) => !a.enabled).toList();
  if (disabledAssertions.isNotEmpty) {
    bru += '\n${indentString(disabledAssertions.map((item) => '~${item.name}: ${item.value}').join('\n'))}';
  }

  bru += '\n}';

  return bru;
}
