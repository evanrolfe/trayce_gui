import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';

Future<void> showEnvironmentsModal(BuildContext context, Collection collection, {String? collectionPath}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => EnvironmentsModal(collection: collection, collectionPath: collectionPath),
  );
}

class EnvironmentsModal extends StatefulWidget {
  final Collection collection;
  final String? collectionPath;

  const EnvironmentsModal({super.key, required this.collection, this.collectionPath});

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
    if (_environments.isEmpty) return;
    initialVars = _environments[_selectedEnvironmentIndex].vars;

    _varsController = FormVarsController(
      onStateChanged: () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {});
          });
        }
      },
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
    // Get collection directory path
    if (widget.collectionPath == null) {
      print('Collection path is required to create a new environment');
      return;
    }

    // Create environments directory if it doesn't exist
    final environmentsDir = Directory(path.join(widget.collectionPath!, 'environments'));
    if (!environmentsDir.existsSync()) {
      environmentsDir.createSync(recursive: true);
    }

    // Create a new environment file
    final envFileName = 'untitled.bru';
    final envFile = File(path.join(environmentsDir.path, envFileName));

    // Create a new environment with empty vars
    final newEnvironment = Environment(vars: [], file: envFile);

    // Save the environment file
    newEnvironment.save();

    // Add to the collection's environments list
    widget.collection.environments.add(newEnvironment);

    // Update the local environments list
    setState(() {
      _environments = widget.collection.environments;
      _selectedEnvironmentIndex = _environments.length - 1;
      _filenameController.text = newEnvironment.fileName();
      _isEditingFilename = false;
    });

    // Update the vars controller
    _varsController.setVars(newEnvironment.vars);
  }

  Future<void> _onSave() async {
    final vars = _varsController.getVars();
    final environment = _environments[_selectedEnvironmentIndex];
    environment.vars = vars;
    environment.save();

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
                              children:
                                  _environments.asMap().entries.map((entry) {
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
                                              controller: _filenameController,
                                              style: textFieldStyle,
                                              decoration: textFieldDecor,
                                              onSubmitted: (value) {
                                                setState(() {
                                                  _isEditingFilename = false;
                                                  // TODO: Update the environment filename
                                                });
                                              },
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
