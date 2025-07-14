import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/widgets/common/form_table_base_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

class FormFilesController implements FormTableControllerI {
  late FormTableBaseController _baseController;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;
  final EventBus eventBus;

  FormFilesController({
    required this.onStateChanged,
    required List<FileBodyItem> initialRows,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
    required this.eventBus,
  }) : _focusManager = focusManager {
    final rows = _convertFilesToRows(initialRows);
    _baseController = FormTableBaseController(
      rows: rows,
      onStateChanged: onStateChanged,
      onModified: onModified,
      focusManager: focusManager,
    );

    // Setup listeners for existing rows
    for (int i = 0; i < rows.length; i++) {
      _baseController.setupListenersForRow(rows[i], i);
    }

    _selectedRowIndex = initialRows.indexWhere((file) => file.selected == true);

    _baseController.addNewRow();
  }

  @override
  List<FormTableRow> rows() => _baseController.rows;

  @override
  EditorFocusManager focusManager() => _focusManager;

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

  List<FileBodyItem> getFiles() {
    return _baseController.rows.where((row) => !row.isEmpty()).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      final contentType = row.contentTypeController.text.isEmpty ? null : row.contentTypeController.text;

      return FileBodyItem(
        filePath: row.valueFile ?? '',
        contentType: contentType,
        selected: index == _selectedRowIndex,
      );
    }).toList();
  }

  void setFiles(List<FileBodyItem> files) {
    final rows = _convertFilesToRows(files);
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

    _selectedRowIndex = files.indexWhere((file) => file.selected == true);

    onStateChanged();
  }

  List<FormTableRow> _convertFilesToRows(List<FileBodyItem> files) {
    return files.asMap().entries.map((entry) {
      final file = entry.value;

      final contentTypeController = CodeLineEditingController();

      contentTypeController.text = file.contentType ?? '';

      final row = FormTableRow(
        keyController: CodeLineEditingController(),
        valueController: CodeLineEditingController(),
        contentTypeController: contentTypeController,
        valueFile: file.filePath,
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
    final row = _baseController.rows[index];

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
      final file = await openFile();
      path = file?.path;
    }

    return path;
  }

  @override
  void dispose() {
    _baseController.dispose();
  }
}
