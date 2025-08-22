import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';

Future<void> showRuntimeVarsModal(BuildContext context) {
  return showDialog(context: context, builder: (dialogContext) => RuntimeVarsModal());
}

class RuntimeVarsModal extends StatefulWidget {
  const RuntimeVarsModal({super.key});

  @override
  State<RuntimeVarsModal> createState() => _RuntimeVarsModalState();
}

class _RuntimeVarsModalState extends State<RuntimeVarsModal> {
  late FormVarsController _varsController;
  late EditorFocusManager _focusManager;
  late String _title;

  @override
  void initState() {
    super.initState();

    final config = context.read<ConfigRepo>().get();
    final eventBus = context.read<EventBus>();
    final filePicker = context.read<FilePickerI>();
    _focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    _title = 'Runtime Variables';

    // Vars
    List<Variable> vars = context.read<RuntimeVarsRepo>().vars;

    _varsController = FormVarsController(
      onStateChanged: () => setState(() {}),
      initialRows: vars,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );
  }

  Future<void> _onSave() async {
    final repo = context.read<RuntimeVarsRepo>();
    repo.clearVars();

    for (final varr in _varsController.getVars()) {
      repo.setVar(varr.name, varr.value ?? '');
    }

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
                    style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  HoverableIconButton(onPressed: () => Navigator.of(context).pop(), icon: Icons.close),
                ],
              ),
            ),
            Container(height: 1, color: borderColor),
            Expanded(
              child: Container(
                color: backgroundColor,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          'Runtime variables can be set here or by calling bru.setVar() in scripts.',
                          style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
                        ),
                      ),
                      FormTable(
                        controller: _varsController,
                        columns: [
                          FormTableColumn.enabled,
                          FormTableColumn.key,
                          FormTableColumn.value,
                          FormTableColumn.delete,
                        ],
                      ),
                    ],
                  ),
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
