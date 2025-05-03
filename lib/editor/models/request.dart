import 'assertion.dart';
import 'auth.dart';
import 'body.dart';
import 'header.dart';
import 'param.dart';
import 'script.dart';
import 'utils.dart';
import 'variable.dart';

class Request {
  String name;
  String type;
  int seq;
  String method;
  String url;
  String? tests;
  String? docs;
  Body? body;
  Auth? auth;

  List<Param> params;
  List<Header> headers;

  List<Variable> requestVars;
  List<Variable> responseVars;

  List<Assertion> assertions;

  Script? script;

  Request({
    required this.name,
    required this.type,
    required this.seq,
    required this.method,
    required this.url,
    this.body,
    this.auth,
    required this.params,
    required this.headers,
    required this.requestVars,
    required this.responseVars,
    required this.assertions,
    this.script,
    this.tests,
    this.docs,
  });

  String toBru() {
    var bru = '';

    // Convert meta to bru
    bru += 'meta {\n';
    bru += '  name: $name\n';
    bru += '  type: $type\n';
    bru += '  seq: $seq\n';
    bru += '}\n\n';

    // Convert request to bru
    bru += '${method} {\n';
    bru += '  url: $url';

    if (body != null) {
      bru += '\n  body: ${body!.type}';
    }

    if (auth != null) {
      bru += '\n  auth: ${auth!.type}';
    }

    bru += '\n}\n';

    // Convert params to bru
    final queryParams = params.where((p) => p.type == 'query').toList();
    if (queryParams.isNotEmpty) {
      bru += '\n${queryParamsToBru(queryParams)}\n';
    }

    final pathParams = params.where((p) => p.type == 'path').toList();
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

    // Convert body to bru
    if (body != null) {
      bru += '\n${body!.toBru()}\n';
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
