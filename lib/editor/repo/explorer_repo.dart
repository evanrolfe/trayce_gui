import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';

class EventDisplayExplorerItems {
  final List<ExplorerNode> nodes;

  EventDisplayExplorerItems(this.nodes);
}

class EventOpenExplorerNode {
  final ExplorerNode node;
  final Collection collection;

  EventOpenExplorerNode(this.node, this.collection);
}

class EventExplorerNodeRenamed {
  final ExplorerNode node;

  EventExplorerNodeRenamed(this.node);
}

class EventCollectionOpened {
  final ExplorerNode node;
  final Collection collection;

  EventCollectionOpened(this.node, this.collection);
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
      collectionDir.createSync(recursive: true);
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
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  void openCollection(String path) {
    // Check if its already open
    if (_nodes.any((node) => node.getDir()?.path == path)) return;

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
    _eventBus.fire(EventCollectionOpened(collectionNode, collectionNode.collection!));
  }

  void closeCollection(ExplorerNode node) {
    if (node.type != NodeType.collection) return;
    _nodes.remove(node);

    _sortNodes(_nodes);
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  // addNodeToParent adds a node to a parent node and refreshes the explorer, its used
  // when you click new request on a folder/collection and enter the filename, the node
  // is unsaved at this point which is why we dont just call refresh()
  void addNodeToParent(ExplorerNode parentNode, ExplorerNode node) {
    parentNode.children.add(node);

    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  // removeUnsavedNode removes an unsaved node from its parent and refreshes the explorer,
  // this is used when you click new request on a folder/collection but then hit escape
  // to cancel the rename
  void removeUnsavedNode(ExplorerNode node) {
    final parentNode = _findParentNode(node);
    if (parentNode == null) return;
    parentNode.children.remove(node);

    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  Future<void> renameNode(ExplorerNode node, String newName) async {
    // Rename a collection/folder
    if ((node.type == NodeType.collection || node.type == NodeType.folder) && !node.isSaved) {
      final targetDir = node.getDir()!;
      final targetPath = path.join(path.dirname(targetDir.path), newName);

      node.setDir(Directory(targetPath));
      node.setFile(File(path.join(targetPath, 'folder.bru')));
      node.name = newName;

      node.save();
    }

    if ((node.type == NodeType.collection || node.type == NodeType.folder) && node.isSaved) {
      final targetDir = node.getDir()!;
      final targetPath = path.join(path.dirname(targetDir.path), newName);

      await node.getDir()!.rename(targetPath);

      node.setDir(Directory(targetPath));
      node.setFile(File(path.join(targetPath, 'collection.bru')));
      node.name = newName;
    }

    // Rename a request
    newName = "$newName.bru";
    // This is called when you click new request on a folder/collection and enter the filename
    // directly in the explorer, then hit enter
    if (node.type == NodeType.request && !node.isSaved) {
      final parentNode = _findParentNode(node);
      if (parentNode == null) return;

      final targetDir = parentNode.getDir()!;
      final targetPath = path.join(targetDir.path, newName);

      node.setFile(File(targetPath));
      node.name = newName;
      node.request!.seq = getNextSeq(targetDir.path);
      node.save();
      refresh();
      openNode(node);
    }
    if (node.type == NodeType.request && node.isSaved) {
      final parentNode = _findParentNode(node);
      if (parentNode == null) return;

      final sourceFile = node.getFile()!;
      final targetDir = parentNode.getDir()!;
      final targetPath = path.join(targetDir.path, newName);

      // Move the file
      sourceFile.copySync(targetPath);
      sourceFile.deleteSync();

      // Update the movedNode's file
      node.setFile(File(targetPath));
      node.name = newName;
      node.save();

      _eventBus.fire(EventExplorerNodeRenamed(node));
    }

    refresh();
  }

  Future<void> deleteNode(ExplorerNode node) async {
    // Deleting a collection
    if (node.type == NodeType.collection) {
      if (node.getDir() == null) return;

      await deleteDir(node.getDir()!);
      _nodes.remove(node);
    }

    // Deleting a folder
    if (node.type == NodeType.folder) {
      final parentNode = _findParentNode(node);
      if (parentNode == null || node.getDir() == null) return;

      await deleteDir(node.getDir()!);
      parentNode.children.remove(node);
      parentNode.updateChildrenSeq();
    }

    // Deleting a request
    if (node.type == NodeType.request) {
      final parentNode = _findParentNode(node);
      if (parentNode == null) return;

      node.getFile()!.deleteSync();
      parentNode.children.remove(node);
      parentNode.updateChildrenSeq();
    }

    refresh();
  }

  // moveNode moves a node's file to the target node path and refreshes the explorer
  Future<void> moveNode(ExplorerNode movedNode, ExplorerNode targetNode) async {
    // Moving a folder
    if (movedNode.type == NodeType.folder) {
      Directory targetDir = targetNode.getDir()!;
      final sourceDir = movedNode.getDir()!;

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

      final movedToDifferentFolder = parentNodeMoved.getDir()?.path != parentNodeTarget?.getDir()?.path;

      if (targetNode.type == NodeType.folder || targetNode.type == NodeType.collection) {
        // Get the file paths
        final sourceFile = movedNode.getFile()!;
        final targetDir = targetNode.getDir()!;
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
        final sourceFile = movedNode.getFile()!;
        final targetDir = parentNodeTarget.getDir()!;
        final targetPath = path.join(targetDir.path, movedNode.name);

        // Move the file
        sourceFile.copySync(targetPath);
        sourceFile.deleteSync();

        // Update the movedNode's file
        movedNode.setFile(File(targetPath));

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
      refreshedNodes.add(_buildNode(node.getDir()!, 0));
    }

    for (var collNode in _nodes) {
      final refreshedCollNode = refreshedNodes.firstWhereOrNull(
        (node) => node.getDir()?.path == collNode.getDir()?.path,
      );
      if (refreshedCollNode == null) continue;

      _refreshNodes(collNode.children, refreshedCollNode.children);
    }

    _sortNodes(_nodes);
    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  void openNode(ExplorerNode node) {
    final collectionNode = _findRootNodeOf(node);
    if (collectionNode == null) return;

    _eventBus.fire(EventOpenExplorerNode(node, collectionNode.collection!));
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
        final existingNode = existingNodes.firstWhereOrNull(
          (node) => node.getDir()?.path == refreshedNode.getDir()?.path,
        );
        if (existingNode == null) {
          nodesToAdd.add(refreshedNode);
        } else {
          // Recursively sync children
          _refreshNodes(existingNode.children, refreshedNode.children);
        }
      } else if (refreshedNode.type == NodeType.request) {
        // Check if request exists
        final exists = existingNodes.any((node) => node.getFile()?.path == refreshedNode.getFile()?.path);
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
          (refreshedNode) =>
              refreshedNode.type == NodeType.folder && refreshedNode.getDir()?.path == node.getDir()?.path,
        );
        if (!exists) {
          nodesToRemove.add(node);
        }
      } else if (node.type == NodeType.request) {
        final exists = refreshedNodes.any(
          (refreshedNode) =>
              refreshedNode.type == NodeType.request && refreshedNode.getFile()?.path == node.getFile()?.path,
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

      if (depth == 0) {
        final collection = CollectionRepo().load(entity);
        return ExplorerNode.newCollection(name, collection, children);
      } else {
        final folder = FolderRepo().load(entity);
        return ExplorerNode.newFolder(name, folder, children);
      }
    } else {
      final request = RequestRepo().load(entity as File);
      return ExplorerNode.newRequest(name, request);
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
    final collectionNode = _nodes.firstWhereOrNull((node) => path.startsWith(node.getDir()?.path ?? ''));
    if (collectionNode == null) return 0;

    // Strip any file from the path
    final folderPath = path.endsWith('.bru') ? path.substring(0, path.lastIndexOf(Platform.pathSeparator)) : path;

    // Find the folder node that matches the exact path
    late final ExplorerNode? folderNode;
    if (folderPath == collectionNode.getDir()?.path) {
      folderNode = collectionNode;
    } else {
      folderNode = collectionNode.children.firstWhereOrNull(
        (node) => _comparePaths(node.getDir()?.path ?? '', folderPath),
      );
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

  // getNodeHierarchy returns the parent, grandparent and so on of a given node, ending at the collection
  List<ExplorerNode> getNodeHierarchy(ExplorerNode node) {
    final hierarchy = <ExplorerNode>[];
    ExplorerNode? currentNode = node;
    while (currentNode != null) {
      hierarchy.add(currentNode);
      currentNode = _findParentNode(currentNode);
    }

    return hierarchy;
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

  // _findRootNodeOf finds the root collection node of a given node by traversing up its ancestors
  ExplorerNode? _findRootNodeOf(ExplorerNode node) {
    ExplorerNode? currentNode = node;
    while (currentNode != null) {
      if (currentNode.type == NodeType.collection) {
        return currentNode;
      }
      currentNode = _findParentNode(currentNode);
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

Future<void> deleteDir(Directory dir) async {
  if (!await dir.exists()) return;

  await for (var entity in dir.list(recursive: false)) {
    if (entity is Directory) {
      await deleteDir(entity);
    } else if (entity is File) {
      await entity.delete();
    }
  }

  await dir.delete();
}
