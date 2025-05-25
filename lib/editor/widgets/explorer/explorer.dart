import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int lastClickmilliseconds = DateTime.now().millisecondsSinceEpoch;
  late final FocusNode _focusNode;
  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _displaySub = context.read<EventBus>().on<EventDisplayExplorerItems>().listen((event) {
      setState(() {
        _files = event.nodes;
      });
    });

    _focusNode = FocusNode();
    _focusNode.onKeyEvent = _onKeyUp;

    final config = context.read<Config>();
    if (!config.isTest) {
      context.read<ExplorerRepo>().openCollection('/home/evan/Code/trayce/gui/test/support/collection1');
    }
  }

  KeyEventResult _onKeyUp(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN && HardwareKeyboard.instance.isControlPressed) {
        context.read<EventBus>().fire(EventNewRequest());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _displaySub.cancel();
    _focusNode.dispose();
    super.dispose();
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
      path = './test/support/collection1';
    } else {
      // Need to find a way to mock the file selector in integration tests
      path = await getDirectoryPath();
    }

    return path;
  }

  bool _shouldShowDropLineBelow(ExplorerNode targetNode, List<ExplorerNode?> candidateData) {
    if (targetNode.type != NodeType.request) return false;

    if (_dropPosition == null || candidateData.isEmpty) return false;

    final movedNode = candidateData.first;
    if (movedNode?.type != NodeType.request && targetNode.type == NodeType.request) return false;

    return _dropPosition == _files.indexOf(targetNode);
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
            onWillAcceptWithDetails: (details) {
              final targetNode = node;
              final movedNode = details.data;

              if (movedNode.type == NodeType.folder && targetNode.type == NodeType.request) return false;

              return true;
            },
            onAcceptWithDetails: (details) {
              final movedNode = details.data;
              context.read<ExplorerRepo>().moveNode(movedNode, node);

              setState(() {
                _dropPosition = null;
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
                        showNodeMenu(context, details, node, () {
                          _renameController.text = node.name;
                          _renameController.selection = TextSelection.fromPosition(
                            TextPosition(offset: node.name.length),
                          );
                          setState(() {
                            node.isRenaming = true;
                          });
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
                            if (node.isRenaming)
                              Expanded(
                                child: TextField(
                                  controller: _renameController,
                                  style: itemTextStyle,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF474747), width: 1),
                                    ),
                                    fillColor: Color(0xFF2E2E2E),
                                    filled: true,
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      node.isRenaming = false;
                                    });
                                  },
                                  onEditingComplete: () {
                                    setState(() {
                                      node.isRenaming = false;
                                    });
                                  },
                                ),
                              )
                            else
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
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileTree(child, indent: indent + 24)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: true,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focusNode.requestFocus(),
        child: Container(
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
                    children: [..._files.map((node) => _buildFileTree(node))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
