import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';

class EventDisplayExplorerItems {
  final List<ExplorerNode> nodes;

  EventDisplayExplorerItems(this.nodes);
}

class EventOpenExplorerNode {
  final ExplorerNode node;

  EventOpenExplorerNode(this.node);
}

class EventExplorerNodeRenamed {
  final ExplorerNode node;

  EventExplorerNodeRenamed(this.node);
}

class ExplorerRepo {
  final EventBus _eventBus;
  final filesToIgnore = ['folder.bru', 'collection.bru'];
  final foldersToIgnore = ['environments'];
  final List<ExplorerNode> _nodes = [];

  ExplorerRepo({required EventBus eventBus}) : _eventBus = eventBus;

  void createCollection(String collectionPath) async {
    final collectionDir = Directory(collectionPath);
    if (!collectionDir.existsSync()) {
      print('collectionDir does not exist: $collectionPath');
      _eventBus.fire(EventDisplayAlert('the collection path must exist'));
      return;
    }

    final files = collectionDir.listSync();
    if (files.isNotEmpty) {
      print('collectionDir is not empty: $collectionPath');
      _eventBus.fire(EventDisplayAlert('the collection path must be empty'));
      return;
    }

    // Create the collection files (bruno.json and collection.bru)
    final brunoJsonFile = File(path.join(collectionPath, 'bruno.json'));
    final collectionFile = File(path.join(collectionPath, 'collection.bru'));
    final collectionName = collectionDir.path.split(Platform.pathSeparator).last;

    await brunoJsonFile.create();
    await collectionFile.create();

    await brunoJsonFile.writeAsString(Collection.getBrunoJson(collectionName));
    await collectionFile.writeAsString(Collection.getDefaultCollectionBru());

    // Add the new collection to the explorer
    final collectionNode = _buildNode(collectionDir, 0);
    _nodes.add(collectionNode);

    _sortNodes(_nodes);
    print('===========> eventbus fire');
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

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

    // Add the collection to the explorer
    final collectionNode = _buildNode(collectionDir, 0);
    _nodes.add(collectionNode);

    _sortNodes(_nodes);
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  void closeCollection(ExplorerNode node) {
    if (node.type != NodeType.collection) return;
    _nodes.remove(node);

    _sortNodes(_nodes);
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  Future<void> renameNode(ExplorerNode node, String newName) async {
    // Rename a collection/folder
    if (node.type == NodeType.collection || node.type == NodeType.folder) {
      final targetDir = node.dir!;
      final targetPath = path.join(path.dirname(targetDir.path), newName);

      await node.dir!.rename(targetPath);

      node.dir = Directory(targetPath);
      node.file = File(path.join(targetPath, 'collection.bru'));
      node.name = newName;
    }

    // Rename a request
    if (node.type == NodeType.request) {
      final parentNode = _findParentNode(node);
      if (parentNode == null) return;

      final sourceFile = node.file;
      final targetDir = parentNode.dir!;
      final targetPath = path.join(targetDir.path, newName);

      // Move the file
      sourceFile.copySync(targetPath);
      sourceFile.deleteSync();

      // Update the movedNode's file
      node.file = File(targetPath);
      node.name = newName;
      node.save();

      _eventBus.fire(EventExplorerNodeRenamed(node));
    }

    refresh();
  }

  // moveNode moves a node's file to the target node path and refreshes the explorer
  Future<void> moveNode(ExplorerNode movedNode, ExplorerNode targetNode) async {
    // Moving a folder
    if (movedNode.type == NodeType.folder) {
      Directory targetDir = targetNode.dir!;
      final sourceDir = movedNode.dir!;

      if (targetNode.type == NodeType.collection) {
        // Moving to a collection
        targetDir = Directory(path.join(targetDir.path, movedNode.name));
        if (sourceDir.path == targetDir.path) return;
        await moveDirectory(sourceDir, targetDir);
      } else if (targetNode.type == NodeType.folder) {
        // Moving to a folder
        if (sourceDir.path == targetDir.path) return;
        targetDir = Directory(path.join(targetDir.path, movedNode.name));
        await moveDirectory(sourceDir, targetDir);
      }

      refresh();
      return;
    }

    // Moving a request
    if (movedNode.type == NodeType.request) {
      final parentNodeMoved = _findParentNode(movedNode);
      final parentNodeTarget = _findParentNode(targetNode);
      if (parentNodeMoved == null) return;

      final movedToDifferentFolder = parentNodeMoved.dir?.path != parentNodeTarget?.dir?.path;

      if (targetNode.type == NodeType.folder || targetNode.type == NodeType.collection) {
        // Get the file paths
        final sourceFile = movedNode.file;
        final targetDir = targetNode.dir!;
        final targetPath = path.join(targetDir.path, movedNode.name);

        if (targetNode == parentNodeMoved) {
          parentNodeMoved.children.remove(movedNode);
          parentNodeMoved.children.insert(0, movedNode);
          parentNodeMoved.updateChildrenSeq();
          refresh();
          return;
        }

        // Update the movedNode's request seq num
        movedNode.request!.seq = getNextSeq(targetDir.path);
        movedNode.save();

        // Move the file
        sourceFile.copySync(targetPath);
        sourceFile.deleteSync();

        parentNodeMoved.children.remove(movedNode);
        parentNodeMoved.updateChildrenSeq();

        refresh();
      } else if (targetNode.type == NodeType.request && movedToDifferentFolder) {
        if (parentNodeTarget == null) return;
        // Get the file paths
        final sourceFile = movedNode.file;
        final targetDir = parentNodeTarget.dir!;
        final targetPath = path.join(targetDir.path, movedNode.name);

        // Move the file
        sourceFile.copySync(targetPath);
        sourceFile.deleteSync();

        // Update the movedNode's file
        movedNode.file = File(targetPath);

        parentNodeMoved.children.remove(movedNode);
        parentNodeMoved.updateChildrenSeq();

        // targetIndex+1 because it should be inserted after the target node
        int targetIndex = parentNodeTarget.children.indexOf(targetNode) + 1;
        parentNodeTarget.children.insert(targetIndex, movedNode);

        parentNodeTarget.updateChildrenSeq();

        refresh();
      } else if (targetNode.type == NodeType.request && !movedToDifferentFolder) {
        if (parentNodeTarget == null) return;
        // Find the index of targetNode in parentNode.children
        final movedIndex = parentNodeMoved.children.indexOf(movedNode);
        int targetIndex = parentNodeTarget.children.indexOf(targetNode);
        if (targetIndex == -1) return;

        if (targetIndex < movedIndex) targetIndex++;

        parentNodeMoved.children.remove(movedNode);
        parentNodeTarget.children.insert(targetIndex, movedNode);

        parentNodeMoved.updateChildrenSeq();

        refresh();
      }
    }
  }

  // refresh re loads the nodes from file and emits EventDisplayExplorerItems, it will preserve
  // existing nodes so that they dont lose their state values like isExpanded, etc
  void refresh() {
    final refreshedNodes = <ExplorerNode>[];
    for (var node in _nodes) {
      refreshedNodes.add(_buildNode(node.dir!, 0));
    }

    for (var collNode in _nodes) {
      final refreshedCollNode = refreshedNodes.firstWhereOrNull((node) => node.dir?.path == collNode.dir?.path);
      if (refreshedCollNode == null) continue;

      _refreshNodes(collNode.children, refreshedCollNode.children);
    }

    _sortNodes(_nodes);
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  // _refreshNodes syncs the children of two nodes - any nodes which exist in refreshNodes
  // but not in existingNodes are added, and any nodes which exist in existingNodes
  // but not in refreshedNodes are removed
  void _refreshNodes(List<ExplorerNode> existingNodes, List<ExplorerNode> refreshedNodes) {
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
          _refreshNodes(existingNode.children, refreshedNode.children);
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

  // _buildNode builds a node tree recursively from file
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

  // _shouldIncludeEntity determines if a file or directory should be included in the node tree
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

  // _sortNodes recursively sorts the children of a node by seq value
  void _sortNodes(List<ExplorerNode> nodes) {
    for (var node in nodes) {
      if (node.type == NodeType.folder || node.type == NodeType.collection) {
        // Sort children by seq value if they are requests
        node.children.sort((a, b) {
          if (a.type == NodeType.request && b.type == NodeType.request) {
            return a.request!.seq.compareTo(b.request!.seq);
          }
          // Keep folders at the top
          if (a.type == NodeType.folder && b.type == NodeType.request) return -1;
          if (a.type == NodeType.request && b.type == NodeType.folder) return 1;
          // If both are folders, sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        // Recursively sort children
        _sortNodes(node.children);
      }
    }
  }

  // getNextSeq gives the next seq number for a folder based on the existing requests in it
  int getNextSeq(String path) {
    // Find the collection node that contains this path
    final collectionNode = _nodes.firstWhereOrNull((node) => path.startsWith(node.dir?.path ?? ''));
    if (collectionNode == null) return 0;

    // Strip any file from the path
    final folderPath = path.endsWith('.bru') ? path.substring(0, path.lastIndexOf(Platform.pathSeparator)) : path;

    // Find the folder node that matches the exact path
    late final ExplorerNode? folderNode;
    if (folderPath == collectionNode.dir?.path) {
      folderNode = collectionNode;
    } else {
      folderNode = collectionNode.children.firstWhereOrNull((node) => _comparePaths(node.dir?.path ?? '', folderPath));
    }

    if (folderNode == null) return 0;

    if (folderNode.children.isEmpty) return 0;
    // Find the highest seq number in this folder
    int highestSeq = 0;
    for (var node in folderNode.children) {
      if (node.type == NodeType.request && node.request != null) {
        highestSeq = math.max(highestSeq, node.request!.seq);
      }
    }

    return highestSeq + 1;
  }

  bool _comparePaths(String path1, String path2) {
    // Remove trailing slashes from both paths
    final normalizedPath1 = path1.endsWith(Platform.pathSeparator) ? path1.substring(0, path1.length - 1) : path1;
    final normalizedPath2 = path2.endsWith(Platform.pathSeparator) ? path2.substring(0, path2.length - 1) : path2;

    return normalizedPath1 == normalizedPath2;
  }

  // _findParentNode finds the parent node of a given node
  ExplorerNode? _findParentNode(ExplorerNode node) {
    for (var parentNode in _nodes) {
      if (parentNode.children.contains(node)) {
        return parentNode;
      }
      // Recursively check children
      final foundParent = _findParentNodeInChildren(parentNode, node);
      if (foundParent != null) {
        return foundParent;
      }
    }
    return null;
  }

  ExplorerNode? _findParentNodeInChildren(ExplorerNode parentNode, ExplorerNode node) {
    for (var child in parentNode.children) {
      if (child.children.contains(node)) {
        return child;
      }
      // Recursively check children of the child
      final foundParent = _findParentNodeInChildren(child, node);
      if (foundParent != null) {
        return foundParent;
      }
    }
    return null;
  }
}

Future<void> moveDirectory(Directory source, Directory destination) async {
  // Step 1: Copy everything
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  await for (var entity in source.list(recursive: false)) {
    if (entity is Directory) {
      var newDirectory = Directory('${destination.path}/${entity.uri.pathSegments.last}');
      await moveDirectory(entity, newDirectory);
    } else if (entity is File) {
      var newFile = File('${destination.path}/${entity.uri.pathSegments.last}');
      await newFile.writeAsBytes(await entity.readAsBytes());
      await entity.delete(); // Remove the file after moving
    }
  }

  // Step 2: Delete the original directory (should be empty now)
  await source.delete();
}
