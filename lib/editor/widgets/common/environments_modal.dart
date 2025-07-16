import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';

class EventEnvironmentsChanged {}

Future<void> showEnvironmentsModal(BuildContext context, Collection collection) {
  return showDialog(context: context, builder: (dialogContext) => EnvironmentsModal(collection: collection));
}

class EnvironmentsModal extends StatefulWidget {
  final Collection collection;

  const EnvironmentsModal({super.key, required this.collection});

  @override
  State<EnvironmentsModal> createState() => _EnvironmentsModalState();
}

class _EnvironmentsModalState extends State<EnvironmentsModal> {
  late FormVarsController _varsController;
  late String _title;
  late List<Environment> _environments;
  late int _selectedEnvironmentIndex;
  int? _hoveredEnvironmentIndex;
  bool _isEditingFilename = false;
  bool _isHoveringNewButton = false;
  late TextEditingController _filenameController;
  @override
  void initState() {
    super.initState();

    final config = context.read<Config>();
    final eventBus = context.read<EventBus>();
    final focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    _title = 'Environments';
    _environments = widget.collection.environments;
    _selectedEnvironmentIndex = 0;

    _filenameController = TextEditingController(
      text: _environments.isEmpty ? '' : _environments[_selectedEnvironmentIndex].fileName(),
    );

    // Vars
    List<Variable> initialVars = [];
    if (_environments.isNotEmpty) {
      initialVars = _environments[_selectedEnvironmentIndex].vars;
    }

    _varsController = FormVarsController(
      onStateChanged: () => setState(() {}),
      initialRows: initialVars,
      config: config,
      focusManager: focusManager,
      eventBus: eventBus,
    );
  }

  void _selectEnv(int index) {
    _selectedEnvironmentIndex = index;
    _filenameController.text = _environments[index].fileName();
    _isEditingFilename = false;

    _varsController.setVars(_environments[_selectedEnvironmentIndex].vars);
  }

  void _createNewEnvironment() {
    final collectionPath = widget.collection.dir.path;
    final newEnvironment = Environment.blank(collectionPath);
    widget.collection.environments.add(newEnvironment);

    CollectionRepo().save(widget.collection);

    // Update the local environments list
    setState(() {
      _environments = widget.collection.environments;
      _selectedEnvironmentIndex = _environments.length - 1;
      _filenameController.text = newEnvironment.fileName();
      _isEditingFilename = false;
    });

    context.read<EventBus>().fire(EventEnvironmentsChanged());

    // Update the vars controller
    _varsController.setVars(newEnvironment.vars);
  }

  Future<void> _onRenamed(String newName) async {
    final environment = _environments[_selectedEnvironmentIndex];

    setState(() {
      _isEditingFilename = false;
      environment.setFileName(newName);
      _filenameController.text = environment.fileName();
    });
  }

  Future<void> _onSave() async {
    final vars = _varsController.getVars();
    final environment = _environments[_selectedEnvironmentIndex];
    environment.vars = vars;

    CollectionRepo().save(widget.collection);

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _varsController.dispose();
    _filenameController.dispose();
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
            Container(height: 1, color: borderColor),
            Expanded(
              child:
                  _environments.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No environments found.', style: const TextStyle(color: lightTextColor, fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _createNewEnvironment();
                              },
                              style: commonButtonStyle,
                              child: const Text('New Environment'),
                            ),
                          ],
                        ),
                      )
                      : Row(
                        children: [
                          // Vertical Tab Bar
                          Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border(right: BorderSide(width: 1, color: borderColor)),
                            ),
                            child: Column(
                              children: [
                                ..._environments.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final environment = entry.value;
                                  final isSelected = index == _selectedEnvironmentIndex;

                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) {
                                      setState(() {
                                        _hoveredEnvironmentIndex = index;
                                      });
                                    },
                                    onExit: (_) {
                                      setState(() {
                                        _hoveredEnvironmentIndex = null;
                                      });
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectEnv(index);
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? lightBackgroundColor
                                                  : (_hoveredEnvironmentIndex == index
                                                      ? lightBackgroundColor
                                                      : Colors.transparent),
                                          border: Border(
                                            left: BorderSide(
                                              width: 2,
                                              color: isSelected ? highlightBorderColor : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          environment.fileName(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : lightTextColor,
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const Spacer(),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) {
                                    setState(() {
                                      _isHoveringNewButton = true;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      _isHoveringNewButton = false;
                                    });
                                  },
                                  child: GestureDetector(
                                    key: const Key('environments_modal_new_btn'),
                                    onTap: _createNewEnvironment,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _isHoveringNewButton ? lightBackgroundColor : Colors.transparent,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.add, color: lightTextColor, size: 16),
                                          const SizedBox(width: 8),
                                          Text('New', style: TextStyle(color: lightTextColor, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_isEditingFilename)
                                          SizedBox(
                                            width: 200,
                                            child: TextField(
                                              key: const Key('environments_modal_name_input'),
                                              controller: _filenameController,
                                              style: textFieldStyle,
                                              decoration: textFieldDecor,
                                              onSubmitted: _onRenamed,
                                              autofocus: true,
                                            ),
                                          )
                                        else
                                          Expanded(
                                            child: Text(
                                              _environments[_selectedEnvironmentIndex].fileName(),
                                              style: const TextStyle(
                                                color: lightTextColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              if (_isEditingFilename) {
                                                _isEditingFilename = false;
                                                _filenameController.text =
                                                    _environments[_selectedEnvironmentIndex].fileName();
                                              } else {
                                                _isEditingFilename = true;
                                                _filenameController.text =
                                                    _environments[_selectedEnvironmentIndex].fileName();
                                              }
                                            });
                                          },
                                          icon: Icon(
                                            _isEditingFilename ? Icons.close : Icons.edit,
                                            color: lightTextColor,
                                            size: 18,
                                          ),
                                          padding: EdgeInsets.only(right: 16),
                                          constraints: const BoxConstraints(),
                                          splashRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 16),
                                    child: Text(
                                      'Variables',
                                      style: const TextStyle(color: lightTextColor, fontSize: 14),
                                    ),
                                  ),
                                  Expanded(child: SingleChildScrollView(child: FormTable(controller: _varsController))),
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
