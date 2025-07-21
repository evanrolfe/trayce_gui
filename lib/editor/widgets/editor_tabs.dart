import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'splash_page.dart';

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
  String _selectedTabUuid = '';
  Collection? _currentCollection;

  final Map<Collection, List<TabItem>> _tabsMap = {};

  // TODO: This needs to work with multiple collections
  final List<FlowEditor> _tabEditors = [];

  // Environment dropdown state
  final Map<Collection, String> _selectedEnvironment = {};

  List<TabItem> currentTabs() {
    return _tabsMap[_currentCollection] ?? [];
  }

  void addTab(TabItem tab) {
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
    _tabsSub = context.read<EventBus>().on<EventOpenExplorerNode>().listen(_onEventOpenExplorerNode);

    // Called when a request is modified
    _tabsSub2 = context.read<EventBus>().on<EventEditorNodeModified>().listen(_onEventEditorNodeModified);

    // Called when a new request is created (i.e. CTRL+N)
    _tabsSub3 = context.read<EventBus>().on<EventNewRequest>().listen(_onEventNewRequest);

    // Called when a request is saved (i.e. CTRL+S)
    _tabsSub4 = context.read<EventBus>().on<EventSaveRequest>().listen(_onEventSaveRequest);

    // Called when a node is renamed from the explorer
    _tabsSub5 = context.read<EventBus>().on<EventExplorerNodeRenamed>().listen(_onEventExplorerNodeRenamed);

    // Called when CTRL+W is pressed
    _tabsSub6 = context.read<EventBus>().on<EventCloseCurrentNode>().listen((event) {});

    // Called when the selected environment is changed
    _tabsSub7 = context.read<EventBus>().on<EventEnvironmentsChanged>().listen((event) {});
  }

  void _onEventOpenExplorerNode(EventOpenExplorerNode event) {
    setState(() {
      _currentCollection = event.collection;

      final path = event.node.getFile()?.path;
      if (path == null) return;

      // Check if tab already exists
      final existingTab = currentTabs().firstWhereOrNull((entry) => entry.getPath() == path);
      if (existingTab != null) {
        setState(() {
          _selectedTabUuid = existingTab.uuid;
        });
        return;
      }

      final uuid = const Uuid().v4();
      final tabKey = ValueKey('tabItem_$uuid');

      final focusNode = FocusNode();
      focusNode.onKeyEvent = _createOnKeyEventTabItem(tabKey);

      // Create the editor widget
      final editor = FlowEditor(
        uuid: uuid,
        key: ValueKey('editor_$uuid'),
        tabKey: tabKey,
        flowType: 'http',
        node: event.node,
        request: event.node.request!,
      );
      _tabEditors.add(editor);

      // Create the tab item
      final newTab = TabItem(
        uuid: uuid,
        node: event.node,
        key: tabKey,
        displayName: event.node.displayName(),
        focusNode: focusNode,
        editor: editor,
      );

      if (event.node.request == null) return;

      // Add new tab
      addTab(newTab);
      _selectedTabUuid = newTab.uuid;
    });
  }

  void _onEventEditorNodeModified(EventEditorNodeModified event) {
    final modifiedTab = currentTabs().firstWhereOrNull((entry) => entry.key == event.tabKey);
    if (modifiedTab == null) {
      return;
    }

    setState(() {
      modifiedTab.isModified = event.isDifferent;
    });
  }

  void _onEventNewRequest(EventNewRequest event) {
    setState(() {
      setState(() {
        final newTabCount = currentTabs().where((tab) => tab.isNew).length;

        final uuid = const Uuid().v4();
        final tabKey = ValueKey('tabItem_$uuid');

        final focusNode = FocusNode();
        focusNode.onKeyEvent = _createOnKeyEventTabItem(tabKey);

        // Create the editor widget
        final editor = FlowEditor(
          uuid: uuid,
          key: ValueKey('editor_$uuid'),
          tabKey: tabKey,
          flowType: 'http',
          node: null,
          request: Request.blank(),
        );
        _tabEditors.add(editor);

        // Create the tab item
        final newTab = TabItem(
          uuid: uuid,
          node: null,
          key: tabKey,
          displayName: 'Untitled-$newTabCount',
          focusNode: focusNode,
          isNew: true,
          editor: editor,
        );

        addTab(newTab);
        _selectedTabUuid = newTab.uuid;
      });
    });
  }

  void _onEventSaveRequest(EventSaveRequest event) async {
    final tab = currentTabs().firstWhereOrNull((entry) => entry.key == event.tabKey);
    if (tab == null) return;

    final request = event.request;

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

      request.file = File(path);
      final fileName = path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;
      final node = ExplorerNode(name: fileName, type: NodeType.request, isDirectory: false, request: request);

      tab.node = node;
      tab.isNew = false;
      tab.displayName = node.displayName();

      print('saving request: ${tab.node!.request!.file?.path}');
      RequestRepo().save(tab.node!.request!);

      // Refresh the explorer
      if (mounted) {
        context.read<ExplorerService>().refresh();
      }
    } else {
      // Updating an existing request
      tab.node!.request = request;
      RequestRepo().save(tab.node!.request!);
    }

    setState(() {
      tab.isModified = false;
    });
  }

  void _onEventExplorerNodeRenamed(EventExplorerNodeRenamed event) {
    final tab = currentTabs().firstWhereOrNull((entry) => entry.node == event.node);
    if (tab == null) return;

    setState(() {
      tab.displayName = event.node.displayName();
    });
  }

  KeyEventResult Function(FocusNode, KeyEvent) _createOnKeyEventTabItem(ValueKey tabKey) {
    return (FocusNode node, KeyEvent event) {
      final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
          context.read<EventBus>().fire(EventSaveIntent(tabKey));
          return KeyEventResult.handled;
        }
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
    };
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
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      // Dont let them drag past the + tab
      if (newIndex >= currentTabs().length) return;

      // Reorder the tab entry
      final item = currentTabs().removeAt(oldIndex);
      currentTabs().insert(newIndex, item);
    });
  }

  void _closeTab(int index) {}

  void _closeTabNoConfirm(int index) {}

  void _closeCurrentTab() {
    // _closeTab(_selectedTabIndex);
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
      mainContent = SplashPage(focusNode: _focusNode);
    } else if (currentTabs().isEmpty) {
      mainContent = Center(child: Text('No tabs open', style: TextStyle(color: lightTextColor)));
    } else {
      final selectedIndex = _tabEditors.indexWhere((entry) => entry.uuid == _selectedTabUuid);

      mainContent = IndexedStack(index: selectedIndex, children: _tabEditors);
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
                            ...currentTabs().asMap().entries.map((entry) => _buildTab(entry.value, entry.key)),
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

  Widget _buildTab(TabItem tabEntry, int index) {
    final isSelected = tabEntry.uuid == _selectedTabUuid;
    final isHovered = _hoveredTabIndex == index;

    return ReorderableDragStartListener(
      key: tabEntry.key,
      index: index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTapDown: (_) {
            tabEntry.focusNode.requestFocus();
            setState(() => _selectedTabUuid = tabEntry.uuid);
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
                    Text(tabEntry.getDisplayName(), style: tabTextStyle),
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
