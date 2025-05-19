import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

import '../../models/explorer_node.dart';
import 'explorer_style.dart';
import 'menu_node.dart';
import 'menu_root.dart';

const double itemHeight = 22;

class EventNewRequest {
  EventNewRequest();
}

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
  int lastClickmilliseconds = DateTime.now().millisecondsSinceEpoch;
  int _openCount = 0;

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _displaySub = context.read<EventBus>().on<EventDisplayExplorerItems>().listen((event) {
      setState(() {
        _files = event.nodes;
      });
    });

    final config = context.read<Config>();
    if (!config.isTest) {
      context.read<ExplorerRepo>().openCollection('/home/evan/Code/trayce/gui/test/support/collection1');
    }
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
    final path = await _getCollectionPath();

    if (path != null && mounted) {
      context.read<ExplorerRepo>().openCollection(path);
    }
  }

  Future<void> _handleNewRequest() async {
    context.read<EventBus>().fire(EventNewRequest());
  }

  Future<void> _handleRefresh() async {
    context.read<ExplorerRepo>().refresh();
  }

  Future<String?> _getCollectionPath() async {
    final config = context.read<Config>();
    late String? path;
    if (config.isTest) {
      if (_openCount == 0) {
        path = './test/support/collection1';
      } else {
        path = './test/support/collection2';
      }
      _openCount++;
    } else {
      // Need to find a way to mock the file selector in integration tests
      path = await getDirectoryPath();
    }

    return path;
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
                      onTapDown: (_) {
                        // We do this instead of using onDoubleTap because that makes single tap way too slow
                        // See: https://stackoverflow.com/questions/71293804/ondoubletap-makes-ontap-very-slow
                        int currMills = DateTime.now().millisecondsSinceEpoch;
                        if ((currMills - lastClickmilliseconds) < 250) {
                          // Double tap
                          if (node.type == NodeType.request) {
                            context.read<ExplorerRepo>().openNode(node);
                          }
                        } else {
                          // Single tap
                          lastClickmilliseconds = currMills;
                          setState(() {
                            _selectedNode = node;
                            if (node.isDirectory) {
                              node.isExpanded = !node.isExpanded;
                            }
                          });
                        }
                      },
                      onSecondaryTapDown: (details) {
                        showNodeMenu(context, details, node);
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
                    key: const Key('open_collection_btn'),
                    icon: const Icon(Icons.more_horiz, color: textColor, size: 16),
                    padding: const EdgeInsets.only(right: 5),
                    constraints: const BoxConstraints(),
                    onPressed:
                        () => showRootMenu(
                          context,
                          widget.width,
                          itemHeight,
                          _handleOpen,
                          _handleNewRequest,
                          _handleRefresh,
                        ),
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
