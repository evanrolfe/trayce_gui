import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/parse/parse_folder.dart';
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

  late Collection? collection;
  late Folder? folder;
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
    Folder? folder,
  }) {
    if (type == NodeType.collection) {
      final collectionStr = file.readAsStringSync();
      collection = parseCollection(collectionStr);
    }

    if (type == NodeType.folder) {
      if (folder != null) {
        this.folder = folder;
      } else {
        final folderStr = file.readAsStringSync();
        this.folder = parseFolder(folderStr);
      }
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

  ValueKey get key => ValueKey(file.path);

  void save() {
    if (type == NodeType.collection) {
      final bruStr = collection!.toBru();
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(bruStr);
    }

    if (type == NodeType.folder) {
      final bruStr = folder!.toBru();
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(bruStr);
    }

    if (type == NodeType.request) {
      request!.name = name.replaceAll('.bru', '');
      final bruStr = request!.toBru();

      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(bruStr);
    }
    isSaved = true;
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
