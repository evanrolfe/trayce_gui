import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';

class HeadersTable extends StatefulWidget {
  const HeadersTable({super.key});

  @override
  State<HeadersTable> createState() => _HeadersTableState();
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

class _HeadersTableState extends State<HeadersTable> {
  final List<HeaderRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _addNewRow(); // Initialize first row
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
        setState(() {
          row.checkboxState = true;
        });
      }

      if (isKey) {
        row.previousKeyText = currentKeyText;
      } else {
        row.previousValueText = currentValueText;
      }
    });
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
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
    });
  }

  void _handleTabPress(int row, bool isKey) {
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

  // Hack required here, I cannot do _rows.removeAt(i) (unless its the last row), because this exception will be thrown:
  // The following assertion was thrown while dispatching notifications for
  // _CodeLineEditingControllerImpl:
  // setState() or markNeedsBuild() called during build.
  // This HeadersTable widget cannot be marked as needing to build because the framework is already in
  // the process of building widgets. A widget can be marked as needing to be built during the build
  // phase only if one of its ancestors is currently building. This exception is allowed because the
  // framework builds parent widgets before children, which means a dirty descendant will always be
  // built. Otherwise, the framework might not visit this widget during this build phase.
  // The widget on which setState() or markNeedsBuild() was called was:
  //   HeadersTable
  // The widget which was currently being built when the offending call was made was:
  //   _ActionsScope
  void _deleteRow(int index) {
    setState(() {
      if (_rows.length <= 1) return; // Don't delete if only one row

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
      child: Column(
        children: List.generate(_rows.length, (index) {
          final row = _rows[index];
          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF474747), width: 1)),
                child: Checkbox(
                  value: row.checkboxState,
                  onChanged: (bool? value) {
                    setState(() {
                      row.checkboxState = value ?? false;
                    });
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
                    onTabPressed: () => _handleTabPress(index, true),
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
                    onTabPressed: () => _handleTabPress(index, false),
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
                    if (_rows.length > 1) {
                      _deleteRow(index);
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
