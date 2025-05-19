import 'dart:io';

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class EventDisplayExplorerItems {
  final List<ExplorerNode> nodes;

  EventDisplayExplorerItems(this.nodes);
}

class EventOpenExplorerNode {
  final ExplorerNode node;

  EventOpenExplorerNode(this.node);
}

class ExplorerRepo {
  final EventBus _eventBus;
  final filesToIgnore = ['folder.bru', 'collection.bru'];
  final foldersToIgnore = ['environments'];
  final List<ExplorerNode> _nodes = [];

  ExplorerRepo({required EventBus eventBus}) : _eventBus = eventBus;

  void openCollection(String path) {
    // Check if its already open
    if (_nodes.any((node) => node.dir?.path == path)) return;

    // Check for bruno.json in the root directory
    final collectionDir = Directory(path);
    if (!collectionDir.existsSync()) {
      print('Directory does not exist: $path');
      return;
    }
    final brunoJsonFile = File('${collectionDir.path}${Platform.pathSeparator}bruno.json');
    if (!brunoJsonFile.existsSync()) {
      _eventBus.fire(EventDisplayAlert('the collection path is missing bruno.json'));
      return;
    }

    final collectionNode = _buildNode(collectionDir, 0);
    _nodes.add(collectionNode);

    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  void refresh() {
    final refreshedNodes = <ExplorerNode>[];
    for (var node in _nodes) {
      refreshedNodes.add(_buildNode(node.dir!, 0));
    }

    for (var collNode in _nodes) {
      final refreshedCollNode = refreshedNodes.firstWhereOrNull((node) => node.dir?.path == collNode.dir?.path);
      if (refreshedCollNode == null) continue;

      _syncNodes(collNode.children, refreshedCollNode.children);
    }
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  void _syncNodes(List<ExplorerNode> existingNodes, List<ExplorerNode> refreshedNodes) {
    // Collect nodes to add
    final nodesToAdd = <ExplorerNode>[];

    for (var refreshedNode in refreshedNodes) {
      if (refreshedNode.type == NodeType.folder) {
        // Check if folder exists
        final existingNode = existingNodes.firstWhereOrNull((node) => node.dir?.path == refreshedNode.dir?.path);
        if (existingNode == null) {
          nodesToAdd.add(refreshedNode);
        } else {
          // Recursively sync children
          _syncNodes(existingNode.children, refreshedNode.children);
        }
      } else if (refreshedNode.type == NodeType.request) {
        // Check if request exists
        final exists = existingNodes.any((node) => node.file.path == refreshedNode.file.path);
        if (!exists) {
          nodesToAdd.add(refreshedNode);
        }
      }
    }
    existingNodes.addAll(nodesToAdd);

    // Collect nodes to remove
    final nodesToRemove = <ExplorerNode>[];
    for (var node in existingNodes) {
      if (node.type == NodeType.folder) {
        final exists = refreshedNodes.any(
          (refreshedNode) => refreshedNode.type == NodeType.folder && refreshedNode.dir?.path == node.dir?.path,
        );
        if (!exists) {
          nodesToRemove.add(node);
        }
      } else if (node.type == NodeType.request) {
        final exists = refreshedNodes.any(
          (refreshedNode) => refreshedNode.type == NodeType.request && refreshedNode.file.path == node.file.path,
        );
        if (!exists) {
          nodesToRemove.add(node);
        }
      }
    }
    existingNodes.removeWhere((node) => nodesToRemove.contains(node));
  }

  // Helper function to recursively build ExplorerNodes
  ExplorerNode _buildNode(FileSystemEntity entity, int depth) {
    // Use basename from path for both files and directories
    final name = entity.path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;

    if (entity is Directory) {
      final children = entity.listSync().where(_shouldIncludeEntity).map((e) => _buildNode(e, depth + 1)).toList();

      // Sort: directories first, then by name alphabetically
      children.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      late NodeType type;
      late File file;
      late Directory dir;

      if (depth == 0) {
        type = NodeType.collection;
        dir = entity;
        file = File('${entity.path}/collection.bru');
      } else {
        type = NodeType.folder;
        dir = entity;
        file = File('${entity.path}/folder.bru');
      }

      return ExplorerNode(
        file: file,
        dir: dir,
        name: name,
        isDirectory: true,
        type: type,
        isExpanded: (type == NodeType.collection),
        initialChildren: children,
      );
    } else {
      return ExplorerNode(file: entity as File, type: NodeType.request, name: name, isDirectory: false);
    }
  }

  bool _shouldIncludeEntity(FileSystemEntity entity) {
    final name = entity.path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;

    if (entity is Directory && name != 'environments') {
      return true;
    }
    if (entity is File && name.endsWith('.bru') && !filesToIgnore.contains(name)) {
      return true;
    }
    return false;
  }

  void openNode(ExplorerNode node) {
    _eventBus.fire(EventOpenExplorerNode(node));
  }
}
