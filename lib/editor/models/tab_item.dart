import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class TabItem {
  ExplorerNode? node;
  bool isModified = false;
  bool isNew;
  ValueKey key;
  String displayName;
  Collection collection;

  TabItem({
    required this.node,
    this.isNew = false,
    required this.key,
    required this.displayName,
    required this.collection,
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
