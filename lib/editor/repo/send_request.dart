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
import 'package:trayce/editor/repo/environment_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/global_environment_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:uuid/uuid.dart';

typedef RequestMap = Map<String, Map<String, dynamic>>;

typedef VarForJson = Map<String, dynamic>;

class HttpClient implements HttpClientI {
  final http.Client client = http.Client();

  HttpClient();

  @override
  Future<http.Response> send(http.BaseRequest request, Duration timeout) async {
    final streamedResponse = await client.send(request).timeout(timeout);
    return http.Response.fromStream(streamedResponse);
  }
}

abstract interface class HttpClientI {
  Future<http.Response> send(http.BaseRequest request, Duration timeout);
}

class SendRequest {
  final Config config;
  final Request request;
  final ExplorerNode? node;
  final ExplorerNode collectionNode;

  final ExplorerService explorerService;
  final RuntimeVarsRepo runtimeVarsRepo;
  final EnvironmentRepo environmentRepo;
  final GlobalEnvironmentRepo globalEnvironmentRepo;
  final HttpClientI httpClient;

  SendRequest({
    required this.request,
    required this.config,
    required this.explorerService,
    required this.node,
    required this.collectionNode,
    required this.httpClient,
    required this.runtimeVarsRepo,
    required this.environmentRepo,
    required this.globalEnvironmentRepo,
  });

  Future<SendResult> send() async {
    final finalReq = getFinalRequest(node);

    final outputPre = await _executePreRequestScript(finalReq);
    final result = await _sendRequest(finalReq);
    final resultPost = await _executePostResponseScript(finalReq, result.response, result.responseTime ?? 0);
    final resultPostVars = await _executePostResponseVarsScript(finalReq, result.response, result.responseTime ?? 0);

    return SendResult(
      response: resultPost.response,
      output: outputPre + resultPost.output + resultPostVars.output,
      responseTime: resultPost.responseTime,
    );
  }

  Future<SendResult> _sendRequest(Request request) async {
    final httpRequest = await request.toHttpRequest();

    final startTime = DateTime.now();
    final response = await httpClient.send(httpRequest, request.timeout);
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;

    return SendResult(response: response, output: [], responseTime: responseTime);
  }

  Future<RequestMap> generateRequestMap() async {
    RequestMap requestMap = {};
    final nodeMap = explorerService.getNodeMap(collectionNode);
    for (final entry in nodeMap.entries) {
      final key = entry.key;
      final node = entry.value;
      if (node.request == null) continue;

      final httpRequest = await getFinalRequest(node).toHttpRequest();
      requestMap[key] = _httpRequestToAxios(httpRequest);
    }

    return requestMap;
  }

  Map<String, List<VarForJson>> _getVarsMap(ExplorerNode? reqNode) {
    List<ExplorerNode> nodeHierarchy;
    if (reqNode == null) {
      nodeHierarchy = [collectionNode];
    } else {
      nodeHierarchy = explorerService.getNodeHierarchy(reqNode);
    }

    final varsMap = <String, List<VarForJson>>{
      'globalEnvVars': [],
      'collectionVars': [],
      'envVars': [],
      'folderVars': [],
      'requestVars': [],
      'responseVars': [],
      'runtimeVars': runtimeVarsRepo.toMapList(),
    };

    // Add global environment vars
    final globalEnv = globalEnvironmentRepo.getSelectedEnv();
    if (globalEnv != null) {
      for (final reqvar in globalEnv.vars) {
        varsMap['globalEnvVars']!.add({'name': reqvar.name, 'value': reqvar.value});
      }
    }

    // Work out the variables by looping through nodeHierarchy in reverse order
    for (int i = nodeHierarchy.length - 1; i >= 0; i--) {
      final node = nodeHierarchy[i];

      // Add vars from collection & environment
      if (node.type == NodeType.collection && node.collection != null) {
        // Add vars from collection
        for (final reqvar in node.collection!.requestVars) {
          varsMap['collectionVars']!.add({'name': reqvar.name, 'value': reqvar.value});
        }

        // Add vars from environment
        final currentEnv = node.collection!.getCurrentEnvironment();
        if (currentEnv != null) {
          for (final reqvar in currentEnv.vars) {
            varsMap['envVars']!.add({'name': reqvar.name, 'value': reqvar.value});
          }
        }
      }

      // Add vars from folder
      if (node.type == NodeType.folder && node.folder != null) {
        for (final reqvar in node.folder!.requestVars) {
          varsMap['folderVars']!.add({'name': reqvar.name, 'value': reqvar.value});
        }
      }

      // Add vars from request
      if (node.type == NodeType.request && node.request != null) {
        // pre-request
        for (final reqvar in node.request!.requestVars) {
          varsMap['requestVars']!.add({'name': reqvar.name, 'value': reqvar.value});
        }
        // post-response
        for (final reqvar in node.request!.responseVars) {
          varsMap['responseVars']!.add({'name': reqvar.name, 'value': reqvar.value});
        }
      }
    }

    return varsMap;
  }

  Request getFinalRequest(ExplorerNode? reqNode) {
    List<ExplorerNode> nodeHierarchy;
    if (reqNode == null) {
      nodeHierarchy = [collectionNode];
    } else {
      nodeHierarchy = explorerService.getNodeHierarchy(reqNode);
    }

    final finalReq = Request.blank();
    finalReq.copyValuesFrom(request);
    finalReq.interpolatePathParams();

    // Add global environment vars
    final globalEnv = globalEnvironmentRepo.getSelectedEnv();
    if (globalEnv != null) {
      for (final reqvar in globalEnv.vars) {
        finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
        finalReq.requestVars.add(reqvar);
      }
    }

    // Work out the headers by looping through nodeHierarchy in reverse order
    for (int i = nodeHierarchy.length - 1; i >= 0; i--) {
      final node = nodeHierarchy[i];

      if (node.type == NodeType.collection && node.collection != null) {
        // Add headers, vars, auth from collection
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

        // Add vars from environment
        final currentEnv = node.collection!.getCurrentEnvironment();
        if (currentEnv != null) {
          for (final reqvar in currentEnv.vars) {
            finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
            finalReq.requestVars.add(reqvar);
          }
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

    // Add runtime vars
    for (final varr in runtimeVarsRepo.vars) {
      finalReq.requestVars.removeWhere((v) => v.name == varr.name);
      finalReq.requestVars.add(varr);
    }

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
      scriptFile.writeAsStringSync(preReqScript);

      final requestMap = await generateRequestMap();
      final cliArgs = {
        'request': request.toMap(),
        'requestMap': requestMap,
        'collectionName': collectionNode.collection!.dir.path,
        'collectionPath': collectionNode.collection!.absolutePath(),
        'vars': _getVarsMap(node),
      };

      // Run the CLI command
      // print("npm run script --silent -- ${scriptFile.path} '${jsonEncode(cliArgs)}'");
      final result = await Process.run(config.npmCommand, [
        'run',
        'script',
        '--silent',
        '--',
        scriptFile.path,
        jsonEncode(cliArgs),
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

    if (json['req'] == null) throw Exception('req not set on pre request script output');

    final req = json['req'] as Map<String, dynamic>;
    if (req['url'] != null) {
      request.url = req['url'];
    }
    if (req['method'] != null) {
      request.method = req['method'].toString().toLowerCase();
    }
    if (req['timeout'] != null) {
      request.timeout = Duration(milliseconds: req['timeout']);
    }
    if (req['headers'] != null) {
      final headersMap = req['headers'] as Map<String, dynamic>;
      request.headers =
          headersMap.entries
              .map((entry) => Header(name: entry.key, value: entry.value.toString(), enabled: true))
              .toList();
    }
    if (req['body'] != null) {
      final body = request.getBody();
      if (body != null) {
        if (body is JsonBody) {
          body.setContent(jsonEncode(req['body']));
        } else {
          body.setContent(req['body']);
        }
      }
    }
    if (json['runtimeVars'] != null) {
      final runtimeVars = json['runtimeVars'] as List<dynamic>;
      runtimeVarsRepo.clearVars();
      for (final varr in runtimeVars) {
        final varMap = varr as Map<String, dynamic>;
        runtimeVarsRepo.setVar(varMap['name'], varMap['value']);
      }
    }

    final currentEnv = collectionNode.collection!.getCurrentEnvironment();
    if (currentEnv != null && json['envVars'] != null) {
      final envVars = json['envVars'] as List<dynamic>;
      for (final varr in envVars) {
        final varMap = varr as Map<String, dynamic>;
        if (varMap['value'] == null) continue;
        currentEnv.setVar(varMap['name'], varMap['value']);
      }

      environmentRepo.save(collectionNode.collection!, currentEnv);
    }

    final currentGlobalEnv = globalEnvironmentRepo.getSelectedEnv();
    if (currentGlobalEnv != null && json['globalEnvVars'] != null) {
      final globalEnvVars = json['globalEnvVars'] as List<dynamic>;
      for (final varr in globalEnvVars) {
        final varMap = varr as Map<String, dynamic>;
        currentGlobalEnv.setVar(varMap['name'], varMap['value']);
      }

      globalEnvironmentRepo.saveOne(currentGlobalEnv);
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

      final requestMap = await generateRequestMap();
      final cliArgs = {
        'request': request.toMap(),
        'response': _httpResponseToMap(response, responseTime),
        'requestMap': requestMap,
        'collectionName': collectionNode.collection!.dir.path,
        'collectionPath': collectionNode.collection!.absolutePath(),
        'vars': _getVarsMap(node),
      };
      // print("npm run script --silent -- ${scriptFile.path} '${jsonEncode(cliArgs)}'");
      // Run the CLI command
      final result = await Process.run(config.npmCommand, [
        'run',
        'script',
        '--silent',
        '--',
        scriptFile.path,
        jsonEncode(cliArgs),
      ], workingDirectory: config.nodeJsDir());

      final output = <String>[];

      if (result.exitCode == 0) {
        if (result.stdout.isNotEmpty) {
          output.addAll(result.stdout.toString().split('\n').where((line) => line.isNotEmpty));

          response = await processScriptOutputResponse(response, output.last);
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

  Future<SendResult> _executePostResponseVarsScript(Request request, http.Response response, int responseTime) async {
    try {
      final requestMap = await generateRequestMap();
      final cliArgs = {
        'request': request.toMap(),
        'response': _httpResponseToMap(response, responseTime),
        'requestMap': requestMap,
        'collectionName': collectionNode.collection!.dir.path,
        'collectionPath': collectionNode.collection!.absolutePath(),
        'vars': _getVarsMap(node),
      };

      // print("npm run script-vars --silent -- '${jsonEncode(cliArgs)}'");
      // Run the CLI command
      final result = await Process.run(config.npmCommand, [
        'run',
        'script-vars',
        '--silent',
        '--',
        jsonEncode(cliArgs),
      ], workingDirectory: config.nodeJsDir());

      final output = <String>[];

      if (result.exitCode == 0) {
        if (result.stdout.isNotEmpty) {
          output.addAll(result.stdout.toString().split('\n').where((line) => line.isNotEmpty));

          response = await processScriptOutputResponse(response, output.last);
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

  Future<http.Response> processScriptOutputResponse(http.Response response, String output) async {
    final json = jsonDecode(output);
    if (json['res'] == null) throw Exception('res not set on post response script output');

    final res = json['res'] as Map<String, dynamic>;

    if (json['runtimeVars'] != null) {
      final runtimeVars = json['runtimeVars'] as List<dynamic>;
      runtimeVarsRepo.clearVars();
      for (final varr in runtimeVars) {
        final varMap = varr as Map<String, dynamic>;
        runtimeVarsRepo.setVar(varMap['name'], varMap['value']);
      }
    }

    final currentEnv = collectionNode.collection!.getCurrentEnvironment();
    if (currentEnv != null && json['envVars'] != null) {
      final envVars = json['envVars'] as List<dynamic>;
      for (final varr in envVars) {
        final varMap = varr as Map<String, dynamic>;
        if (varMap['value'] == null) continue;

        currentEnv.setVar(varMap['name'], varMap['value']);
      }

      environmentRepo.save(collectionNode.collection!, currentEnv);
    }

    final currentGlobalEnv = globalEnvironmentRepo.getSelectedEnv();
    if (currentGlobalEnv != null && json['globalEnvVars'] != null) {
      final globalEnvVars = json['globalEnvVars'] as List<dynamic>;
      for (final varr in globalEnvVars) {
        final varMap = varr as Map<String, dynamic>;
        currentGlobalEnv.setVar(varMap['name'], varMap['value']);
      }

      await globalEnvironmentRepo.saveOne(currentGlobalEnv);
    }

    if (res['body'] != null) {
      // Create a new response with the modified body
      return http.Response(
        res['body'],
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

  Map<String, dynamic> _httpResponseToMap(http.Response response, int responseTime) {
    // Calculate header bytes by encoding each header key-value pair
    int headerBytes = 0;
    response.headers.forEach((key, value) {
      headerBytes += utf8.encode('$key: $value\r\n').length;
    });

    // Calculate body bytes
    int bodyBytes = utf8.encode(response.body).length;

    return {
      'url': response.request?.url.toString(),
      'status': response.statusCode,
      'statusText': response.reasonPhrase,
      'headers': response.headers,
      'body': response.body,
      'size': {'body': bodyBytes, 'headers': headerBytes, 'total': bodyBytes + headerBytes},
      'responseTime': responseTime,
    };
  }

  Map<String, dynamic> _httpRequestToAxios(http.BaseRequest request) {
    final Map<String, dynamic> axiosConfig = {
      'method': request.method.toLowerCase(),
      'url': request.url.toString(),
      'headers': request.headers,
    };

    // Add request body data if present
    if (request is http.Request && request.body.isNotEmpty) {
      axiosConfig['data'] = request.body;
    } else if (request is http.MultipartRequest) {
      // todo
    }

    // Add query parameters if present in URL
    final uri = request.url;
    if (uri.queryParameters.isNotEmpty) {
      axiosConfig['params'] = uri.queryParameters;
    }

    return axiosConfig;
  }
}
