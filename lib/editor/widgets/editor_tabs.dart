import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/dialog.dart';
import 'package:trayce/common/dropdown_style.dart';
import 'package:trayce/common/environments_global_modal.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/tab_item.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/global_environment_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/widgets/common/environments_modal.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';
import 'package:trayce/editor/widgets/runtime_vars_modal.dart';
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
  String _selectedTabUuid = '';
  Collection? _currentCollection;
  ExplorerNode? _currentCollectionNode;

  final Map<Collection, List<TabItem>> _tabsMap = {};
  final List<FlowEditor> _tabEditors = [];
  late final ScrollController _tabScrollController;

  // Environment dropdown state
  final Map<Collection, String> _selectedEnvironment = {};

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNodeBtn = FocusNode();
    _tabScrollController = ScrollController();
    _focusNode.onKeyEvent = _onKeyEventTabBar;
    _focusNodeBtn.onKeyEvent = _onKeyEventTabBar;

    // Called when a collection is opened from the explorer
    _tabsSub0 = context.read<EventBus>().on<EventCollectionOpened>().listen((event) {
      setState(() {
        _currentCollection = event.collection;
        _currentCollectionNode = event.node;
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
    _tabsSub6 = context.read<EventBus>().on<EventCloseCurrentNode>().listen(_onEventCloseCurrentNode);

    // Called when the selected environment is changed
    _tabsSub7 = context.read<EventBus>().on<EventEnvironmentsChanged>().listen(_onEventEnvironmentsChanged);
  }

  void _onEventOpenExplorerNode(EventOpenExplorerNode event) {
    setState(() {
      _currentCollection = event.collectionNode.collection;
      _currentCollectionNode = event.collectionNode;

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
        collectionNode: _currentCollectionNode!,
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
          collectionNode: _currentCollectionNode!,
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

      tab.isNew = false;
      // We only create a node so we can get its displayName:
      tab.displayName = ExplorerNode(name: fileName, type: NodeType.request).displayName();

      RequestRepo().save(request);

      // Refresh the explorer
      if (mounted) {
        context.read<ExplorerService>().refresh();

        final p = request.file?.path ?? '';
        final node = context.read<ExplorerService>().findNodeByPath(p);
        if (node != null) {
          // This is a bit hacky, but because the tab we need to associate the ExplorerNode from the explorer
          // with this tab. Because the tab was created before the ExplorerNode was created.
          // Otherwise the tab.node and the node from the explorer will be different instances.
          tab.node = node;
        }
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

  void _onEventEnvironmentsChanged(EventEnvironmentsChanged event) {
    setState(() {});
  }

  void _onEventCloseCurrentNode(EventCloseCurrentNode event) {
    _closeCurrentTab();
  }

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

  void selectEnvironment(String environmentFilename) {
    if (_currentCollection == null) return;

    _currentCollection!.setCurrentEnvironment(environmentFilename);
    _selectedEnvironment[_currentCollection!] = environmentFilename;
  }

  String getSelectedGlobalEnvironment() {
    final env = context.read<GlobalEnvironmentRepo>().getSelectedEnv();
    if (env == null) return 'No Environment';

    return env.name;
  }

  void selectGlobalEnvironment(String? envName) {
    if (envName == 'No Environment') envName = null;

    context.read<GlobalEnvironmentRepo>().setSelectedEnvName(envName);
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
    final config = context.read<ConfigRepo>().get();
    late String? path;
    if (config.isTest) {
      path = './test/support/collection1/hello';
    } else {
      if (_currentCollection == null) return null;

      final initialDirectory = _currentCollection!.dir.path;
      path = await context.read<FilePickerI>().saveBruFile(initialDirectory);
      if (path == null) return null;

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
    _tabScrollController.dispose();
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

  void _closeTab(TabItem tab) {
    if (tab.isModified) {
      showConfirmDialog(
        context: context,
        title: 'Close tab',
        message: 'Are you sure you want to close this tab"?',
        onAccept: () => _closeTabNoConfirm(tab),
      );
    } else {
      _closeTabNoConfirm(tab);
    }
  }

  void _closeTabNoConfirm(TabItem tab) {
    setState(() {
      final indexRemoved = currentTabs().indexOf(tab);
      final isLastTab = indexRemoved == currentTabs().length - 1;

      currentTabs().remove(tab);
      _tabEditors.removeWhere((entry) => entry.uuid == tab.uuid);

      // if we have close a tab which isn't the currently selected one, then do not change the selection
      if (_selectedTabUuid != tab.uuid) return;

      // if we have no tabs left, then do nothing
      if (currentTabs().isEmpty) return;

      // if the tab removed, is the last one in the tabbar, then select the last tab after removal
      if (isLastTab) {
        _selectedTabUuid = currentTabs().last.uuid;
        return;
      }

      // otherwise select the tab to the right of the removed tab
      _selectedTabUuid = currentTabs()[indexRemoved].uuid;
    });
  }

  void _closeCurrentTab() {
    final currentTab = currentTabs().firstWhereOrNull((entry) => entry.uuid == _selectedTabUuid);
    if (currentTab == null) return;
    _closeTab(currentTab);
  }

  String ensureExt(String path) {
    if (!path.endsWith('.bru')) {
      return '$path.bru';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // Environments for dropdown
    final environments = ['No Environment'];
    if (_currentCollection != null) {
      environments.addAll(_currentCollection!.environments.map((e) => e.fileName()));
    }
    environments.add('Configure');

    final selectedEnvBorderColor =
        getSelectedEnvironment() == 'No Environment' ? Color(0xFF474747) : fadedHighlightBorderColor;
    final selectedEnvTextColor =
        getSelectedEnvironment() == 'No Environment' ? Color(0xFF474747) : highlightBorderColor;

    // Global environments for dropdown
    final globalEnvironments = ['No Environment'];
    globalEnvironments.addAll(context.read<GlobalEnvironmentRepo>().getAll().map((e) => e.name));
    globalEnvironments.add('Configure');

    final selectedGlobalEnv = context.read<GlobalEnvironmentRepo>().getSelectedEnv();
    final globalEnvTooltip =
        selectedGlobalEnv == null ? 'Select Global Environment' : 'Global Environment: ${selectedGlobalEnv.name}';

    final globalEnvIconColor = selectedGlobalEnv == null ? lightTextColor : highlightBorderColor;

    // Tab bar content
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
                        // Listener is used to convert mouse wheel scrolls (vertical) to tabbar scrolls (horizontal)
                        child: Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              // Convert vertical scroll to horizontal scroll
                              final scrollController = _tabScrollController;
                              if (scrollController.hasClients) {
                                final newOffset = (scrollController.offset + pointerSignal.scrollDelta.dy * 4).clamp(
                                  0.0,
                                  scrollController.position.maxScrollExtent,
                                );
                                scrollController.jumpTo(newOffset);
                              }
                            }
                          },
                          // GestureDetector is used to convert two finger touchpad scroll (vertical) to tabbar scrolls (horizontal)
                          child: GestureDetector(
                            onVerticalDragUpdate: (DragUpdateDetails details) {
                              // Convert vertical drag to horizontal scroll
                              final scrollController = _tabScrollController;
                              if (scrollController.hasClients) {
                                final newOffset = (scrollController.offset - details.delta.dy * 4).clamp(
                                  0.0,
                                  scrollController.position.maxScrollExtent,
                                );
                                scrollController.jumpTo(newOffset);
                              }
                            },
                            child: SizedBox(
                              height: tabHeight,
                              child: ReorderableListView(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollController: _tabScrollController,
                                scrollDirection: Axis.horizontal,
                                onReorder: _onReorder,
                                buildDefaultDragHandles: false,
                                children: [
                                  ...currentTabs().asMap().entries.map((entry) => _buildTab(entry.value, entry.key)),
                                  if (_currentCollection != null) _buildPlusTab(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Eye button to open the runtime vars modal
                      Container(
                        width: 25,
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          key: const Key('editor_tabs_runtime_vars_button'),
                          onPressed: () {
                            showRuntimeVarsModal(context);
                          },
                          style: iconButtonStyle,
                          child: const Icon(Icons.visibility, size: 16),
                        ),
                      ),
                      // Settings button to open collection settings
                      Container(
                        width: 25,
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          key: const Key('editor_tabs_collection_settings_button'),
                          onPressed: () {
                            // TODO: Handle eye button press
                          },
                          style: iconButtonStyle,
                          child: const Icon(Icons.settings, size: 16),
                        ),
                      ),
                      // Globe button to open the global environments modal
                      Container(
                        width: 25,
                        margin: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: globalEnvTooltip,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              key: const Key('editor_tabs_global_envs_button'),
                              value: getSelectedGlobalEnvironment(),
                              // Unforunately we can't use an ElevatedButton here because the onPressed callback prevents
                              // the dropdown menu from opening.
                              customButton: _HoverableContainer(
                                child: Icon(Icons.language, size: 16, color: globalEnvIconColor),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                decoration: dropdownDecoration,
                                width: 150,
                                openInterval: Interval(0.0, 0.0),
                              ),
                              buttonStyleData: ButtonStyleData(
                                padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                              ),
                              menuItemStyleData: menuItemStyleData,
                              iconStyleData: iconStyleData,
                              style: textFieldStyle,
                              items:
                                  globalEnvironments.map((String envFileName) {
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

                                if (newValue == 'Configure') {
                                  showGlobalEnvironmentsModal(context);
                                } else {
                                  setState(() {
                                    selectGlobalEnvironment(newValue);
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 20,
                        margin: const EdgeInsets.only(left: 2, right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: selectedEnvBorderColor, width: 1),
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
                    HoverableIconButton(
                      onPressed: () => _closeTab(tabEntry),
                      icon: Icons.close,
                      iconSize: 16,
                      iconColor: lightTextColor,
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

class _HoverableContainer extends StatefulWidget {
  final Widget child;

  const _HoverableContainer({required this.child});

  @override
  State<_HoverableContainer> createState() => _HoverableContainerState();
}

class _HoverableContainerState extends State<_HoverableContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 20,
        height: 18,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF3A3A3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: widget.child,
      ),
    );
  }
}
