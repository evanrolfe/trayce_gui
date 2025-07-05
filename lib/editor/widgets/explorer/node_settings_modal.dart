import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/form_table_state.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

Future<void> showNodeSettingsModal(BuildContext context, ExplorerNode node) {
  return showDialog(context: context, builder: (dialogContext) => NodeSettingsModal(node: node));
}

class NodeSettingsModal extends StatefulWidget {
  final ExplorerNode node;
  const NodeSettingsModal({super.key, required this.node});

  @override
  State<NodeSettingsModal> createState() => _NodeSettingsModalState();
}

class _NodeSettingsModalState extends State<NodeSettingsModal> with TickerProviderStateMixin {
  late TabController _tabController;
  late FormTableStateManager _formTableStateManager;
  late String _title;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final config = context.read<Config>();
    final eventBus = context.read<EventBus>();
    final focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    _title = widget.node.type == NodeType.folder ? 'Folder Settings' : 'Collection Settings';

    List<Header> headers = [];
    if (widget.node.type == NodeType.folder) {
      headers = widget.node.folder?.headers ?? [];
    } else if (widget.node.type == NodeType.collection) {
      headers = widget.node.collection?.headers ?? [];
    }

    _formTableStateManager = FormTableStateManager(
      initialRows: headers,
      onStateChanged: () => setState(() {}),
      config: config,
      focusManager: focusManager,
      eventBus: eventBus,
    );
  }

  Future<void> _onSave() async {
    if (widget.node.type == NodeType.folder) {
      widget.node.folder!.headers = _formTableStateManager.getHeaders();
    } else if (widget.node.type == NodeType.collection) {
      widget.node.collection!.headers = _formTableStateManager.getHeaders();
    }
    widget.node.save();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formTableStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: lightBackgroundColor,
      shape: dialogShape,
      child: Container(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFFD4D4D4), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                animationDuration: Duration.zero,
                child: Column(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border(top: BorderSide(width: 1, color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              labelColor: const Color(0xFFD4D4D4),
                              unselectedLabelColor: const Color(0xFF808080),
                              indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(width: 1, color: Color(0xFF4DB6AC)),
                              ),
                              labelPadding: EdgeInsets.zero,
                              padding: EdgeInsets.zero,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelStyle: const TextStyle(fontWeight: FontWeight.normal),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                              tabs: [
                                GestureDetector(
                                  onTapDown: (_) {
                                    _tabController.animateTo(0);
                                  },
                                  child: Container(child: const SizedBox(width: 100, child: Tab(text: 'Headers'))),
                                ),
                                GestureDetector(
                                  onTapDown: (_) {
                                    _tabController.animateTo(1);
                                  },
                                  child: Container(child: const SizedBox(width: 100, child: Tab(text: 'Variables'))),
                                ),
                              ],
                              overlayColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return hoveredItemColor.withAlpha(hoverAlpha);
                                }
                                return null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: backgroundColor,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SingleChildScrollView(
                              child: FormTable(
                                stateManager: _formTableStateManager,
                                onSavePressed: () {
                                  // TODO: Add save functionality
                                },
                              ),
                            ),
                            const Center(child: Text('Todo', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 16))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    key: ValueKey("save_btn"),
                    onPressed: _onSave,
                    style: commonButtonStyle,
                    child: const Text('Save'),
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
