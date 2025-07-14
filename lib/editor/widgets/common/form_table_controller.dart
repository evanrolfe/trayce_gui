import 'package:event_bus/event_bus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

abstract interface class FormTableControllerI {
  List<FormTableRow> rows();
  EditorFocusManager focusManager();
  int selectedRowIndex();
  void setCheckboxState(int index, bool value);
  void setCheckboxStateSecret(int index, bool value);
  void setSelectedRowIndex(int value);
  void deleteRow(int index);
  void uploadValueFile(int index);
  void dispose();
}

class FormTableController implements FormTableControllerI {
  List<FormTableRow> _rows = [];
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? _selectedRowIndex; // Track which row is selected for radio buttons
  final EditorFocusManager _focusManager;
  final EventBus eventBus;

  FormTableController({
    required this.onStateChanged,
    this.onModified,
    required this.config,
    required EditorFocusManager focusManager,
    required this.eventBus,
  }) : _focusManager = focusManager {
    _addNewRow();
  }

  @override
  List<FormTableRow> rows() => _rows;

  @override
  EditorFocusManager focusManager() => _focusManager;

  @override
  int selectedRowIndex() => _selectedRowIndex ?? -1;

  void clearAllSelections() {
    for (var row in _rows) {
      row.keyController.selection = CodeLineSelection.collapsed(
        index: row.keyController.selection.baseIndex,
        offset: row.keyController.selection.baseOffset,
      );
      row.valueController.selection = CodeLineSelection.collapsed(
        index: row.valueController.selection.baseIndex,
        offset: row.valueController.selection.baseOffset,
      );
      row.contentTypeController.selection = CodeLineSelection.collapsed(
        index: row.contentTypeController.selection.baseIndex,
        offset: row.contentTypeController.selection.baseOffset,
      );
    }
  }

  List<MultipartFile> getMultipartFiles() {
    return _rows.where((row) => !row.isEmpty()).map((row) {
      final contentType = row.contentTypeController.text.isEmpty ? null : row.contentTypeController.text;

      return MultipartFile(
        name: row.keyController.text,
        value: row.valueFile ?? '',
        contentType: contentType,
        enabled: row.checkboxState,
      );
    }).toList();
  }

  List<FileBodyItem> getFiles() {
    return _rows.where((row) => !row.isEmpty()).toList().asMap().entries.map((entry) {
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

  void setMultipartFiles(List<MultipartFile> files) {
    _rows =
        files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;

          final keyController = CodeLineEditingController();
          final contentTypeController = CodeLineEditingController();

          keyController.text = file.name;
          contentTypeController.text = file.contentType ?? '';

          _setupControllerListener(keyController, index, true);
          _setupControllerListener(contentTypeController, index, false);

          final row = FormTableRow(
            keyController: keyController,
            valueController: CodeLineEditingController(),
            contentTypeController: contentTypeController,
            valueFile: file.value,
            checkboxState: file.enabled,
            newRow: false,
          );

          return row;
        }).toList();

    _addNewRow();
  }

  void setFiles(List<FileBodyItem> files) {
    _rows =
        files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;

          final contentTypeController = CodeLineEditingController();

          contentTypeController.text = file.contentType ?? '';

          _setupControllerListener(contentTypeController, index, false);

          final row = FormTableRow(
            keyController: CodeLineEditingController(),
            valueController: CodeLineEditingController(),
            contentTypeController: contentTypeController,
            valueFile: file.filePath,
            newRow: false,
          );

          return row;
        }).toList();

    _selectedRowIndex = files.indexWhere((file) => file.selected == true);

    _addNewRow();
  }

  void _setupControllerListener(CodeLineEditingController controller, int index, bool isKey) {
    controller.addListener(() {
      if (index >= _rows.length) return;
      final row = _rows[index];
      if (index == _rows.length - 1 && controller.text.isNotEmpty) {
        _addNewRow();
      }

      final currentKeyText = row.keyController.text;
      final currentValueText = row.valueController.text;
      final previousKeyText = row.previousKeyText;
      final previousValueText = row.previousValueText;
      final currentContentTypeText = row.contentTypeController.text;
      final previousContentTypeText = row.previousContentTypeText;

      final hasTextChanged =
          currentKeyText != previousKeyText ||
          currentValueText != previousValueText ||
          currentContentTypeText != previousContentTypeText;

      if (hasTextChanged &&
          previousKeyText.isEmpty &&
          previousValueText.isEmpty &&
          previousContentTypeText.isEmpty &&
          !row.checkboxState &&
          row.newRow) {
        row.checkboxState = true;
        // Schedule state change for next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onStateChanged();
        });
      }

      row.previousKeyText = currentKeyText;
      row.previousValueText = currentValueText;
      row.previousContentTypeText = currentContentTypeText;

      onModified?.call();
    });
  }

  void _addNewRow() {
    final row = FormTableRow(
      keyController: CodeLineEditingController(),
      valueController: CodeLineEditingController(),
      contentTypeController: CodeLineEditingController(),
      newRow: true,
    );

    _rows.add(row);

    final index = _rows.length - 1;
    _setupControllerListener(row.keyController, index, true);
    _setupControllerListener(row.valueController, index, false);
    _setupControllerListener(row.contentTypeController, index, false);
    _focusManager.createRowFocusNodes();
    onStateChanged();
  }

  // There is a bug with the Re-Editor which prevents me from doing _rows.removeAt(index)
  // so instead i have to do this work around where we swap rows and delete the last one
  @override
  void deleteRow(int index) {
    if (_rows.length <= 1) return;
    if (index >= _rows.length - 1) return;

    for (int i = index; i < _rows.length - 1; i++) {
      final row1 = _rows[i];
      final row2 = _rows[i + 1];

      if (row2.isEmpty()) break;

      row1.swapWith(row2);
    }

    final removed = _rows.removeLast();
    removed.dispose();

    _rows.last.setEmpty();
    onStateChanged();
    onModified?.call();
  }

  @override
  void setCheckboxState(int index, bool value) {
    _rows[index].checkboxState = value;
    onStateChanged();
    onModified?.call();
  }

  @override
  void setCheckboxStateSecret(int index, bool value) {
    _rows[index].checkboxStateSecret = value;
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

    if (index >= _rows.length) return;
    final row = _rows[index];

    _rows[index].valueFile = path;

    if (index == _rows.length - 1) {
      _addNewRow();
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

  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
  }
}
