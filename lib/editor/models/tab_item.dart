import 'package:flutter/material.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/widgets/flow_editor.dart';

class TabItem {
  final String uuid;

  final FlowEditor editor;
  final FocusNode focusNode;

  ExplorerNode? node;
  bool isModified = false;
  bool isNew;
  ValueKey key;
  String displayName;

  TabItem({
    required this.uuid,
    required this.node,
    this.isNew = false,
    required this.key,
    required this.displayName,
    required this.editor,
    required this.focusNode,
  });

  String getDisplayName() {
    if (isModified) {
      return "$displayName*";
    }

    return displayName;
  }

  String getPath() {
    if (node == null) return key.toString();

    return node!.getFile()?.path ?? '';
  }
}
