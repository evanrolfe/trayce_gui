import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';

class HeadersTable extends StatelessWidget {
  final HeadersStateManager stateManager;

  const HeadersTable({super.key, required this.stateManager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
      child: Column(
        children: List.generate(stateManager.rows.length, (index) {
          final row = stateManager.rows[index];
          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF474747), width: 1)),
                child: Checkbox(
                  value: row.checkboxState,
                  onChanged: (bool? value) {
                    stateManager.setCheckboxState(index, value ?? false);
                  },
                  side: BorderSide.none,
                  activeColor: const Color(0xFF4DB6AC),
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: SingleLineCodeEditor(
                    controller: row.keyController,
                    onTabPressed: () => stateManager.handleTabPress(index, true),
                    focusNode: row.keyFocusNode,
                  ),
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: SingleLineCodeEditor(
                    controller: row.valueController,
                    onTabPressed: () => stateManager.handleTabPress(index, false),
                    focusNode: row.valueFocusNode,
                  ),
                ),
              ),
              const SizedBox(width: 0),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF474747), width: 1)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    if (stateManager.rows.length > 1) {
                      stateManager.deleteRow(index);
                    }
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class HeadersStateManager {
  late final List<HeaderRow> _rows;
  final void Function() onStateChanged;

  HeadersStateManager({required this.onStateChanged, List<Header>? initialRows}) {
    if (initialRows != null) {
      _rows = _convertHeadersToRows(initialRows);
    } else {
      _rows = [];
    }

    _addNewRow();
  }

  List<HeaderRow> get rows => _rows;

  List<Header> getHeaders() {
    return _rows.where((row) => !row.isEmpty()).map((row) {
      return Header(name: row.keyController.text, value: row.valueController.text, enabled: row.checkboxState);
    }).toList();
  }

  List<HeaderRow> _convertHeadersToRows(List<Header> headers) {
    return headers.map((header) {
      final keyController = CodeLineEditingController();
      final valueController = CodeLineEditingController();

      keyController.text = header.name;
      valueController.text = header.value;

      return HeaderRow(
        keyController: keyController,
        valueController: valueController,
        keyFocusNode: FocusNode(),
        valueFocusNode: FocusNode(),
        checkboxState: header.enabled,
      );
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

      final hasTextChanged = currentKeyText != previousKeyText || currentValueText != previousValueText;

      if (hasTextChanged && previousKeyText.isEmpty && previousValueText.isEmpty && !row.checkboxState) {
        row.checkboxState = true;
        onStateChanged();
      }

      if (isKey) {
        row.previousKeyText = currentKeyText;
      } else {
        row.previousValueText = currentValueText;
      }
    });
  }

  void _addNewRow() {
    final row = HeaderRow(
      keyController: CodeLineEditingController(),
      valueController: CodeLineEditingController(),
      keyFocusNode: FocusNode(),
      valueFocusNode: FocusNode(),
    );
    _rows.add(row);

    final index = _rows.length - 1;
    _setupControllerListener(row.keyController, index, true);
    _setupControllerListener(row.valueController, index, false);
    onStateChanged();
  }

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
  }

  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
  }
}

class HeaderRow {
  final CodeLineEditingController keyController;
  final CodeLineEditingController valueController;
  final FocusNode keyFocusNode;
  final FocusNode valueFocusNode;
  bool checkboxState;
  String previousKeyText;
  String previousValueText;

  HeaderRow({
    required this.keyController,
    required this.valueController,
    required this.keyFocusNode,
    required this.valueFocusNode,
    this.checkboxState = false,
    this.previousKeyText = '',
    this.previousValueText = '',
  });

  void dispose() {
    keyController.dispose();
    valueController.dispose();
    keyFocusNode.dispose();
    valueFocusNode.dispose();
  }

  void swapWith(HeaderRow otherRow) {
    // Swap checkboxState
    final tempCheckboxState = checkboxState;
    checkboxState = otherRow.checkboxState;
    otherRow.checkboxState = tempCheckboxState;

    // Swap previousKeyText
    final tempPreviousKeyText = previousKeyText;
    previousKeyText = otherRow.previousKeyText;
    otherRow.previousKeyText = tempPreviousKeyText;

    // Swap previousValueText
    final tempPreviousValueText = previousValueText;
    previousValueText = otherRow.previousValueText;
    otherRow.previousValueText = tempPreviousValueText;

    // Swap keyController.text
    final tempKeyText = keyController.text;
    keyController.text = otherRow.keyController.text;
    otherRow.keyController.text = tempKeyText;

    // Swap valueController.text
    final tempValueText = valueController.text;
    valueController.text = otherRow.valueController.text;
    otherRow.valueController.text = tempValueText;
  }

  bool isEmpty() {
    return keyController.text.isEmpty && valueController.text.isEmpty && !checkboxState;
  }

  void setEmpty() {
    keyController.text = '';
    valueController.text = '';
    checkboxState = false;
    previousKeyText = '';
    previousValueText = '';
  }
}
