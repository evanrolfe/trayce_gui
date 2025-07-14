import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/widgets/common/form_table_base_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

class FormMultipartController implements FormTableControllerI {
  late FormTableBaseController _baseController;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;
  final EventBus eventBus;

  FormMultipartController({
    required this.onStateChanged,
    required List<MultipartFile> initialRows,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
    required this.eventBus,
  }) : _focusManager = focusManager {
    final rows = _convertMultipartFilesToRows(initialRows);
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

    _baseController.addNewRow();
  }

  @override
  List<FormTableRow> rows() => _baseController.rows;

  @override
  EditorFocusManager focusManager() => _focusManager;

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

  List<MultipartFile> getMultipartFiles() {
    return _baseController.rows.where((row) => !row.isEmpty()).map((row) {
      final contentType = row.contentTypeController.text.isEmpty ? null : row.contentTypeController.text;

      return MultipartFile(
        name: row.keyController.text,
        value: row.valueFile ?? '',
        contentType: contentType,
        enabled: row.checkboxState,
      );
    }).toList();
  }

  void setMultipartFiles(List<MultipartFile> files) {
    final rows = _convertMultipartFilesToRows(files);
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

    onStateChanged();
  }

  List<FormTableRow> _convertMultipartFilesToRows(List<MultipartFile> multipartFiles) {
    return multipartFiles.asMap().entries.map((entry) {
      final file = entry.value;

      final keyController = CodeLineEditingController();
      final contentTypeController = CodeLineEditingController();

      keyController.text = file.name;
      contentTypeController.text = file.contentType ?? '';

      final row = FormTableRow(
        keyController: keyController,
        valueController: CodeLineEditingController(),
        contentTypeController: contentTypeController,
        valueFile: file.value,
        checkboxState: file.enabled,
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
