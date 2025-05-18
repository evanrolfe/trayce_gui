import 'package:flutter/material.dart';
import 'package:trayce/editor/models/request.dart';

import 'flow_editor_grpc/flow_editor_grpc.dart';
import 'flow_editor_http/flow_editor_http.dart';

class FlowEditor extends StatefulWidget {
  final String flowType;
  final Request request;
  final ValueKey tabKey;

  const FlowEditor({super.key, required this.flowType, required this.request, required this.tabKey});

  @override
  State<FlowEditor> createState() => _FlowEditorState();
}

class _FlowEditorState extends State<FlowEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(child: _buildEditorContent());
  }

  Widget _buildEditorContent() {
    switch (widget.flowType) {
      case 'http':
        return FlowEditorHttp(request: widget.request, tabKey: widget.tabKey);
      case 'grpc':
        return FlowEditorGrpc();
      default:
        return Center(
          child: Text('Unsupported flow type: ${widget.flowType}', style: const TextStyle(color: Color(0xFFD4D4D4))),
        );
    }
  }
}
