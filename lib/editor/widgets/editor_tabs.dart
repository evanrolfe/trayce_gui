import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/dialog.dart';
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
  late final StreamSubscription _tabsSub5;
  late final StreamSubscription _tabsSub6;
  late final FocusNode _focusNode;
  int? _hoveredTabIndex;
  int? _hoveredCloseButtonIndex;
  int _selectedTabIndex = 0;
  final List<_TabEntry> _tabs = [];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.onKeyEvent = _onKeyEventTabBar;

    // Called when a request is opened from the explorer
    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen((event) {
      setState(() {
        final uuid = const Uuid().v4();
        final newTab = TabItem(node: event.node, key: ValueKey('tabItem_$uuid'), displayName: event.node.name);

        // Check if tab already exists
        final existingIndex = _tabs.indexWhere((entry) => entry.tab.getPath() == newTab.getPath());
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
          return;
        }

        if (event.node.request == null) return;

        // Add new tab
        final tabKey = newTab.key;
        _tabs.add(
          _TabEntry(
            tab: newTab,
            // Bit of a round-about way of letting the user save the flow when focused on a tab,
            // it sends this event to FlowEditorHttpp, which then sends the EventSaveRequest back to us,
            // theres probably a better/cleaner way of doing this
            onSave: () => context.read<EventBus>().fire(EventSaveIntent(tabKey)),
            onNewRequest: () => context.read<EventBus>().fire(EventNewRequest()),
            onCloseCurrentTab: () => _closeCurrentTab(),
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
        final tabKey = newTab.key;
        _tabs.add(
          _TabEntry(
            tab: newTab,
            onSave: () => context.read<EventBus>().fire(EventSaveIntent(tabKey)),
            onNewRequest: () => context.read<EventBus>().fire(EventNewRequest()),
            onCloseCurrentTab: () => _closeCurrentTab(),
            editor: FlowEditor(
              key: ValueKey('editor_$uuid'),
              tabKey: tabKey,
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

        if (mounted) {
          final seq = context.read<ExplorerRepo>().getNextSeq(path);
          event.request.seq = seq;
        }

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

        // Refresh the explorer
        if (mounted) {
          context.read<ExplorerRepo>().refresh();
        }
      } else {
        // Updating an existing request
        tab.node!.request = event.request;
        tab.node!.save();
      }

      setState(() {
        _tabs[index].tab.isModified = false;
      });
    });

    // Called when a node is renamed from the explorer
    _tabsSub5 = context.read<EventBus>().on<EventExplorerNodeRenamed>().listen((event) {
      final tab = _tabs.firstWhereOrNull((entry) => entry.tab.node == event.node);
      if (tab == null) return;

      setState(() {
        tab.tab.displayName = event.node.name;
      });
    });

    // Called when CTRL+W is pressed
    _tabsSub6 = context.read<EventBus>().on<EventCloseCurrentNode>().listen((event) {
      _closeCurrentTab();
    });
  }

  KeyEventResult _onKeyEventTabBar(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN && HardwareKeyboard.instance.isControlPressed) {
        context.read<EventBus>().fire(EventNewRequest());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW && HardwareKeyboard.instance.isControlPressed) {
        _closeCurrentTab();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
    _tabsSub5.cancel();
    _tabsSub6.cancel();
    _focusNode.dispose();
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
    final tab = _tabs[index];

    if (tab.tab.isModified) {
      showConfirmDialog(
        context: context,
        title: 'Close tab',
        message: 'Are you sure you want to close this tab"?',
        onAccept: () => _closeTabNoConfirm(index),
      );
    } else {
      _closeTabNoConfirm(index);
    }
  }

  void _closeTabNoConfirm(int index) {
    setState(() {
      _tabs.removeAt(index);
      _hoveredCloseButtonIndex = null;
      _hoveredTabIndex = null;

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

  void _closeCurrentTab() {
    _closeTab(_selectedTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          Focus(
            focusNode: _focusNode,
            canRequestFocus: true,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => _focusNode.requestFocus(),
              child: Container(
                height: tabHeight,
                decoration: getTabBarDecoration(),
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  children: _tabs.asMap().entries.map((entry) => _buildTab(entry.value, entry.key)).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              canRequestFocus: true,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (_) => _focusNode.requestFocus(),
                child:
                    _tabs.isEmpty
                        ? const Center(child: Text('No tabs open'))
                        : IndexedStack(index: _selectedTabIndex, children: _tabs.map((entry) => entry.editor).toList()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_TabEntry tabEntry, int index) {
    final tabItem = tabEntry.tab;
    final isSelected = _selectedTabIndex == index;
    final isHovered = _hoveredTabIndex == index;

    return ReorderableDragStartListener(
      key: tabItem.key,
      index: index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTapDown: (_) {
            tabEntry.focusNode.requestFocus();
            setState(() => _selectedTabIndex = index);
          },
          child: Focus(
            focusNode: tabEntry.focusNode,
            canRequestFocus: true,
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
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredCloseButtonIndex = index),
                      onExit: (_) => setState(() => _hoveredCloseButtonIndex = null),
                      child: GestureDetector(
                        onTap: () => _closeTab(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                _hoveredCloseButtonIndex == index ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.close, size: 16, color: lightTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
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
  final FocusNode focusNode;
  final void Function() onSave;
  final void Function() onNewRequest;
  final void Function() onCloseCurrentTab;
  _TabEntry({
    required this.tab,
    required this.editor,
    required this.onSave,
    required this.onNewRequest,
    required this.onCloseCurrentTab,
  }) : focusNode = FocusNode() {
    focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.keyS && HardwareKeyboard.instance.isControlPressed) {
          onSave();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyN && HardwareKeyboard.instance.isControlPressed) {
          onNewRequest();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyW && HardwareKeyboard.instance.isControlPressed) {
          onCloseCurrentTab();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }
}
