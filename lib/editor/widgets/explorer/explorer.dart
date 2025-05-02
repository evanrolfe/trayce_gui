import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

import '../../../common/context_menu_style.dart';
import '../../models/explorer_node.dart';
import 'explorer_style.dart';

const double itemHeight = 22;

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key, required this.width});

  final double width;

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  ExplorerNode? _hoveredNode;
  ExplorerNode? _selectedNode;
  List<ExplorerNode> _files = [];
  late final StreamSubscription _displaySub;
  int? _dropPosition;
  ExplorerNode? _dropTargetDir;

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _displaySub = context.read<EventBus>().on<EventDisplayExplorerItems>().listen((event) {
      setState(() {
        _files = event.nodes;
      });
    });

    context.read<ExplorerRepo>().openCollection('/home/evan/Code/bruno/test');
  }

  @override
  void dispose() {
    _displaySub.cancel();
    super.dispose();
  }

  void _sortNodes(List<ExplorerNode> nodes) {
    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });
  }

  Future<void> _handleOpen() async {
    final String? path = await getDirectoryPath(initialDirectory: '/home/evan/Code/bruno/test');

    if (path != null && mounted) {
      context.read<ExplorerRepo>().openCollection(path);
    }
  }

  bool _shouldShowDropLineBelow(ExplorerNode node, List<ExplorerNode?> candidateData) {
    if (_dropPosition == null || _dropPosition != _files.indexOf(node) || candidateData.isEmpty) return false;
    return !node.isDirectory;
  }

  Widget _buildFileTree(ExplorerNode node, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Draggable<ExplorerNode>(
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
          child: DragTarget<ExplorerNode>(
            onWillAccept: (data) {
              if (data == null) return false;
              if (data == node) return false;

              if (data.isDirectory) {
                ExplorerNode? parent = _findParentNode(node);
                while (parent != null) {
                  if (parent == data) return false;
                  parent = _findParentNode(parent);
                }
              }

              if (node.isDirectory) {
                setState(() {
                  _dropTargetDir = node;
                });
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
                _dropTargetDir = null;
              });
            },
            onMove: (details) {
              setState(() {
                _dropPosition = _files.indexOf(node);
              });
            },
            onLeave: (data) {
              setState(() {
                _dropPosition = null;
                if (_dropTargetDir == node) _dropTargetDir = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Column(
                children: [
                  MouseRegion(
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
                  ),
                  if (_shouldShowDropLineBelow(node, candidateData))
                    Container(
                      height: 1,
                      color: Colors.white,
                      margin: EdgeInsets.only(left: indent + fileTreeLeftMargin),
                    ),
                ],
              );
            },
          ),
        ),
        if (node.isDirectory && node.isExpanded) ..._buildDirChildrenWithDropLine(node, indent: indent + 24),
      ],
    );
  }

  List<Widget> _buildDirChildrenWithDropLine(ExplorerNode dir, {required double indent}) {
    if (dir.children.isEmpty) return [];
    final children = <Widget>[];
    if (_dropTargetDir == dir) {
      children.add(
        Container(height: 1, color: Colors.white, margin: EdgeInsets.only(left: indent + fileTreeLeftMargin)),
      );
    }
    children.addAll(dir.children.map((child) => _buildFileTree(child, indent: indent)));
    return children;
  }

  void _removeNode(ExplorerNode node) {
    if (_files.remove(node)) return;

    for (var file in _files) {
      if (_removeNodeFromChildren(file, node)) return;
    }
  }

  bool _removeNodeFromChildren(ExplorerNode parent, ExplorerNode nodeToRemove) {
    if (parent.children.remove(nodeToRemove)) return true;

    for (var child in parent.children) {
      if (_removeNodeFromChildren(child, nodeToRemove)) return true;
    }

    return false;
  }

  ExplorerNode? _findParentNode(ExplorerNode node) {
    for (var file in _files) {
      final parent = _findParentInNode(file, node);
      if (parent != null) return parent;
    }
    return null;
  }

  ExplorerNode? _findParentInNode(ExplorerNode current, ExplorerNode node) {
    if (current.children.contains(node)) return current;

    for (var child in current.children) {
      final parent = _findParentInNode(child, node);
      if (parent != null) return parent;
    }

    return null;
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Editor', style: TextStyle(color: textColor, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: textColor, size: 16),
                    padding: const EdgeInsets.only(right: 5),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final anchors = TextSelectionToolbarAnchors(
                        primaryAnchor: Offset(widget.width + 40, itemHeight + 32),
                      );
                      showMenu(
                        popUpAnimationStyle: contextMenuAnimationStyle,
                        context: context,
                        position: RelativeRect.fromSize(
                          anchors.primaryAnchor & const Size(150, double.infinity),
                          MediaQuery.of(context).size,
                        ),
                        color: contextMenuColor,
                        shape: contextMenuShape,
                        items: [
                          PopupMenuItem(
                            height: 30,
                            child: Text('Open Collection', style: contextMenuTextStyle),
                            onTap: () => _handleOpen(),
                          ),
                          PopupMenuItem(
                            height: 30,
                            child: Text('New Collection', style: contextMenuTextStyle),
                            onTap: () {
                              print('New Collection');
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._files.map((node) => _buildFileTree(node)).toList(),
                  DragTarget<ExplorerNode>(
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
