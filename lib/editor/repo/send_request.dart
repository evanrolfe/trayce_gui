import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/send_result.dart';
import 'package:uuid/uuid.dart';

class SendRequest {
  final Config config;
  final Request request;
  List<ExplorerNode> nodeHierarchy;

  SendRequest({required this.request, required this.nodeHierarchy, required this.config});

  Future<SendResult> send() async {
    final finalReq = getFinalRequest();
    final outputPre = await _executePreRequestScript(finalReq);
    final result = await finalReq.send();
    print('outputPre: $outputPre');
    final resultPost = await _executePostResponseScript(finalReq, result.response, result.responseTime ?? 0);

    return SendResult(
      response: resultPost.response,
      output: outputPre + resultPost.output,
      responseTime: resultPost.responseTime,
    );
  }

  Request getFinalRequest() {
    final finalReq = Request.blank();
    finalReq.copyValuesFrom(request);
    finalReq.interpolatePathParams();

    // Work out the headers by looping through nodeHierarchy in reverse order
    for (int i = nodeHierarchy.length - 1; i >= 0; i--) {
      final node = nodeHierarchy[i];

      // Add headers, vars, auth from collection & environment
      if (node.type == NodeType.collection && node.collection != null) {
        // Add vars from environment
        final currentEnv = node.collection!.getCurrentEnvironment();
        if (currentEnv != null) {
          for (final reqvar in currentEnv.vars) {
            finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
            finalReq.requestVars.add(reqvar);
          }
        }

        for (final header in node.collection!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }

        for (final reqvar in node.collection!.requestVars) {
          finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
          finalReq.requestVars.add(reqvar);
        }

        final collectionAuth = node.collection!.getAuth();
        if (node.collection!.authType != AuthType.none && collectionAuth != null) {
          finalReq.authType = node.collection!.authType;
          finalReq.setAuth(collectionAuth);
        }
      }

      // Add headers, vars, auth from folder
      if (node.type == NodeType.folder && node.folder != null) {
        for (final header in node.folder!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }

        for (final reqvar in node.folder!.requestVars) {
          finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
          finalReq.requestVars.add(reqvar);
        }

        final folderAuth = node.folder!.getAuth();
        if (node.folder!.authType != AuthType.none && folderAuth != null) {
          finalReq.authType = node.folder!.authType;
          finalReq.setAuth(folderAuth);
        }
      }

      // Add headers, vars from request
      if (node.type == NodeType.request && node.request != null) {
        for (final header in node.request!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }

        for (final reqvar in node.request!.requestVars) {
          finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
          finalReq.requestVars.add(reqvar);
        }

        final requestAuth = node.request!.getAuth();
        if (node.request!.authType != AuthType.none && requestAuth != null) {
          finalReq.authType = node.request!.authType;
          finalReq.setAuth(requestAuth);
        }
      }
    }

    // for (final header in finalReq.headers) {
    //   print('   ${header.name}: ${header.value}');
    // }

    return finalReq;
  }

  Future<List<String>> _executePreRequestScript(Request request) async {
    final script = request.script;
    if (script == null || script.req == null || script.req!.isEmpty) return [];

    final preReqScript = script.req!;

    // Generate a random UUID
    final uuid = Uuid().v4();
    final scriptFile = File(path.join(config.nodeJsDir(), 'trayce_pre_req-$uuid.js'));

    try {
      // Write the script content to the file
      scriptFile.writeAsStringSync(preReqScript);
      print('scriptFile: ${scriptFile.path}');
      // Run the CLI command
      final result = await Process.run('npm', [
        'run',
        'script',
        '--silent',
        '--',
        scriptFile.path,
        request.toJson(),
      ], workingDirectory: config.nodeJsDir());
      final output = <String>[];

      if (result.exitCode == 0) {
        if (result.stdout.isNotEmpty) {
          output.addAll(result.stdout.toString().split('\n').where((line) => line.isNotEmpty));

          processScriptOutputRequest(request, output.last);
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
    } finally {
      // Clean up the temporary script file
      if (scriptFile.existsSync()) {
        scriptFile.deleteSync();
      }
    }
  }

  void processScriptOutputRequest(Request request, String output) {
    final json = jsonDecode(output);
    if (json['url'] != null) {
      request.url = json['url'];
    }
    if (json['method'] != null) {
      request.method = json['method'].toString().toLowerCase();
    }
    if (json['timeout'] != null) {
      // TODO:
      // request._timeout = Duration(milliseconds: json['timeout']);
    }
    if (json['headers'] != null) {
      final headersMap = json['headers'] as Map<String, dynamic>;
      request.headers =
          headersMap.entries
              .map((entry) => Header(name: entry.key, value: entry.value.toString(), enabled: true))
              .toList();
    }
    if (json['body'] != null) {
      final body = request.getBody();
      if (body != null) {
        if (body is JsonBody) {
          body.setContent(jsonEncode(json['body']));
        } else {
          body.setContent(json['body']);
        }
      }
    }
  }

  Future<SendResult> _executePostResponseScript(Request request, http.Response response, int responseTime) async {
    final script = request.script;
    if (script == null || script.res == null || script.res!.isEmpty) {
      return SendResult(response: response, output: [], responseTime: responseTime);
    }

    final postRespScript = script.res!;

    // Generate a random UUID
    final uuid = Uuid().v4();
    final scriptFile = File(path.join(config.nodeJsDir(), 'trayce_post_resp-$uuid.js'));

    try {
      // Write the script content to the file
      scriptFile.writeAsStringSync(postRespScript);

      // Run the CLI command
      final result = await Process.run('npm', [
        'run',
        'script',
        '--silent',
        '--',
        scriptFile.path,
        request.toJson(),
        _httpResponseToJson(response, responseTime),
      ], workingDirectory: config.nodeJsDir());

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
    } finally {
      // Clean up the temporary script file
      if (scriptFile.existsSync()) {
        scriptFile.deleteSync();
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
}
