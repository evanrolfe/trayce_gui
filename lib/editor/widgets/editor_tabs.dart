import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/editor/models/tab_item.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

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
  int? _hoveredTabIndex;
  int _selectedTabIndex = 0;
  final List<_TabEntry> _tabs = [];

  @override
  void initState() {
    super.initState();

    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen((event) {
      setState(() {
        final newTab = TabItem(node: event.node);

        // Check if tab already exists
        final existingIndex = _tabs.indexWhere((entry) => entry.tab.key == newTab.key);
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
          return;
        }

        // Add new tab
        _tabs.add(
          _TabEntry(
            tab: newTab,
            editor: FlowEditor(
              key: ValueKey('editor_${newTab.key}'),
              flowType: 'http',
              request: newTab.node.getRequest()!,
            ),
          ),
        );
        _selectedTabIndex = _tabs.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _tabsSub.cancel();
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
                  Text(tabItem.node.name, style: tabTextStyle),
                  if (_tabs.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTapDown: (_) => _closeTab(index),
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
  final Widget editor;

  _TabEntry({required this.tab, required this.editor});
}
