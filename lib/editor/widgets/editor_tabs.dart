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
  final List<TabItem> _tabs = [];
  List<int> _editorIndices = [0]; // Maps tab positions to original editor positions
  ValueKey? _selectedTabKey; // Track selected tab by its key
  int? _hoveredTabIndex;
  final Map<ValueKey, int> _keyToEditorIndex = {}; // Map from tab key to editor index

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen((event) {
      setState(() {
        final newTab = TabItem(node: event.node);

        final newTabIndex = _tabs.map((e) => e.key).toList().indexOf(newTab.key);
        if (newTabIndex != -1) {
          _selectedTabKey = newTab.key;
          return;
        }

        _tabs.add(newTab);
        _selectedTabKey = newTab.key;
        _editorIndices = List.generate(_tabs.length, (index) => index);
        _keyToEditorIndex[newTab.key] = _tabs.length - 1; // Map the new tab's key to its editor index
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
      // Reorder tabs
      final TabItem item = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, item);

      // Reorder the mapping instead of the actual editors
      final int editorIndex = _editorIndices.removeAt(oldIndex);
      _editorIndices.insert(newIndex, editorIndex);

      // Update the key-to-editor-index map
      _keyToEditorIndex.clear();
      for (int i = 0; i < _tabs.length; i++) {
        _keyToEditorIndex[_tabs[i].key] = _editorIndices[i];
      }

      // Update selected tab key if needed
      if (_selectedTabKey == _tabs[oldIndex].key) {
        _selectedTabKey = _tabs[newIndex].key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final editors = List.generate(
      _tabs.length,
      (i) => FlowEditor(key: ValueKey('editor_$i'), flowType: 'http', request: _tabs[i].node.getRequest()!),
    );

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
              children: _tabs.asMap().entries.map((entry) => _buildTab(entry.value, entry.key)).toList(),
            ),
          ),
          Expanded(
            child: IndexedStack(
              // Use the mapping to show the correct editor
              index: _selectedTabKey != null ? _keyToEditorIndex[_selectedTabKey] ?? 0 : 0,
              children: editors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(TabItem tabItem, int index) {
    final isSelected = _selectedTabKey == tabItem.key;
    final isHovered = _hoveredTabIndex == index;

    return ReorderableDragStartListener(
      key: tabItem.key,
      index: index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _selectedTabKey = tabItem.key),
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
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 16, color: lightTextColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
