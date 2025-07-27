import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

/// Helper class that provides common functionality for form table controllers
/// Uses composition to avoid code duplication between FormHeadersController and FormVarsController
class QueryParamsFormBaseController {
  final List<FormTableRow> _rows;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final EditorFocusManager _focusManager;

  // Flag to enable/disable all listeners
  bool _listenersEnabled = true;

  QueryParamsFormBaseController({
    required List<FormTableRow> rows,
    required this.onStateChanged,
    this.onModified,
    required EditorFocusManager focusManager,
  }) : _rows = rows,
       _focusManager = focusManager;

  List<FormTableRow> get rows => _rows;

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

  void callOnModified() {
    if (!_listenersEnabled) return;
    onModified?.call();
  }

  void setupControllerListener(CodeLineEditingController controller, int index, bool isKey) {
    controller.addListener(() {
      if (!_listenersEnabled) return; // Early exit if disabled

      final previousValue = controller.preValue;
      final previousValueText2 = previousValue?.codeLines.asString(TextLineBreak.lf) ?? '';

      if (controller.text == '' && previousValueText2 == '') return;

      if (index >= _rows.length) return;
      final row = _rows[index];
      if (index == _rows.length - 1 && controller.text.isNotEmpty) {
        addNewRow();
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

      callOnModified();
    });
  }

  void setupListenersForRow(FormTableRow row, int index) {
    setupControllerListener(row.keyController, index, true);
    setupControllerListener(row.valueController, index, false);
    setupControllerListener(row.contentTypeController, index, false);
  }

  void addNewRow() {
    final row = FormTableRow(
      keyController: CodeLineEditingController(),
      valueController: CodeLineEditingController(),
      contentTypeController: CodeLineEditingController(),
      newRow: true,
    );

    _rows.add(row);

    final index = _rows.length - 1;
    setupListenersForRow(row, index);
    _focusManager.createRowFocusNodes();
    onStateChanged();
  }

  // There is a bug with the Re-Editor which prevents me from doing _rows.removeAt(index)
  // so instead i have to do this work around where we swap rows and delete the last one
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
    callOnModified();
  }

  void disableListeners() {
    _listenersEnabled = false;
  }

  void enableListeners() {
    _listenersEnabled = true;
  }

  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
  }
}
