import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/form_table_state.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

Future<void> showEnvironmentsModal(BuildContext context) {
  return showDialog(context: context, builder: (dialogContext) => EnvironmentsModal());
}

class EnvironmentsModal extends StatefulWidget {
  const EnvironmentsModal({super.key});

  @override
  State<EnvironmentsModal> createState() => _EnvironmentsModalState();
}

class _EnvironmentsModalState extends State<EnvironmentsModal> {
  late FormTableStateManager _varsController;
  late String _title;
  late List<String> _environments;
  late int _selectedEnvironmentIndex;
  @override
  void initState() {
    super.initState();

    final config = context.read<Config>();
    final eventBus = context.read<EventBus>();
    final focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    _title = 'Environments';
    _environments = ['Dev', 'Test', 'Prod'];
    _selectedEnvironmentIndex = 0;
    //  widget.node.type == NodeType.folder ? 'Folder Settings' : 'Collection Settings';

    // Vars
    // List<Variable> vars = [];
    // if (widget.node.type == NodeType.folder) {
    //   vars = widget.node.folder?.requestVars ?? [];
    // } else if (widget.node.type == NodeType.collection) {
    //   vars = widget.node.collection?.requestVars ?? [];
    // }

    // Convert the params to Headers for the FormTableStateManager
    // List<Header> varsForManager = [];
    // varsForManager = vars.map((p) => Header(name: p.name, value: p.value ?? '', enabled: p.enabled)).toList();
    _varsController = FormTableStateManager(
      onStateChanged: () => setState(() {}),
      initialRows: [],
      config: config,
      focusManager: focusManager,
      eventBus: eventBus,
    );
  }

  Future<void> _onSave() async {
    // Save Variables
    // if (widget.node.type == NodeType.folder) {
    //   widget.node.folder!.requestVars = _varsController.getVars();
    // } else if (widget.node.type == NodeType.collection) {
    //   widget.node.collection!.requestVars = _varsController.getVars();
    // }

    // widget.node.save();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _varsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: lightBackgroundColor,
      shape: dialogShape,
      child: Container(
        width: 800,
        height: 600,
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
                    style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: lightTextColor, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Vertical Tab Bar
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(right: BorderSide(width: 1, color: borderColor)),
                    ),
                    child: Column(
                      children:
                          _environments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final environment = entry.value;
                            final isSelected = index == _selectedEnvironmentIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEnvironmentIndex = index;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? lightBackgroundColor : Colors.transparent,
                                  border: Border(
                                    left: BorderSide(
                                      width: 2,
                                      color: isSelected ? highlightBorderColor : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  environment,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : lightTextColor,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  // Content Area
                  Expanded(
                    child: Container(
                      color: backgroundColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, left: 16),
                            child: Text('Variables', style: const TextStyle(color: lightTextColor, fontSize: 14)),
                          ),
                          Expanded(child: SingleChildScrollView(child: FormTable(stateManager: _varsController))),
                        ],
                      ),
                    ),
                  ),
                ],
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
