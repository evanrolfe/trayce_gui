import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:trayce/editor/models/multipart_file.dart';

import 'assertion.dart';
import 'auth.dart';
import 'body.dart';
import 'header.dart';
import 'param.dart';
import 'script.dart';
import 'utils.dart';
import 'variable.dart';

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

class Request {
  String name;
  String type;
  int seq;
  String method;
  String url;
  String? tests;
  String? docs;
  BodyType bodyType;
  Auth? auth;

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

  Request({
    required this.name,
    required this.type,
    required this.seq,
    required this.method,
    required this.url,
    required this.bodyType,
    this.auth,
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
  });

  static Request blank() {
    return Request(
      name: '',
      type: 'http',
      seq: 0,
      method: 'get',
      url: '',
      bodyType: BodyType.none,
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

    if (auth != null) {
      bru += '\n  auth: ${auth!.type}';
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

    // Convert auth to bru
    if (auth != null) {
      bru += '\n${auth!.toBru()}\n';
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
    if (bodyType != other.bodyType) {
      return false;
    }

    final body = getBody();
    final otherBody = other.getBody();

    final bodyEmpty = body == null || body.isEmpty();
    final otherBodyEmpty = otherBody == null || otherBody.isEmpty();

    if (bodyEmpty && !otherBodyEmpty) return false;
    if (!bodyEmpty && otherBodyEmpty) return false;

    if (!bodyEmpty && !otherBodyEmpty) {
      if (!body.equals(otherBody)) return false;
    }

    // Compare headers
    if (headers.length != other.headers.length) return false;

    for (var i = 0; i < headers.length; i++) {
      if (!headers[i].equals(other.headers[i])) {
        return false;
      }
    }

    // Compare auth
    // if ((auth == null) != (other.auth == null)) return false;
    // if (auth != null && !auth!.equals(other.auth!)) return false;

    // Compare params
    // if (params.length != other.params.length) return false;
    // for (var i = 0; i < params.length; i++) {
    //   if (!params[i].equals(other.params[i])) return false;
    // }

    // Compare request variables
    if (requestVars.length != other.requestVars.length) return false;

    for (var i = 0; i < requestVars.length; i++) {
      if (!requestVars[i].equals(other.requestVars[i])) {
        return false;
      }
    }

    // if (requestVars.length != other.requestVars.length) return false;
    // for (var i = 0; i < requestVars.length; i++) {
    //   if (!requestVars[i].equals(other.requestVars[i])) return false;
    // }

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
    // if ((script == null) != (other.script == null)) return false;
    // if (script != null && !script!.equals(other.script!)) return false;

    return true;
  }

  Future<http.Response> send() async {
    if (bodyType == BodyType.multipartForm) {
      return _sendMultipart();
    }

    if (bodyType == BodyType.file) {
      return _sendFile();
    }

    final request = http.Request(method, Uri.parse(url));

    request.headers.addAll(Map.fromEntries(headers.where((h) => h.enabled).map((h) => MapEntry(h.name, h.value))));

    final body = getBody();
    if (body != null) {
      request.body = body.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response;
  }

  Future<http.Response> _sendMultipart() async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    request.headers.addAll(Map.fromEntries(headers.where((h) => h.enabled).map((h) => MapEntry(h.name, h.value))));

    final multipartBody = bodyMultipartForm as MultipartFormBody;
    for (var file in multipartBody.files) {
      if (file.enabled) {
        request.files.add(
          await http.MultipartFile.fromPath(
            file.name,
            file.value,
            contentType: file.contentType != null ? MediaType.parse(file.contentType!) : null,
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response;
  }

  Future<http.Response> _sendFile() async {
    final request = http.Request(method, Uri.parse(url));

    final body = bodyFile as FileBody;
    final selectedFile = body.selectedFile();
    if (selectedFile != null) {
      final data = await File(selectedFile.filePath).readAsBytes();
      request.bodyBytes = data;

      if (selectedFile.contentType != null) {
        request.headers['content-type'] = selectedFile.contentType!;
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response;
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

  void copyValuesFrom(Request request) {
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
    // TODO: This should deep copy the auth
    auth = request.auth;

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
    script = request.script;
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

  void setBodyType(BodyType bodyType) {
    this.bodyType = bodyType;
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
