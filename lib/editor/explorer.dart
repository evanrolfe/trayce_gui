import 'package:flutter/material.dart';

import '../common/context_menu_style.dart';
import 'explorer_style.dart';
import 'file_node.dart';

const double itemHeight = 22;

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key, required this.width});

  final double width;

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  FileNode? _hoveredNode;
  FileNode? _selectedNode;
  late final List<FileNode> _files;

  @override
  void initState() {
    super.initState();
    _files = [
      FileNode(
        name: 'src',
        isDirectory: true,
        isExpanded: true,
        initialChildren: [
          FileNode(name: 'main.dart'),
          FileNode(name: 'utils.dart'),
          FileNode(
            name: 'widgets',
            isDirectory: true,
            initialChildren: [FileNode(name: 'button.dart'), FileNode(name: 'input.dart')],
          ),
        ],
      ),
      FileNode(name: 'test', isDirectory: true, initialChildren: [FileNode(name: 'widget_test.dart')]),
      FileNode(name: 'README.md'),
      FileNode(name: 'pubspec.yaml'),
      FileNode(name: '.gitignore'),
    ];

    // Sort initial files
    _sortNodes(_files);
    for (var node in _files) {
      if (node.isDirectory) {
        _sortNodes(node.children);
      }
    }
  }

  void _sortNodes(List<FileNode> nodes) {
    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });
  }

  Widget _buildFileTree(FileNode node, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Draggable<FileNode>(
          data: node,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.only(left: indent + fileTreeLeftMargin),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (node.isDirectory) const Icon(Icons.keyboard_arrow_right, color: textColor, size: 16),
                  if (!node.isDirectory) const Icon(Icons.insert_drive_file, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text(node.name, style: const TextStyle(color: textColor, fontSize: 13)),
                ],
              ),
            ),
          ),
          child: DragTarget<FileNode>(
            onWillAccept: (data) {
              if (data == null) return false;
              if (data == node) return false;

              if (data.isDirectory) {
                FileNode? parent = _findParentNode(node);
                while (parent != null) {
                  if (parent == data) return false;
                  parent = _findParentNode(parent);
                }
              }

              return true;
            },
            onAccept: (data) {
              setState(() {
                _removeNode(data);
                if (node.isDirectory) {
                  node.children.add(data);
                  _sortNodes(node.children);
                } else {
                  final parentNode = _findParentNode(node);
                  if (parentNode != null) {
                    final index = parentNode.children.indexOf(node);
                    parentNode.children.insert(index + 1, data);
                    _sortNodes(parentNode.children);
                  } else {
                    _files.add(data);
                    _sortNodes(_files);
                  }
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredNode = node),
                onExit: (_) => setState(() => _hoveredNode = null),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNode = node;
                      if (node.isDirectory) {
                        node.isExpanded = !node.isExpanded;
                      }
                    });
                  },
                  onSecondaryTapDown: (details) {
                    _showContextMenu(context, details.globalPosition, node);
                  },
                  child: Container(
                    height: itemHeight,
                    padding: EdgeInsets.only(left: indent + fileTreeLeftMargin),
                    decoration: getItemDecoration(
                      isHovered: _hoveredNode == node,
                      isSelected: _selectedNode == node,
                      isDragTarget: candidateData.isNotEmpty,
                    ),
                    child: Row(
                      children: [
                        if (node.isDirectory)
                          Icon(
                            node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            color: textColor,
                            size: 16,
                          ),
                        if (!node.isDirectory) const Icon(Icons.insert_drive_file, color: fileIconColor, size: 16),
                        const SizedBox(width: 8),
                        Text(node.name, style: itemTextStyle),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileTree(child, indent: indent + 24)),
      ],
    );
  }

  void _removeNode(FileNode node) {
    if (_files.remove(node)) return;

    for (var file in _files) {
      if (_removeNodeFromChildren(file, node)) return;
    }
  }

  bool _removeNodeFromChildren(FileNode parent, FileNode nodeToRemove) {
    if (parent.children.remove(nodeToRemove)) return true;

    for (var child in parent.children) {
      if (_removeNodeFromChildren(child, nodeToRemove)) return true;
    }

    return false;
  }

  FileNode? _findParentNode(FileNode node) {
    for (var file in _files) {
      final parent = _findParentInNode(file, node);
      if (parent != null) return parent;
    }
    return null;
  }

  FileNode? _findParentInNode(FileNode current, FileNode node) {
    if (current.children.contains(node)) return current;

    for (var child in current.children) {
      final parent = _findParentInNode(child, node);
      if (parent != null) return parent;
    }

    return null;
  }

  void _showContextMenu(BuildContext context, Offset position, FileNode node) async {
    final selected = await showMenu<String>(
      context: context,
      popUpAnimationStyle: contextMenuAnimationStyle,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: contextMenuColor,
      shape: contextMenuShape,
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          height: 30,
          child: const Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal)),
        ),
        PopupMenuItem<String>(
          value: 'cut',
          height: 30,
          child: const Text('Cut', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal)),
        ),
        PopupMenuItem<String>(
          value: 'paste',
          height: 30,
          child: const Text('Paste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal)),
        ),
      ],
    );
    if (selected == 'copy') {
      print('Copy "${node.name}"');
    } else if (selected == 'cut') {
      print('Cut "${node.name}"');
    } else if (selected == 'paste') {
      print('Paste into "${node.name}"');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: itemHeight,
              padding: const EdgeInsets.only(left: fileTreeLeftMargin),
              alignment: Alignment.centerLeft,
              decoration: headerDecoration,
              child: const Text('Editor', style: TextStyle(color: textColor, fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.only(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._files.map((node) => _buildFileTree(node)).toList(),
                  DragTarget<FileNode>(
                    onWillAccept: (data) {
                      if (data == null) return false;
                      return _findParentNode(data) != null;
                    },
                    onAccept: (data) {
                      setState(() {
                        _removeNode(data);
                        _files.add(data);
                        _sortNodes(_files);
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        height: itemHeight,
                        decoration: getItemDecoration(isDragTarget: candidateData.isNotEmpty),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
