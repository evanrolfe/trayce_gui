import 'dart:io';

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
  List<ExplorerNode> _nodes = [];

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

    final collectionNode = buildNode(collectionDir, 0);
    _nodes.add(collectionNode);

    _eventBus.fire(EventDisplayExplorerItems(_nodes));
  }

  // Helper function to recursively build ExplorerNodes
  ExplorerNode buildNode(FileSystemEntity entity, int depth) {
    // Use basename from path for both files and directories
    final name = entity.path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;

    if (entity is Directory) {
      final children = entity.listSync().where(_shouldIncludeEntity).map((e) => buildNode(e, depth + 1)).toList();

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

// final nodes = [
//   ExplorerNode(
//     name: dirName, // Use the extracted directory name
//     isDirectory: true,
//     initialChildren: [
//       ExplorerNode(name: 'main.dart'),
//       ExplorerNode(name: 'utils.dart'),
//       ExplorerNode(
//         name: 'widgets',
//         isDirectory: true,
//         initialChildren: [ExplorerNode(name: 'button.dart'), ExplorerNode(name: 'input.dart')],
//       ),
//     ],
//   ),
//   ExplorerNode(name: 'test', isDirectory: true, initialChildren: [ExplorerNode(name: 'widget_test.dart')]),
//   ExplorerNode(name: 'README.md'),
//   ExplorerNode(name: 'pubspec.yaml'),
//   ExplorerNode(name: '.gitignore'),
// ];
