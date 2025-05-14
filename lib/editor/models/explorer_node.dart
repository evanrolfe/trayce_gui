import 'dart:io';

import 'package:flutter/foundation.dart';
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

  late Collection collection;
  late Request? request;

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

  // Request? getRequest() {
  //   if (type != NodeType.request) return null;

  //   final requestStr = file.readAsStringSync();
  //   return parseRequest(requestStr);
  // }

  Collection? getCollection() {
    if (type != NodeType.collection) return null;

    final collectionStr = file.readAsStringSync();
    return parseCollection(collectionStr);
  }

  ValueKey get key => ValueKey(file.path);

  void save() {
    if (type == NodeType.request) {
      final bruStr = request!.toBru();
      file.writeAsStringSync(bruStr);
    }
  }
}
