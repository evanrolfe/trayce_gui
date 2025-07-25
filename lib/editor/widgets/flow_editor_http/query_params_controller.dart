import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/query_params_form_base_controller.dart';

class QueryParamsController implements FormTableControllerI {
  late QueryParamsFormBaseController _baseController;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;
  final EventBus eventBus;
  final FilePickerI filePicker;
  final CodeLineEditingController urlController;

  QueryParamsController({
    required this.onStateChanged,
    required List<Param> initialRows,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
    required this.eventBus,
    required this.filePicker,
    required this.urlController,
  }) : _focusManager = focusManager {
    final rows = _convertParamsToRows(initialRows);
    _baseController = QueryParamsFormBaseController(
      rows: rows,
      onStateChanged: onStateChanged,
      onModified: onModified,
      focusManager: focusManager,
    );

    // Setup listeners for existing rows
    for (int i = 0; i < rows.length; i++) {
      _baseController.setupListenersForRow(rows[i], i);
    }

    _baseController.addNewRow();
  }

  @override
  List<FormTableRow> rows() => _baseController.rows;

  @override
  EditorFocusManager focusManager() => _focusManager;

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

  List<Param> getParams() {
    return _baseController.rows.where((row) => !row.isEmpty()).map((row) {
      return Param(
        name: row.keyController.text,
        value: row.valueController.text,
        enabled: row.checkboxState,
        type: ParamType.form,
      );
    }).toList();
  }

  // This should merge params so it preserves disabled rows, but it doesn't work properly
  // So for the meantime I am not allowing disabling of query params
  void mergeParams(List<Param> params) {
    _baseController.disableListeners();
    if (params.length < _baseController.rows.length) {
      for (int i = params.length; i < _baseController.rows.length; i++) {
        _baseController.deleteRow(i);
      }
    }

    // params.length+1 because we alway have an empty row last
    if (params.length + 1 > _baseController.rows.length) {
      for (int i = _baseController.rows.length; i < params.length + 1; i++) {
        _baseController.addNewRow();
      }
    }

    for (int i = 0; i < params.length; i++) {
      final param = params[i];
      final row = _baseController.rows[i];
      row.keyController.text = param.name;
      row.valueController.text = param.value;
    }

    _baseController.enableListeners();
  }

  List<FormTableRow> _convertParamsToRows(List<Param> params) {
    return params.asMap().entries.map((entry) {
      final param = entry.value;

      final keyController = CodeLineEditingController();
      final valueController = CodeLineEditingController();
      final contentTypeController = CodeLineEditingController();

      keyController.text = param.name;
      valueController.text = param.value;
      contentTypeController.text = '';

      final row = FormTableRow(
        keyController: keyController,
        valueController: valueController,
        contentTypeController: contentTypeController,
        checkboxState: param.enabled,
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
