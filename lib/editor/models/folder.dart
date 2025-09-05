import 'dart:io';

import 'package:path/path.dart' as path;

import 'auth.dart';
import 'header.dart';
import 'param.dart';
import 'request.dart';
import 'script.dart';
import 'utils.dart';
import 'variable.dart';

class Folder {
  // file properties:
  File file;
  Directory dir;

  // .bru properties:
  String type;

  Map<String, dynamic>? meta;

  List<Header> headers;
  List<Param> query;

  AuthType authType;
  // All Auth types
  Auth? authApiKey;
  Auth? authAwsV4;
  Auth? authBasic;
  Auth? authBearer;
  Auth? authDigest;
  Auth? authOauth2;
  Auth? authWsse;

  List<Variable> requestVars;
  List<Variable> responseVars;

  Script? script;

  String? tests;
  String? docs;

  Folder({
    required this.file,
    required this.dir,
    required this.type,
    this.meta,
    required this.headers,
    required this.query,
    required this.authType,
    this.authApiKey,
    this.authAwsV4,
    this.authBasic,
    this.authBearer,
    this.authDigest,
    this.authOauth2,
    this.authWsse,
    required this.requestVars,
    required this.responseVars,
    this.script,
    this.tests,
    this.docs,
  });

  String toBru() {
    var bru = '';

    // Convert meta to bru
    bru += 'meta {\n';
    bru += '  type: folder\n';
    bru += '}\n';

    // Convert headers to bru
    if (headers.isNotEmpty) {
      bru += '\n${headersToBru(headers)}\n';
    }

    // Convert auth to bru
    if (authType != AuthType.none) {
      bru += '\nauth {\n';
      bru += '  mode: ${authTypeEnumToBru[authType]}\n';
      bru += '}\n';

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
        return null;
      case AuthType.none:
        return null;
    }
  }

  static String getDefaultFolderBru() {
    return '''meta {
  type: folder
}''';
  }

  static Folder blank(String parentPath) {
    final file = File(path.join(parentPath, 'new_folder', 'folder.bru'));
    final dir = Directory(path.join(parentPath, 'new_folder'));

    return Folder(
      file: file,
      dir: dir,
      type: 'folder',
      headers: [],
      query: [],
      requestVars: [],
      responseVars: [],
      authType: AuthType.none,
    );
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
}
