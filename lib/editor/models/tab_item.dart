import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class TabItem {
  ExplorerNode? node;
  bool isModified = false;
  bool isNew;
  ValueKey key;
  String displayName;

  TabItem({required this.node, this.isNew = false, required this.key, required this.displayName});

  String getDisplayName() {
    if (isModified) {
      return "$displayName*";
    }

    return displayName;
  }
}
