import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/path_params_form_base_controller.dart';

class PathParamsController implements FormTableControllerI {
  late PathParamsFormBaseController _baseController;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;

  PathParamsController({
    required this.onStateChanged,
    required List<Param> initialRows,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
  }) : _focusManager = focusManager {
    final rows = _convertParamsToRows(initialRows);
    _baseController = PathParamsFormBaseController(
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
  Map<String, FocusNode> getRowFocusNodes(int index) => _focusManager.getPathParamsRowFocusNodes(index);

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

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
      _focusManager.createRowFocusNodesForPathParams();

      return row;
    }).toList();
  }

  List<Param> getParams() {
    return _baseController.rows
        .where((row) => !(row.keyController.text.isEmpty && row.valueController.text.isEmpty))
        .map((row) {
          return Param(
            name: row.keyController.text,
            value: row.valueController.text,
            enabled: true,
            type: ParamType.path,
          );
        })
        .toList();
  }

  void setParams(List<Param> params) {
    for (int i = 0; i < params.length; i++) {
      final param = params[i];
      final row = _baseController.rows[i];
      row.keyController.text = param.name;
    }
    // final rows = _convertParamsToRows(params);
    // _baseController = PathParamsFormBaseController(
    //   rows: rows,
    //   onStateChanged: onStateChanged,
    //   onModified: onModified,
    //   focusManager: _focusManager,
    // );

    // // Setup listeners for existing rows
    // for (int i = 0; i < rows.length; i++) {
    //   _baseController.setupListenersForRow(rows[i], i);
    // }

    // _baseController.addNewRow();
    onStateChanged();
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
  void uploadValueFile(int index) async {}

  @override
  void dispose() {
    _baseController.dispose();
  }
}
