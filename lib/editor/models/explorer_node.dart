import 'dart:io';

import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';
import 'package:trayce/editor/models/request.dart';

enum NodeType { collection, folder, request }

class ExplorerNode {
  final Directory? dir;
  final File file;
  final String name;
  final bool isDirectory;
  final List<ExplorerNode> children = [];
  final NodeType type;
  bool isExpanded;

  late final Collection collection;
  late final Request? request;

  ExplorerNode({
    required this.file,
    this.dir,
    required this.name,
    this.isDirectory = false,
    required this.type,
    List<ExplorerNode>? initialChildren,
    this.isExpanded = false,
  }) {
    if (type == NodeType.collection) {
      final collectionStr = file.readAsStringSync();
      collection = parseCollection(collectionStr);
    }

    if (type == NodeType.folder) {
      // final folderStr = file.readAsStringSync();
      print("Loaded folder from ${file.path}, but parsing not implemented yet");
    }

    if (type == NodeType.request) {
      final requestStr = file.readAsStringSync();
      request = parseRequest(requestStr);
    }

    if (initialChildren != null) {
      children.addAll(initialChildren);
    }
  }
}
