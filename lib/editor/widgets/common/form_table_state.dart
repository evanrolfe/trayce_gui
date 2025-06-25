import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';

enum FormTableColumn { enabled, selected, delete, key, value, valueFile, contentType }

class FormTableStateManager {
  late List<FormTableRow> _rows;
  final void Function() onStateChanged;
  final VoidCallback? onModified;
  final Config config;
  int? selectedRowIndex; // Track which row is selected for radio buttons

  FormTableStateManager({
    required this.onStateChanged,
    List<Header>? initialRows,
    this.onModified,
    required this.config,
  }) {
    // TODO: This should somehow accept either params or multipart files
    if (initialRows != null) {
      _rows = _convertHeadersToRows(initialRows);
    } else {
      _rows = [];
    }

    _addNewRow();
  }

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

  void _clearOtherSelections(FormTableRow focusedRow, FocusNode focusedNode) {
    for (var row in _rows) {
      if (row != focusedRow) {
        // Clear selections in other rows
        row.keyController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
        row.valueController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
        row.contentTypeController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
      } else {
        // TODO: Refactor this and so it doesn't rely on so many if else ifs
        // Clear selection in the other editor of the same row
        if (focusedNode == row.valueFocusNode) {
          row.keyController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
          row.contentTypeController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
        } else if (focusedNode == row.keyFocusNode) {
          row.valueController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
          row.contentTypeController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
        } else if (focusedNode == row.contentTypeFocusNode) {
          row.keyController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
          row.valueController.selection = CodeLineSelection.collapsed(index: 0, offset: 0);
        }
      }
    }
  }

  List<Header> getHeaders() {
    return _rows.where((row) => !row.isEmpty()).map((row) {
      return Header(name: row.keyController.text, value: row.valueController.text, enabled: row.checkboxState);
    }).toList();
  }

  List<Param> getParams() {
    return _rows.where((row) => !row.isEmpty()).map((row) {
      return Param(
        name: row.keyController.text,
        value: row.valueController.text,
        type: ParamType.form,
        enabled: row.checkboxState,
      );
    }).toList();
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

      return FileBodyItem(filePath: row.valueFile ?? '', contentType: contentType, selected: index == selectedRowIndex);
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
            keyFocusNode: FocusNode(),
            valueFocusNode: FocusNode(),
            contentTypeFocusNode: FocusNode(),
            checkboxState: file.enabled,
            newRow: false,
          );

          row.keyFocusNode.addListener(() {
            if (row.keyFocusNode.hasFocus) {
              _clearOtherSelections(row, row.keyFocusNode);
            }
          });

          row.valueFocusNode.addListener(() {
            if (row.valueFocusNode.hasFocus) {
              _clearOtherSelections(row, row.valueFocusNode);
            }
          });

          row.contentTypeFocusNode.addListener(() {
            if (row.contentTypeFocusNode.hasFocus) {
              _clearOtherSelections(row, row.contentTypeFocusNode);
            }
          });

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
            keyFocusNode: FocusNode(),
            valueFocusNode: FocusNode(),
            contentTypeFocusNode: FocusNode(),
            newRow: false,
          );

          row.contentTypeFocusNode.addListener(() {
            if (row.contentTypeFocusNode.hasFocus) {
              _clearOtherSelections(row, row.contentTypeFocusNode);
            }
          });

          return row;
        }).toList();

    selectedRowIndex = files.indexWhere((file) => file.selected == true);

    _addNewRow();
  }

  List<FormTableRow> _convertHeadersToRows(List<Header> headers) {
    return headers.asMap().entries.map((entry) {
      final index = entry.key;
      final header = entry.value;

      final keyController = CodeLineEditingController();
      final valueController = CodeLineEditingController();
      final contentTypeController = CodeLineEditingController();

      keyController.text = header.name;
      valueController.text = header.value;
      contentTypeController.text = '';

      _setupControllerListener(keyController, index, true);
      _setupControllerListener(valueController, index, false);
      _setupControllerListener(contentTypeController, index, false);

      final row = FormTableRow(
        keyController: keyController,
        valueController: valueController,
        contentTypeController: contentTypeController,
        keyFocusNode: FocusNode(),
        valueFocusNode: FocusNode(),
        contentTypeFocusNode: FocusNode(),
        checkboxState: header.enabled,
        newRow: false,
      );

      row.keyFocusNode.addListener(() {
        if (row.keyFocusNode.hasFocus) {
          _clearOtherSelections(row, row.keyFocusNode);
        }
      });

      row.valueFocusNode.addListener(() {
        if (row.valueFocusNode.hasFocus) {
          _clearOtherSelections(row, row.valueFocusNode);
        }
      });

      row.contentTypeFocusNode.addListener(() {
        if (row.contentTypeFocusNode.hasFocus) {
          _clearOtherSelections(row, row.contentTypeFocusNode);
        }
      });

      return row;
    }).toList();
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
      keyFocusNode: FocusNode(),
      valueFocusNode: FocusNode(),
      contentTypeFocusNode: FocusNode(),
      newRow: true,
    );

    row.keyFocusNode.addListener(() {
      if (row.keyFocusNode.hasFocus) {
        _clearOtherSelections(row, row.keyFocusNode);
      }
    });

    row.valueFocusNode.addListener(() {
      if (row.valueFocusNode.hasFocus) {
        _clearOtherSelections(row, row.valueFocusNode);
      }
    });

    row.contentTypeFocusNode.addListener(() {
      if (row.contentTypeFocusNode.hasFocus) {
        _clearOtherSelections(row, row.contentTypeFocusNode);
      }
    });

    _rows.add(row);

    final index = _rows.length - 1;
    _setupControllerListener(row.keyController, index, true);
    _setupControllerListener(row.valueController, index, false);
    _setupControllerListener(row.contentTypeController, index, false);
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
    onModified?.call();
  }

  void handleTabPress(int row, bool isKey) {
    if (isKey) {
      _rows[row].valueFocusNode.requestFocus();
    } else {
      if (row < _rows.length - 1) {
        _rows[row + 1].keyFocusNode.requestFocus();
      } else {
        _rows[0].keyFocusNode.requestFocus();
      }
    }
  }

  void setCheckboxState(int index, bool value) {
    _rows[index].checkboxState = value;
    onStateChanged();
    onModified?.call();
  }

  void setSelectedRowIndex(int index) {
    selectedRowIndex = index;
    onStateChanged();
    onModified?.call();
  }

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
