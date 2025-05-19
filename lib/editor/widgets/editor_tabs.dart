import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/tab_item.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';
import 'package:uuid/uuid.dart';

import '../../common/style.dart';
import '../../common/tab_style.dart';
import 'flow_editor.dart';

class EditorTabs extends StatefulWidget {
  final double width;

  const EditorTabs({super.key, required this.width});

  @override
  State<EditorTabs> createState() => _EditorTabsState();
}

class _EditorTabsState extends State<EditorTabs> {
  late final StreamSubscription _tabsSub;
  late final StreamSubscription _tabsSub2;
  late final StreamSubscription _tabsSub3;
  late final StreamSubscription _tabsSub4;
  int? _hoveredTabIndex;
  int _selectedTabIndex = 0;
  final List<_TabEntry> _tabs = [];

  @override
  void initState() {
    super.initState();

    // Called when a request is opened from the explorer
    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen((event) {
      setState(() {
        final uuid = const Uuid().v4();
        final newTab = TabItem(node: event.node, key: ValueKey('tabItem_$uuid'), displayName: event.node.name);

        // Check if tab already exists
        final existingIndex = _tabs.indexWhere((entry) => entry.tab.key == newTab.key);
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
          return;
        }

        if (event.node.request == null) return;

        // Add new tab
        _tabs.add(
          _TabEntry(
            tab: newTab,
            editor: FlowEditor(
              key: ValueKey('editor_$uuid'),
              tabKey: newTab.key,
              flowType: 'http',
              request: event.node.request!,
            ),
          ),
        );
        _selectedTabIndex = _tabs.length - 1;
      });
    });

    // Called when a request is modified
    _tabsSub2 = context.read<EventBus>().on<EventEditorNodeModified>().listen((event) {
      final index = _tabs.indexWhere((entry) => entry.tab.key == event.tabKey);
      if (index == -1) {
        return;
      }

      setState(() {
        _tabs[index].tab.isModified = event.isDifferent;
      });
    });

    // Called when a new request is created (i.e. CTRL+N)
    _tabsSub3 = context.read<EventBus>().on<EventNewRequest>().listen((event) {
      setState(() {
        final newTabCount = _tabs.where((entry) => entry.tab.isNew).length;

        // Add new tab
        final uuid = const Uuid().v4();
        final newTab = TabItem(
          node: null,
          isNew: true,
          key: ValueKey('tabItem_$uuid'),
          displayName: 'Untitled-$newTabCount',
        );

        _tabs.add(
          _TabEntry(
            tab: newTab,
            editor: FlowEditor(
              key: ValueKey('editor_$uuid'),
              tabKey: newTab.key,
              flowType: 'http',
              request: Request.blank(),
            ),
          ),
        );
        _selectedTabIndex = _tabs.length - 1;
      });
    });

    // Called when a request is saved (i.e. CTRL+S)
    _tabsSub4 = context.read<EventBus>().on<EventSaveRequest>().listen((event) async {
      final index = _tabs.indexWhere((entry) => entry.tab.key == event.tabKey);
      if (index == -1) {
        return;
      }

      final tab = _tabs[index].tab;
      if (tab.node == null) {
        // Creating a new request
        final path = await _getPath();
        if (path == null) return;

        final fileName = path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;
        final node = ExplorerNode(
          file: File(path),
          name: fileName,
          type: NodeType.request,
          isDirectory: false,
          request: event.request,
        );

        node.save();
        tab.node = node;
        tab.isNew = false;
        tab.displayName = fileName;
      } else {
        // Updating an existing request
        tab.node!.request = event.request;
        tab.node!.save();
      }

      setState(() {
        _tabs[index].tab.isModified = false;
      });
    });
  }

  Future<String?> _getPath() async {
    final config = context.read<Config>();
    late String? path;
    if (config.isTest) {
      path = './test/support/collection1/hello';
    } else {
      List<XTypeGroup> exts = [
        XTypeGroup(label: 'Trayce', extensions: ['bru']),
      ];
      final loc = await getSaveLocation(acceptedTypeGroups: exts, suggestedName: 'untitled.bru');
      if (loc == null) return null;

      path = loc.path;

      // Ensure the path ends with .bru
      if (!path.endsWith('.bru')) path = '$path.bru';
    }

    return path;
  }

  @override
  void dispose() {
    _tabsSub.cancel();
    _tabsSub2.cancel();
    _tabsSub3.cancel();
    _tabsSub4.cancel();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Reorder the tab entry
      final item = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, item);

      // Update selected index
      if (_selectedTabIndex == oldIndex) {
        _selectedTabIndex = newIndex;
      } else if (_selectedTabIndex > oldIndex && _selectedTabIndex <= newIndex) {
        _selectedTabIndex--;
      } else if (_selectedTabIndex < oldIndex && _selectedTabIndex >= newIndex) {
        _selectedTabIndex++;
      }

      // Ensure selected index is valid
      if (_selectedTabIndex >= _tabs.length) {
        _selectedTabIndex = _tabs.length - 1;
      }
    });
  }

  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);

      if (_tabs.isEmpty) {
        _selectedTabIndex = 0;
      } else {
        // If we're closing the selected tab or a tab before it, adjust the index
        if (index <= _selectedTabIndex) {
          _selectedTabIndex = _selectedTabIndex > 0 ? _selectedTabIndex - 1 : 0;
        }
        // Ensure the selected index is within bounds
        if (_selectedTabIndex >= _tabs.length) {
          _selectedTabIndex = _tabs.length - 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          Container(
            height: tabHeight,
            decoration: getTabBarDecoration(),
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              children: _tabs.asMap().entries.map((entry) => _buildTab(entry.value.tab, entry.key)).toList(),
            ),
          ),
          Expanded(
            child:
                _tabs.isEmpty
                    ? const Center(child: Text('No tabs open'))
                    : IndexedStack(index: _selectedTabIndex, children: _tabs.map((entry) => entry.editor).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(TabItem tabItem, int index) {
    final isSelected = _selectedTabIndex == index;
    final isHovered = _hoveredTabIndex == index;

    return ReorderableDragStartListener(
      key: tabItem.key,
      index: index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _selectedTabIndex = index),
          child: Container(
            height: tabHeight,
            padding: tabPadding,
            constraints: tabConstraints,
            decoration: getTabDecoration(isSelected: isSelected, isHovered: isHovered, showTopBorder: true),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file, size: 16, color: lightTextColor),
                  const SizedBox(width: 8),
                  Text(tabItem.getDisplayName(), style: tabTextStyle),
                  if (_tabs.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      // Note: this needs to be onTap, not onTapDown otherwise it initiates a drag sequence which calls a null error
                      // because the tab is deleted
                      onTap: () => _closeTab(index),
                      child: const Icon(Icons.close, size: 16, color: lightTextColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabEntry {
  final TabItem tab;
  final FlowEditor editor;

  _TabEntry({required this.tab, required this.editor});
}
