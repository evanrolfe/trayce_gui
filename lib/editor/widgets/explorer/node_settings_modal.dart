import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/inline_tab_bar.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';

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
  late FormTableController _headersController;
  late FormVarsController _varsController;
  late String _title;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final config = context.read<Config>();
    final eventBus = context.read<EventBus>();
    final focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    _title = widget.node.type == NodeType.folder ? 'Folder Settings' : 'Collection Settings';

    // Headers
    List<Header> headers = [];
    if (widget.node.type == NodeType.folder) {
      headers = widget.node.folder?.headers ?? [];
    } else if (widget.node.type == NodeType.collection) {
      headers = widget.node.collection?.headers ?? [];
    }

    _headersController = FormTableController(
      initialRows: headers,
      onStateChanged: () => setState(() {}),
      config: config,
      focusManager: focusManager,
      eventBus: eventBus,
    );

    // Vars
    List<Variable> vars = [];
    if (widget.node.type == NodeType.folder) {
      vars = widget.node.folder?.requestVars ?? [];
    } else if (widget.node.type == NodeType.collection) {
      vars = widget.node.collection?.requestVars ?? [];
    }

    _varsController = FormVarsController(
      onStateChanged: () => setState(() {}),
      initialRows: vars,
      config: config,
      focusManager: focusManager,
      eventBus: eventBus,
    );
  }

  Future<void> _onSave() async {
    // Save Headers
    if (widget.node.type == NodeType.folder) {
      widget.node.folder!.headers = _headersController.getHeaders();
    } else if (widget.node.type == NodeType.collection) {
      widget.node.collection!.headers = _headersController.getHeaders();
    }

    // Save Variables
    if (widget.node.type == NodeType.folder) {
      widget.node.folder!.requestVars = _varsController.getVars();
    } else if (widget.node.type == NodeType.collection) {
      widget.node.collection!.requestVars = _varsController.getVars();
    }

    widget.node.save();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headersController.dispose();
    _varsController.dispose();
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
                            child: InlineTabBar(
                              controller: _tabController,
                              tabTitles: const ['Headers', 'Variables'],
                              focusNode: FocusNode(),
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
                            SingleChildScrollView(child: FormTable(controller: _headersController)),
                            SingleChildScrollView(child: FormTable(controller: _varsController)),
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
