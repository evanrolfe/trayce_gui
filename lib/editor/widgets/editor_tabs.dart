import 'package:flutter/material.dart';

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
  final List<String> _tabs = ['grpc', 'http'];
  final List<int> _editorIndices = [0, 1]; // Maps tab positions to original editor positions
  int _selectedTab = 0;
  int? _hoveredTabIndex;

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      // Reorder tabs
      final String item = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, item);

      // Reorder the mapping instead of the actual editors
      final int editorIndex = _editorIndices.removeAt(oldIndex);
      _editorIndices.insert(newIndex, editorIndex);

      if (_selectedTab == oldIndex) {
        _selectedTab = newIndex;
      } else if (_selectedTab > oldIndex && _selectedTab <= newIndex) {
        _selectedTab--;
      } else if (_selectedTab < oldIndex && _selectedTab >= newIndex) {
        _selectedTab++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create fixed list of editors that never changes order
    final fixedEditors = List.generate(
      _tabs.length,
      (index) => FlowEditor(key: ValueKey('editor_$index'), flowType: _tabs[_editorIndices[index]]),
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
              index: _editorIndices[_selectedTab],
              children: fixedEditors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTab == index;
    final isHovered = _hoveredTabIndex == index;

    return ReorderableDragStartListener(
      key: ValueKey(text),
      index: index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _selectedTab = index),
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
                  Text(text, style: tabTextStyle),
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
