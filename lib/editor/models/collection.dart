import 'dart:io';

import 'package:trayce/editor/models/environment.dart';

import 'auth.dart';
import 'header.dart';
import 'param.dart';
import 'request.dart';
import 'script.dart';
import 'utils.dart';
import 'variable.dart';

class Collection {
  // file properties:
  Directory dir;
  File file;
  // String name;

  List<Environment> environments;
  String? _currentEnvironmentFilename;

  // .bru properties:
  String type;
  Map<String, dynamic>? meta;

  List<Header> headers;
  List<Param> query;

  Auth? auth;

  List<Variable> requestVars;
  List<Variable> responseVars;

  Script? script;

  String? tests;
  String? docs;

  Collection({
    required this.file,
    required this.dir,
    required this.type,
    required this.environments,
    this.meta,
    required this.headers,
    required this.query,
    this.auth,
    required this.requestVars,
    required this.responseVars,
    this.script,
    this.tests,
    this.docs,
  });

  Environment? getCurrentEnvironment() {
    if (_currentEnvironmentFilename == null) return null;
    return environments.firstWhere((e) => e.fileName() == _currentEnvironmentFilename);
  }

  void setCurrentEnvironment(String environmentFilename) {
    _currentEnvironmentFilename = environmentFilename;
  }

  String toBru() {
    var bru = '';

    // Convert meta to bru
    bru += 'meta {\n';
    bru += '  type: collection\n';
    bru += '}\n';

    // Convert headers to bru
    if (headers.isNotEmpty) {
      bru += '\n${headersToBru(headers)}\n';
    }

    // Convert auth to bru
    if (auth != null) {
      bru += '\nauth {\n';
      bru += '  mode: ${auth!.type}\n';
      bru += '}\n';

      bru += '\n${auth!.toBru()}\n';
    }

    // Convert variables to bru
    if (requestVars.isNotEmpty) {
      bru += '\n${variablesToBru(requestVars, 'vars:pre-request')}\n';
    }

    if (responseVars.isNotEmpty) {
      bru += '\n${variablesToBru(responseVars, 'vars:post-response')}\n';
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

  static String getBrunoJson(String name) {
    return '''{
  "version": "1",
  "name": "$name",
  "type": "collection",
  "ignore": [
      "node_modules",
      ".git"
  ]
}''';
  }

  static String getDefaultCollectionBru() {
    return '''meta {
  type: collection
}''';
  }
}
