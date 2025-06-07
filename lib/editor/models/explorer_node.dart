import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';
import 'package:trayce/editor/models/request.dart';

enum NodeType { collection, folder, request }

class ExplorerNode {
  Directory? dir;
  File file;
  String name;
  final bool isDirectory;
  final List<ExplorerNode> children = [];
  final NodeType type;
  bool isExpanded;
  bool isRenaming;
  bool isSaved;

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
    this.isRenaming = false,
    this.isSaved = true,
    Request? request,
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
      if (request != null) {
        this.request = request;
      } else {
        final requestStr = file.readAsStringSync();
        this.request = parseRequest(requestStr);
      }
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
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(bruStr);
    }
  }

  String displayName() {
    return name.replaceAll('.bru', '');
  }

  void updateChildrenSeq() {
    for (int i = 0; i < children.length; i++) {
      if (children[i].type != NodeType.request) continue;
      children[i].request!.seq = i;
      children[i].save();
    }
  }
}
