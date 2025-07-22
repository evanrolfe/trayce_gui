import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/form_table_base_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

class FormVarsController implements FormTableControllerI {
  late FormTableBaseController _baseController;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;
  final EventBus eventBus;
  final FilePicker filePicker;

  FormVarsController({
    required this.onStateChanged,
    required List<Variable> initialRows,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
    required this.eventBus,
    required this.filePicker,
  }) : _focusManager = focusManager {
    setVars(initialRows);
  }

  @override
  List<FormTableRow> rows() => _baseController.rows;

  @override
  EditorFocusManager focusManager() => _focusManager;

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

  void setVars(List<Variable> vars) {
    final rows = _convertVarsToRows(vars);
    _baseController = FormTableBaseController(
      rows: rows,
      onStateChanged: onStateChanged,
      onModified: onModified,
      focusManager: _focusManager,
    );

    // Setup listeners for existing rows
    for (int i = 0; i < rows.length; i++) {
      _baseController.setupListenersForRow(rows[i], i);
    }

    _baseController.addNewRow();
    onStateChanged();
  }

  List<Variable> getVars() {
    return _baseController.rows.where((row) => !row.isEmpty()).map((row) {
      return Variable(
        name: row.keyController.text,
        value: row.valueController.text,
        enabled: row.checkboxState,
        secret: row.checkboxStateSecret,
      );
    }).toList();
  }

  List<FormTableRow> _convertVarsToRows(List<Variable> vars) {
    return vars.asMap().entries.map((entry) {
      final varr = entry.value;

      final keyController = CodeLineEditingController();
      final valueController = CodeLineEditingController();
      final contentTypeController = CodeLineEditingController();

      keyController.text = varr.name;
      valueController.text = varr.value ?? '';
      contentTypeController.text = '';

      final row = FormTableRow(
        keyController: keyController,
        valueController: valueController,
        contentTypeController: contentTypeController,
        checkboxState: varr.enabled,
        checkboxStateSecret: varr.secret,
        newRow: false,
      );
      _focusManager.createRowFocusNodes();

      return row;
    }).toList();
  }

  void clearAllSelections() {
    _baseController.clearAllSelections();
  }

  @override
  void deleteRow(int index) {
    _baseController.deleteRow(index);
  }

  @override
  void setCheckboxState(int index, bool value) {
    _baseController.rows[index].checkboxState = value;
    onStateChanged();
    onModified?.call();
  }

  @override
  void setCheckboxStateSecret(int index, bool value) {
    _baseController.rows[index].checkboxStateSecret = value;
    onStateChanged();
    onModified?.call();
  }

  @override
  void setSelectedRowIndex(int index) {
    _selectedRowIndex = index;
    onStateChanged();
    onModified?.call();
  }

  @override
  void uploadValueFile(int index) async {
    final path = await _getFilePath();
    if (path == null) return;

    if (index >= _baseController.rows.length) return;

    _baseController.rows[index].valueFile = path;

    if (index == _baseController.rows.length - 1) {
      _baseController.addNewRow();
    }

    onStateChanged();
    onModified?.call();
  }

  Future<String?> _getFilePath() async {
    late String? path;
    if (config.isTest) {
      path = './test/support/';
    } else {
      path = await filePicker.openFile();
    }
    return path;
  }

  @override
  void dispose() {
    _baseController.dispose();
  }
}
