import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:uuid/uuid.dart';

sealed class ExplorerNode {
  File? getFile();
  Directory? getDir();
  void setFile(File file);
  void setDir(Directory dir);
  String? getPath();
  String displayName();
  ExplorerNode copy();

  // Getters
  ValueKey? get key;
  String get name;
  String get uuid;
  bool get isDirectory;
  bool get isExpanded;
  bool get isRenaming;
  bool get isSaved;
  List<ExplorerNode> get children;

  // Setters
  set isSaved(bool isSaved);
  set name(String name);
  set isExpanded(bool isExpanded);
  set isRenaming(bool isRenaming);
}

// Mixin to provide common implementation for shared fields
mixin ExplorerNodeBase {
  String _name = '';
  String _uuid = '';
  bool _isExpanded = false;
  bool _isRenaming = false;
  bool _isSaved = true;
  bool _isDirectory = false;
  List<ExplorerNode> _children = [];

  // Getters
  String get uuid => _uuid;
  String get name => _name;
  bool get isExpanded => _isExpanded;
  bool get isRenaming => _isRenaming;
  bool get isSaved => _isSaved;
  bool get isDirectory => _isDirectory;
  List<ExplorerNode> get children => _children;

  // Setters
  set name(String value) => _name = value;
  set isExpanded(bool value) => _isExpanded = value;
  set isRenaming(bool value) => _isRenaming = value;
  set isSaved(bool value) => _isSaved = value;

  // Helper method to initialize common fields
  void initializeBase({
    required String name,
    String? uuid,
    bool isExpanded = false,
    bool isRenaming = false,
    bool isSaved = true,
    bool isDirectory = false,
    List<ExplorerNode> children = const [],
  }) {
    _name = name;
    _uuid = uuid ?? Uuid().v4();
    _isExpanded = isExpanded;
    _isRenaming = isRenaming;
    _isSaved = isSaved;
    _isDirectory = isDirectory;
    _children = List.from(children);
  }
}

// =============================================================================
// RequestNode
// =============================================================================
class RequestNode with ExplorerNodeBase implements ExplorerNode {
  late Request request;

  RequestNode({
    required String name,
    required this.request,
    List<ExplorerNode> children = const [],
    bool isExpanded = false,
    bool isDirectory = false,
    bool isSaved = true,
    bool isRenaming = false,
    String? uuid,
  }) {
    initializeBase(
      name: name,
      uuid: uuid,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
      isDirectory: isDirectory,
      children: children,
    );
  }

  // RequestNode.blank() creates a node with a blank unsaved request, used when
  // you click new request on a folder/collection in the explorer
  static blank(String parentPath) {
    final request = Request.blank();
    request.file = File(path.join(parentPath, '.bru'));
    request.name = '.bru';

    return RequestNode(name: ".bru", request: request, isSaved: false);
  }

  @override
  File? getFile() {
    return request.file;
  }

  @override
  Directory? getDir() {
    return null;
  }

  @override
  void setFile(File file) {
    request.file = file;
  }

  @override
  void setDir(Directory dir) {}

  @override
  String? getPath() {
    return request.file?.path;
  }

  @override
  ValueKey? get key => getPath() != null ? ValueKey(getPath()!) : null;

  @override
  String displayName() {
    return name.replaceAll('.bru', '');
  }

  @override
  RequestNode copy() {
    final copiedRequest = Request.blank();
    copiedRequest.copyValuesFrom(request);

    final copiedNode = RequestNode(
      name: name,
      request: copiedRequest,
      isDirectory: isDirectory,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }
}

// =============================================================================
// ScriptNode
// =============================================================================
class ScriptNode with ExplorerNodeBase implements ExplorerNode {
  late File file;

  ScriptNode({
    required String name,
    required this.file,
    List<ExplorerNode> children = const [],
    bool isExpanded = false,
    bool isDirectory = false,
    bool isSaved = true,
    bool isRenaming = false,
    String? uuid,
  }) {
    initializeBase(
      name: name,
      uuid: uuid,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
      isDirectory: isDirectory,
      children: children,
    );
  }

  // ScriptNode.blank() creates a node with a blank unsaved script
  static blank(String parentPath) {
    final file = File(path.join(parentPath, 'untitled.js'));

    return ScriptNode(name: "untitled.js", file: file, isSaved: false);
  }

  @override
  File? getFile() {
    return file;
  }

  @override
  Directory? getDir() {
    return null;
  }

  @override
  void setFile(File file) {
    this.file = file;
  }

  @override
  void setDir(Directory dir) {}

  @override
  String? getPath() {
    return file.path;
  }

  @override
  ValueKey? get key => getPath() != null ? ValueKey(getPath()!) : null;

  @override
  String displayName() {
    return name;
  }

  @override
  ScriptNode copy() {
    final copiedNode = ScriptNode(
      name: name,
      file: file,
      isDirectory: isDirectory,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }
}

// =============================================================================
// FolderNode
// =============================================================================
class FolderNode with ExplorerNodeBase implements ExplorerNode {
  late Folder folder;

  FolderNode({
    required String name,
    required this.folder,
    required List<ExplorerNode> children,
    bool isExpanded = false,
    bool isDirectory = true,
    bool isSaved = true,
    bool isRenaming = false,
    String? uuid,
  }) {
    initializeBase(
      name: name,
      uuid: uuid,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
      isDirectory: isDirectory,
      children: children,
    );
  }

  // RequestNode.blank() creates a node with a blank unsaved request, used when
  // you click new request on a folder/collection in the explorer
  static blank(String parentPath) {
    final folder = Folder.blank(parentPath);

    return FolderNode(name: "new_folder", folder: folder, children: [], isSaved: false);
  }

  @override
  File? getFile() {
    return folder.file;
  }

  @override
  Directory? getDir() {
    return folder.dir;
  }

  @override
  void setFile(File file) {
    folder.file = file;
  }

  @override
  void setDir(Directory dir) {
    folder.dir = dir;
  }

  @override
  String? getPath() {
    return folder.file.path;
  }

  @override
  ValueKey? get key => getPath() != null ? ValueKey(getPath()!) : null;

  @override
  String displayName() {
    return name;
  }

  @override
  FolderNode copy() {
    final copiedNode = FolderNode(
      name: name,
      folder: folder,
      isDirectory: isDirectory,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }
}

// =============================================================================
// CollectionNode
// =============================================================================
class CollectionNode with ExplorerNodeBase implements ExplorerNode {
  late Collection collection;

  CollectionNode({
    required String name,
    required this.collection,
    required List<ExplorerNode> children,
    bool isExpanded = true,
    bool isDirectory = true,
    bool isSaved = true,
    bool isRenaming = false,
    String? uuid,
  }) {
    initializeBase(
      name: name,
      uuid: uuid,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
      isDirectory: isDirectory,
      children: children,
    );
  }

  @override
  File? getFile() {
    return collection.file;
  }

  @override
  Directory? getDir() {
    return collection.dir;
  }

  @override
  void setFile(File file) {
    collection.file = file;
  }

  @override
  void setDir(Directory dir) {
    collection.dir = dir;
  }

  @override
  String? getPath() {
    return collection.file.path;
  }

  @override
  ValueKey? get key => getPath() != null ? ValueKey(getPath()!) : null;

  @override
  String displayName() {
    return name;
  }

  @override
  CollectionNode copy() {
    final copiedNode = CollectionNode(
      name: name,
      collection: collection,
      isDirectory: isDirectory,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }
}
