import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class TabItem {
  ExplorerNode? node;
  bool isModified = false;
  TabItem({required this.node});

  ValueKey get key => ValueKey(node?.file.path);

  String getDisplayName() {
    if (node == null) {
      return 'Untitled';
    }

    if (isModified) {
      return "${node!.name}*";
    }

    return node!.name;
  }
}
