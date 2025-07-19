import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/dialog.dart';
import 'package:trayce/common/dropdown_style.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/tab_item.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/widgets/common/environments_modal.dart';
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
  late final StreamSubscription _tabsSub0;
  late final StreamSubscription _tabsSub;
  late final StreamSubscription _tabsSub2;
  late final StreamSubscription _tabsSub3;
  late final StreamSubscription _tabsSub4;
  late final StreamSubscription _tabsSub5;
  late final StreamSubscription _tabsSub6;
  late final StreamSubscription _tabsSub7;
  late final FocusNode _focusNode;
  late final FocusNode _focusNodeBtn;
  int? _hoveredTabIndex;
  int? _hoveredCloseButtonIndex;
  int _selectedTabIndex = 0;
  final Map<Collection, List<_TabEntry>> _tabsMap = {};
  Collection? _currentCollection;

  // Environment dropdown state
  final Map<Collection, String> _selectedEnvironment = {};

  List<_TabEntry> currentTabs() {
    return _tabsMap[_currentCollection] ?? [];
  }

  void addTab(_TabEntry tab) {
    if (_currentCollection == null) return;

    final tabs = _tabsMap[_currentCollection];

    if (tabs == null) {
      _tabsMap[_currentCollection!] = [tab];
    } else {
      tabs.add(tab);
    }
  }

  String getSelectedEnvironment() {
    if (_currentCollection == null) return 'No Environment';

    return _selectedEnvironment[_currentCollection!] ?? 'No Environment';
  }

  void selectEnvironment(String environment) {
    if (_currentCollection == null) return;

    _currentCollection!.currentEnvironmentFilename = environment;
    _selectedEnvironment[_currentCollection!] = environment;
  }

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNodeBtn = FocusNode();
    _focusNode.onKeyEvent = _onKeyEventTabBar;
    _focusNodeBtn.onKeyEvent = _onKeyEventTabBar;

    // Called when a collection is opened from the explorer
    _tabsSub0 = context.read<EventBus>().on<EventCollectionOpened>().listen((event) {
      setState(() {
        _currentCollection = event.collection;
      });
    });

    // Called when a request is opened from the explorer
    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen((event) {
      setState(() {
        _currentCollection = event.collection;

        final uuid = const Uuid().v4();
        final newTab = TabItem(node: event.node, key: ValueKey('tabItem_$uuid'), displayName: event.node.displayName());

        // Check if tab already exists
        final existingIndex = currentTabs().indexWhere((entry) => entry.tab.getPath() == newTab.getPath());
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
          return;
        }

        if (event.node.request == null) return;

        // Add new tab
        final tabKey = newTab.key;
        addTab(
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
              node: event.node,
              request: event.node.request!,
            ),
          ),
        );
        _selectedTabIndex = currentTabs().length - 1;
      });
    });

    // Called when a request is modified
    _tabsSub2 = context.read<EventBus>().on<EventEditorNodeModified>().listen((event) {
      final index = currentTabs().indexWhere((entry) => entry.tab.key == event.tabKey);
      if (index == -1) {
        return;
      }

      setState(() {
        currentTabs()[index].tab.isModified = event.isDifferent;
      });
    });

    // Called when a new request is created (i.e. CTRL+N)
    _tabsSub3 = context.read<EventBus>().on<EventNewRequest>().listen((event) {
      setState(() {
        final newTabCount = currentTabs().where((entry) => entry.tab.isNew).length;

        // Add new tab
        final uuid = const Uuid().v4();
        final newTab = TabItem(
          node: null,
          isNew: true,
          key: ValueKey('tabItem_$uuid'),
          displayName: 'Untitled-$newTabCount',
        );
        final tabKey = newTab.key;
        addTab(
          _TabEntry(
            tab: newTab,
            onSave: () => context.read<EventBus>().fire(EventSaveIntent(tabKey)),
            onNewRequest: () => context.read<EventBus>().fire(EventNewRequest()),
            onCloseCurrentTab: () => _closeCurrentTab(),
            editor: FlowEditor(
              key: ValueKey('editor_$uuid'),
              tabKey: tabKey,
              flowType: 'http',
              node: null,
              request: Request.blank(),
            ),
          ),
        );
        _selectedTabIndex = currentTabs().length - 1;
      });
    });

    // Called when a request is saved (i.e. CTRL+S)
    _tabsSub4 = context.read<EventBus>().on<EventSaveRequest>().listen((event) async {
      final index = currentTabs().indexWhere((entry) => entry.tab.key == event.tabKey);
      if (index == -1) {
        return;
      }

      final tab = currentTabs()[index].tab;
      if (tab.node == null) {
        // Creating a new request
        String? path = await _getPath();
        if (path == null) return;

        if (mounted) {
          final seq = context.read<ExplorerService>().getNextSeq(path);
          event.request.seq = seq;
        }

        // Ensure the path ends with .bru
        path = ensureExt(path);

        final fileName = path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;
        final node = ExplorerNode(
          // file: File(path),
          name: fileName,
          type: NodeType.request,
          isDirectory: false,
          request: event.request,
        );
        node.request!.file = File(path);
        tab.node = node;
        tab.isNew = false;
        tab.displayName = node.displayName();

        RequestRepo().save(tab.node!.request!);

        // Refresh the explorer
        if (mounted) {
          context.read<ExplorerService>().refresh();
        }
      } else {
        // Updating an existing request
        tab.node!.request = event.request;
        RequestRepo().save(tab.node!.request!);
      }

      setState(() {
        currentTabs()[index].tab.isModified = false;
      });
    });

    // Called when a node is renamed from the explorer
    _tabsSub5 = context.read<EventBus>().on<EventExplorerNodeRenamed>().listen((event) {
      final tab = currentTabs().firstWhereOrNull((entry) => entry.tab.node == event.node);
      if (tab == null) return;

      setState(() {
        tab.tab.displayName = event.node.displayName();
      });
    });

    // Called when CTRL+W is pressed
    _tabsSub6 = context.read<EventBus>().on<EventCloseCurrentNode>().listen((event) {
      _closeCurrentTab();
    });

    _tabsSub7 = context.read<EventBus>().on<EventEnvironmentsChanged>().listen((event) {
      setState(() {});
    });
  }

  KeyEventResult _onKeyEventTabBar(FocusNode node, KeyEvent event) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN && isCmdPressed) {
        context.read<EventBus>().fire(EventNewRequest());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW && isCmdPressed) {
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
      if (_currentCollection == null) return null;

      final loc = await getSaveLocation(
        initialDirectory: _currentCollection!.dir.path,
        acceptedTypeGroups: exts,
        suggestedName: 'untitled.bru',
      );
      if (loc == null) return null;

      path = loc.path;

      // Ensure the path ends with .bru
      if (!path.endsWith('.bru')) path = '$path.bru';
    }

    return path;
  }

  @override
  void dispose() {
    _tabsSub0.cancel();
    _tabsSub.cancel();
    _tabsSub2.cancel();
    _tabsSub3.cancel();
    _tabsSub4.cancel();
    _tabsSub5.cancel();
    _tabsSub6.cancel();
    _tabsSub7.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex == currentTabs().length) return;
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Reorder the tab entry
      final item = currentTabs().removeAt(oldIndex);
      currentTabs().insert(newIndex, item);

      // Update selected index
      if (_selectedTabIndex == oldIndex) {
        _selectedTabIndex = newIndex;
      } else if (_selectedTabIndex > oldIndex && _selectedTabIndex <= newIndex) {
        _selectedTabIndex--;
      } else if (_selectedTabIndex < oldIndex && _selectedTabIndex >= newIndex) {
        _selectedTabIndex++;
      }

      // Ensure selected index is valid
      if (_selectedTabIndex >= currentTabs().length) {
        _selectedTabIndex = currentTabs().length - 1;
      }
    });
  }

  void _closeTab(int index) {
    final tab = currentTabs()[index];

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
      currentTabs().removeAt(index);
      _hoveredCloseButtonIndex = null;
      _hoveredTabIndex = null;

      if (currentTabs().isEmpty) {
        _selectedTabIndex = 0;
      } else {
        // If we're closing the selected tab or a tab before it, adjust the index
        if (index <= _selectedTabIndex) {
          _selectedTabIndex = _selectedTabIndex > 0 ? _selectedTabIndex - 1 : 0;
        }
        // Ensure the selected index is within bounds
        if (_selectedTabIndex >= currentTabs().length) {
          _selectedTabIndex = currentTabs().length - 1;
        }
      }
    });
  }

  void _closeCurrentTab() {
    _closeTab(_selectedTabIndex);
  }

  String ensureExt(String path) {
    if (!path.endsWith('.bru')) {
      return '$path.bru';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final environments = ['No Environment'];
    if (_currentCollection != null) {
      environments.addAll(_currentCollection!.environments.map((e) => e.fileName()));
    }
    environments.add('Configure');

    Widget mainContent;
    if (_currentCollection == null) {
      mainContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            SvgPicture.asset(
              'fonts/logo.svg',
              allowDrawingOutsideViewBox: true,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(highlightBorderColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 24),
            const SelectableText('Trayce Request Editor', style: TextStyle(color: lightTextColor, fontSize: 24)),
            const SizedBox(height: 24),
            const SelectableText(
              'Start by creating or opening a collection:',
              style: TextStyle(color: lightTextColor, fontSize: 18),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  key: const Key('editor_tabs_new_collection_button'),
                  onPressed: () {
                    context.read<EventBus>().fire(EventNewCollectionIntent());
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: lightTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: lightTextColor.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text('New Collection'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  key: const Key('editor_tabs_open_collection_button'),
                  onPressed: () {
                    context.read<EventBus>().fire(EventOpenCollectionIntent());
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: lightTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: lightTextColor.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text('Open Collection'),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (currentTabs().isEmpty) {
      mainContent = Container(
        child: const Center(child: Text('No tabs open', style: TextStyle(color: lightTextColor))),
      );
    } else {
      mainContent = IndexedStack(
        index: _selectedTabIndex,
        children: currentTabs().map((entry) => entry.editor).toList(),
      );
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Focus(
              focusNode: _focusNode,
              canRequestFocus: true,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (_) => _focusNode.requestFocus(),
                child: Container(
                  height: tabHeight,
                  decoration: getTabBarDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: ReorderableListView(
                          scrollDirection: Axis.horizontal,
                          onReorder: _onReorder,
                          buildDefaultDragHandles: false,
                          children: [
                            ...currentTabs().asMap().entries.map((entry) => _buildTab(entry.value, entry.key)).toList(),
                            if (_currentCollection != null) _buildPlusTab(),
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          key: const Key('editor_tabs_eye_button'),
                          onPressed: () {
                            // TODO: Handle eye button press
                          },
                          icon: const Icon(Icons.visibility, size: 16, color: lightTextColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: const BorderSide(color: Color(0xFF474747), width: 1),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 20,
                        margin: const EdgeInsets.only(left: 2, right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF474747), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton2<String>(
                          key: const Key('editor_tabs_env_dropdown'),
                          value: getSelectedEnvironment(),
                          underline: Container(),
                          dropdownStyleData: DropdownStyleData(
                            decoration: dropdownDecoration,
                            width: 150,
                            openInterval: Interval(0.0, 0.0),
                          ),
                          buttonStyleData: ButtonStyleData(padding: const EdgeInsets.only(left: 4, top: 2, right: 4)),
                          menuItemStyleData: menuItemStyleData,
                          iconStyleData: iconStyleData,
                          style: textFieldStyle,
                          isExpanded: true,
                          items:
                              environments.map((String envFileName) {
                                return DropdownMenuItem<String>(
                                  value: envFileName,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(envFileName),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue == null) return;

                            // if (_currentCollection == null) return;

                            if (newValue == 'Configure' && _currentCollection != null) {
                              showEnvironmentsModal(context, _currentCollection!);
                            } else if (newValue == 'Configure' && _currentCollection == null) {
                              showMessageDialog(
                                context: context,
                                title: 'No collection open',
                                message: 'Please open a collection and a request to configure environments',
                              );
                            } else {
                              setState(() {
                                selectEnvironment(newValue);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Focus(focusNode: _focusNode, canRequestFocus: true, child: mainContent)),
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

  Widget _buildPlusTab() {
    final isHovered = _hoveredTabIndex == -1; // Use -1 to represent plus tab hover state
    return MouseRegion(
      key: const Key('editor_tabs_plus_tab'),
      onEnter: (_) => setState(() => _hoveredTabIndex = -1),
      onExit: (_) => setState(() => _hoveredTabIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.read<EventBus>().fire(EventNewRequest());
        },
        child: Container(
          height: tabHeight,
          width: 30,
          margin: const EdgeInsets.only(left: 0),
          decoration: getTabPlusDecoration(isSelected: false, isHovered: isHovered, showTopBorder: true),
          child: const Center(child: Icon(Icons.add, size: 16, color: lightTextColor)),
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
      final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
          onSave();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyN && isCmdPressed) {
          onNewRequest();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyW && isCmdPressed) {
          onCloseCurrentTab();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }
}
