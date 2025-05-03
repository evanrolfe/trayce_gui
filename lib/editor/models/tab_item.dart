import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class TabItem {
  final ExplorerNode node;

  TabItem({required this.node});

  ValueKey get key => ValueKey(node.file.path);
}
