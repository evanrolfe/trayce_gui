import 'package:http/http.dart' as http;
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';

class SendRequest {
  final Request request;
  List<ExplorerNode> nodeHierarchy;

  SendRequest({required this.request, required this.nodeHierarchy});

  Future<http.Response> send() async {
    final finalReq = getFinalRequest();
    final response = await finalReq.send();
    return response;
  }

  Request getFinalRequest() {
    final finalReq = Request.blank();
    finalReq.copyValuesFrom(request);

    // Work out the headers by looping through nodeHierarchy in reverse order
    for (int i = nodeHierarchy.length - 1; i >= 0; i--) {
      final node = nodeHierarchy[i];

      // Add headers, vars from collection
      if (node.type == NodeType.collection && node.collection != null) {
        final currentEnv = node.collection!.getCurrentEnvironment();
        if (currentEnv != null) {
          print("=================> CURRENT ENV: ${currentEnv.fileName()}");
        }

        for (final header in node.collection!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }

        for (final reqvar in node.collection!.requestVars) {
          finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
          finalReq.requestVars.add(reqvar);
        }
      }

      // Add headers, vars from folder
      if (node.type == NodeType.folder && node.folder != null) {
        for (final header in node.folder!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }

        for (final reqvar in node.folder!.requestVars) {
          finalReq.requestVars.removeWhere((v) => v.name == reqvar.name);
          finalReq.requestVars.add(reqvar);
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
      }
    }

    // for (final header in finalReq.headers) {
    //   print('   ${header.name}: ${header.value}');
    // }

    return finalReq;
  }
}
