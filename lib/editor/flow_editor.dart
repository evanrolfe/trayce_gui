import 'package:flutter/material.dart';

import 'flow_editor_grpc.dart';
import 'flow_editor_http.dart';

class FlowEditor extends StatefulWidget {
  final String flowType;

  const FlowEditor({
    super.key,
    required this.flowType,
  });

  @override
  State<FlowEditor> createState() => _FlowEditorState();
}

class _FlowEditorState extends State<FlowEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildEditorContent(),
    );
  }

  Widget _buildEditorContent() {
    switch (widget.flowType) {
      case 'http':
        return const FlowEditorHttp();
      case 'grpc':
        return const FlowEditorGrpc();
      default:
        return Center(
          child: Text(
            'Unsupported flow type: ${widget.flowType}',
            style: const TextStyle(color: Color(0xFFD4D4D4)),
          ),
        );
    }
  }
}
