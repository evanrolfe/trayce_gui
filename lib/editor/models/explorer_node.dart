import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:uuid/uuid.dart';

enum NodeType { collection, folder, request }

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
  NodeType get type;
  List<ExplorerNode> get children;

  // Setters
  void setIsSaved(bool isSaved);
  void setName(String name);
  void setIsRenaming(bool isRenaming);
  void setIsExpanded(bool isExpanded);
}

class RequestNode implements ExplorerNode {
  String name;
  String uuid;
  final bool isDirectory;
  List<ExplorerNode> children = [];
  final NodeType type;
  bool isExpanded;
  bool isRenaming;
  bool isSaved;

  late Request request;

  RequestNode({
    required this.name,
    required this.request,
    this.children = const [],
    this.isExpanded = false,
    this.isDirectory = false,
    this.isSaved = true,
    this.isRenaming = false,
    this.type = NodeType.request,
    String? uuid,
  }) : uuid = uuid ?? Uuid().v4();

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
      type: type,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }

  @override
  void setIsSaved(bool isSaved) {
    this.isSaved = isSaved;
  }

  @override
  void setName(String name) {
    this.name = name;
  }

  @override
  void setIsExpanded(bool isExpanded) {
    this.isExpanded = isExpanded;
  }

  @override
  void setIsRenaming(bool isRenaming) {
    this.isRenaming = isRenaming;
  }
}

class FolderNode implements ExplorerNode {
  String name;
  String uuid;
  final bool isDirectory;
  List<ExplorerNode> children = [];
  final NodeType type;
  bool isExpanded;
  bool isRenaming;
  bool isSaved;

  late Folder folder;

  FolderNode({
    required this.name,
    required this.folder,
    required this.children,
    this.isExpanded = false,
    this.isDirectory = true,
    this.isSaved = true,
    this.isRenaming = false,
    this.type = NodeType.folder,
    String? uuid,
  }) : uuid = uuid ?? Uuid().v4();

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
      type: type,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }

  @override
  void setIsSaved(bool isSaved) {
    this.isSaved = isSaved;
  }

  @override
  void setName(String name) {
    this.name = name;
  }

  @override
  void setIsExpanded(bool isExpanded) {
    this.isExpanded = isExpanded;
  }

  @override
  void setIsRenaming(bool isRenaming) {
    this.isRenaming = isRenaming;
  }
}

class CollectionNode implements ExplorerNode {
  String name;
  String uuid;
  final bool isDirectory;
  List<ExplorerNode> children = [];
  final NodeType type;
  bool isExpanded;
  bool isRenaming;
  bool isSaved;

  late Collection collection;

  CollectionNode({
    required this.name,
    required this.collection,
    required this.children,
    this.isExpanded = true,
    this.isDirectory = true,
    this.isSaved = true,
    this.isRenaming = false,
    this.type = NodeType.collection,
    String? uuid,
  }) : uuid = uuid ?? Uuid().v4();

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
      type: type,
      children: children,
      isExpanded: isExpanded,
      isRenaming: isRenaming,
      isSaved: isSaved,
    );

    return copiedNode;
  }

  @override
  void setIsSaved(bool isSaved) {
    this.isSaved = isSaved;
  }

  @override
  void setName(String name) {
    this.name = name;
  }

  @override
  void setIsExpanded(bool isExpanded) {
    this.isExpanded = isExpanded;
  }

  @override
  void setIsRenaming(bool isRenaming) {
    this.isRenaming = isRenaming;
  }
}
