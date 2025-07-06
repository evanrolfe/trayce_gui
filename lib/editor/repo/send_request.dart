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

      // Add headers from collection
      if (node.type == NodeType.collection && node.collection != null) {
        for (final header in node.collection!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }
      }

      // Add headers from folder
      if (node.type == NodeType.folder && node.folder != null) {
        for (final header in node.folder!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }
      }

      // Add headers from request
      if (node.type == NodeType.request && node.request != null) {
        for (final header in node.request!.headers) {
          finalReq.headers.removeWhere((h) => h.name == header.name);
          finalReq.headers.add(header);
        }
      }
    }

    for (final header in finalReq.headers) {
      print('   ${header.name}: ${header.value}');
    }

    return finalReq;
  }
}
