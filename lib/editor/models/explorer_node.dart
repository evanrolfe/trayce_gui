import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';

enum NodeType { collection, folder, request }

class ExplorerNode {
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

  static newCollection(String name, Collection collection, List<ExplorerNode> children) {
    return ExplorerNode(
      name: name,
      type: NodeType.collection,
      isExpanded: true,
      isDirectory: true,
      initialChildren: children,
      collection: collection,
    );
  }

  static newFolder(String name, Folder folder, List<ExplorerNode> children) {
    return ExplorerNode(
      name: name,
      type: NodeType.folder,
      isDirectory: true,
      initialChildren: children,
      folder: folder,
    );
  }

  static newRequest(String name, Request request) {
    return ExplorerNode(name: name, type: NodeType.request, isDirectory: false, request: request);
  }

  static newBlankRequest(String parentPath) {
    final request = Request.blank();
    request.file = File(path.join(parentPath, '.bru'));
    request.name = '.bru';

    return ExplorerNode(name: ".bru", type: NodeType.request, isDirectory: false, request: request, isSaved: false);
  }

  static newBlankFolder(String parentPath) {
    final folder = Folder.blank(parentPath);

    return ExplorerNode(name: "new_folder", type: NodeType.folder, isDirectory: true, folder: folder, isSaved: false);
  }

  ExplorerNode({
    required this.name,
    this.isDirectory = false,
    required this.type,
    List<ExplorerNode>? initialChildren,
    this.isExpanded = false,
    this.isRenaming = false,
    this.isSaved = true,
    Collection? collection,
    Request? request,
    Folder? folder,
  }) {
    if (type == NodeType.collection) {
      this.collection = collection;
    }

    if (type == NodeType.folder) {
      this.folder = folder;
    }

    if (type == NodeType.request) {
      this.request = request;
    }

    if (initialChildren != null) {
      children.addAll(initialChildren);
    }
  }

  File? getFile() {
    if (type == NodeType.request && request != null) {
      return request!.file;
    } else if (type == NodeType.folder && folder != null) {
      return folder!.file;
    } else if (type == NodeType.collection && collection != null) {
      return collection!.file;
    }
    return null;
  }

  Directory? getDir() {
    if (type == NodeType.folder && folder != null) {
      return folder!.dir;
    } else if (type == NodeType.collection && collection != null) {
      return collection!.dir;
    }
    return null;
  }

  void setFile(File file) {
    if (type == NodeType.request) {
      request!.file = file;
    } else if (type == NodeType.folder) {
      folder!.file = file;
    } else if (type == NodeType.collection) {
      collection!.file = file;
    }
  }

  void setDir(Directory dir) {
    if (type == NodeType.folder) {
      folder!.dir = dir;
    } else if (type == NodeType.collection) {
      collection!.dir = dir;
    }
  }

  String? getPath() {
    if (type == NodeType.request && request != null) {
      return request!.file?.path;
    } else if (type == NodeType.folder && folder != null) {
      return folder!.file.path;
    } else if (type == NodeType.collection && collection != null) {
      return collection!.file.path;
    }
    return null;
  }

  ValueKey? get key => getPath() != null ? ValueKey(getPath()!) : null;

  void save() {
    if (type == NodeType.collection) {
      CollectionRepo().save(collection!);
    }

    if (type == NodeType.folder) {
      FolderRepo().save(folder!);
    }

    if (type == NodeType.request) {
      RequestRepo().save(request!);
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
