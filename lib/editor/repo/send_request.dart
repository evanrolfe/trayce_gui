import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/send_result.dart';

class SendRequest {
  final Request request;
  List<ExplorerNode> nodeHierarchy;

  SendRequest({required this.request, required this.nodeHierarchy});

  Future<SendResult> send() async {
    final finalReq = getFinalRequest();
    return finalReq.send();
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
}
