import 'package:flutter/material.dart';
import 'package:trayce/common/checkbox.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/widgets/code_editor/form_table_input.dart';
import 'package:trayce/editor/widgets/common/form_table_controller.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';

enum FormTableColumn { enabled, selected, delete, key, value, valueFile, secret, contentType }

class FormTable extends StatefulWidget {
  final FormTableControllerI controller;
  final List<FormTableColumn> columns;
  final List<FormTableColumn> readOnlyColumns;

  const FormTable({
    super.key,
    required this.controller,
    this.columns = const [
      FormTableColumn.enabled,
      FormTableColumn.key,
      FormTableColumn.value,
      FormTableColumn.secret,
      FormTableColumn.delete,
    ],
    this.readOnlyColumns = const [],
  });

  @override
  State<FormTable> createState() => _FormTableState();
}

class _FormTableState extends State<FormTable> {
  final List<Map<String, VoidCallback>> _focusListeners = [];

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  @override
  void didUpdateWidget(FormTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _cleanupFocusListeners();
      _setupFocusListeners();
    }
  }

  @override
  void dispose() {
    _cleanupFocusListeners();
    super.dispose();
  }

  void _setupFocusListeners() {
    _cleanupFocusListeners();

    for (int i = 0; i < widget.controller.rows().length; i++) {
      final rowFocusNodes = widget.controller.getRowFocusNodes(i);
      final listeners = <String, VoidCallback>{};

      rowFocusNodes.forEach((key, focusNode) {
        void listener() {
          if (mounted) {
            setState(() {});
          }
        }

        focusNode.addListener(listener);
        listeners[key] = listener;
      });

      _focusListeners.add(listeners);
    }
  }

  void _updateFocusListeners() {
    final currentRowCount = widget.controller.rows().length;
    final currentListenerCount = _focusListeners.length;

    if (currentRowCount != currentListenerCount) {
      _setupFocusListeners();
    }
  }

  void _cleanupFocusListeners() {
    for (final listeners in _focusListeners) {
      listeners.forEach((key, listener) {
        final rowFocusNodes = widget.controller.getRowFocusNodes(_focusListeners.indexOf(listeners));
        rowFocusNodes[key]?.removeListener(listener);
      });
    }
    _focusListeners.clear();
  }

  Widget _buildHeaderCell(String text) {
    final borderSide = BorderSide(color: borderColor, width: 1);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
        height: 30,
        alignment: Alignment.centerLeft,
        child: Text(text, style: TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateFocusListeners();
    final borderSide = BorderSide(color: borderColor, width: 1);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
      child: Column(
        children: [
          // Static header row
          Row(
            children: [
              if (widget.columns.contains(FormTableColumn.enabled))
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
                  // decoration: BoxDecoration(border: Border.all(color: const Color(0xFF474747), width: 0)),
                  child: Tooltip(
                    message: 'Enable/Disable',
                    child: const Icon(Icons.help_outline, size: 16, color: Color(0xFF666666)),
                  ),
                ),

              const SizedBox(width: 0),
              if (widget.columns.contains(FormTableColumn.key)) _buildHeaderCell('Key'),
              const SizedBox(width: 0),

              if (widget.columns.contains(FormTableColumn.value) || widget.columns.contains(FormTableColumn.valueFile))
                _buildHeaderCell('Value'),

              if (widget.columns.contains(FormTableColumn.contentType)) _buildHeaderCell('Content-Type'),

              if (widget.columns.contains(FormTableColumn.selected)) _buildHeaderCell('Selected'),

              if (widget.columns.contains(FormTableColumn.secret)) _buildHeaderCell('Secret'),

              if (widget.columns.contains(FormTableColumn.delete))
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide, right: borderSide)),
                  // decoration: BoxDecoration(border: Border.all(color: const Color(0xFF474747), width: 0)),
                  child: Tooltip(
                    message: 'Delete row',
                    child: const Icon(Icons.help_outline, size: 16, color: Color(0xFF666666)),
                  ),
                ),
            ],
          ),
          // Existing rows
          ...List.generate(widget.controller.rows().length, (index) {
            final row = widget.controller.rows()[index];
            final rowFocusNodes = widget.controller.getRowFocusNodes(index);
            return _buildRow(context, index, row, rowFocusNodes, borderSide);
          }),
        ],
      ),
    );
  }

  Border _getCellBorder(BorderSide borderSide, FocusNode? focusNode, int x, FormTableColumn column) {
    late BorderSide borderBottom;
    late BorderSide borderRight;

    final y = widget.columns.indexOf(column);
    final isFocused = focusNode != null && focusNode.hasFocus;

    if (isFocused) {
      borderSide = BorderSide(color: selectedMenuItemColor, width: 1);
    }

    if (isFocused) {
      borderBottom = BorderSide(color: selectedMenuItemColor, width: 1);
    } else if (x == widget.controller.rows().length - 1) {
      borderBottom = BorderSide(color: borderColor, width: 1);
    } else {
      borderBottom = BorderSide.none;
    }

    if (isFocused) {
      borderRight = BorderSide(color: selectedMenuItemColor, width: 1);
    } else if (y == widget.columns.length - 1) {
      borderRight = BorderSide(color: borderColor, width: 1);
    } else {
      borderRight = BorderSide.none;
    }

    return Border(top: borderSide, left: borderSide, bottom: borderBottom, right: borderRight);
  }

  Widget _buildRow(
    BuildContext context,
    int index,
    FormTableRow row,
    Map<String, FocusNode> rowFocusNodes,
    BorderSide borderSide,
  ) {
    return Row(
      children: [
        if (widget.columns.contains(FormTableColumn.enabled))
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(border: _getCellBorder(borderSide, null, index, FormTableColumn.enabled)),
            child: CommonCheckbox(
              value: row.checkboxState,
              onChanged: (bool? value) {
                FocusScope.of(context).requestFocus(widget.controller.focusManager().editorFocusNode);
                widget.controller.setCheckboxState(index, value ?? false);
              },
            ),
          ),
        const SizedBox(width: 0),
        if (widget.columns.contains(FormTableColumn.key))
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                border: _getCellBorder(borderSide, rowFocusNodes['key'], index, FormTableColumn.key),
              ),
              child: FormTableInput(
                key: Key('form_table_key_$index'),
                controller: row.keyController,
                focusNode: rowFocusNodes['key']!,
                readOnly: widget.readOnlyColumns.contains(FormTableColumn.key),
              ),
            ),
          ),
        const SizedBox(width: 0),
        if (widget.columns.contains(FormTableColumn.value))
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                border: _getCellBorder(borderSide, rowFocusNodes['value'], index, FormTableColumn.value),
              ),
              child: FormTableInput(
                key: Key('form_table_value_$index'),
                controller: row.valueController,
                focusNode: rowFocusNodes['value']!,
                readOnly: widget.readOnlyColumns.contains(FormTableColumn.value),
              ),
            ),
          ),
        if (widget.columns.contains(FormTableColumn.valueFile))
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              height: 30,
              decoration: BoxDecoration(border: _getCellBorder(borderSide, null, index, FormTableColumn.valueFile)),
              child: Center(
                child:
                    row.valueFile != null
                        ? Text(
                          row.valueFile!,
                          style: const TextStyle(color: Color(0xFF666666)),
                          overflow: TextOverflow.ellipsis,
                        )
                        : ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).requestFocus(widget.controller.focusManager().editorFocusNode);
                            widget.controller.uploadValueFile(index);
                          },
                          style: commonButtonStyle.copyWith(minimumSize: WidgetStateProperty.all(const Size(80, 36))),
                          child: const Text('Browse', style: TextStyle(color: Color(0xFF666666))),
                        ),
              ),
            ),
          ),
        const SizedBox(width: 0),
        if (widget.columns.contains(FormTableColumn.contentType))
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                border: _getCellBorder(borderSide, rowFocusNodes['contentType'], index, FormTableColumn.contentType),
              ),
              child: FormTableInput(
                key: Key('form_table_content_type_$index'),
                controller: row.contentTypeController,
                focusNode: rowFocusNodes['contentType']!,
                readOnly: widget.readOnlyColumns.contains(FormTableColumn.contentType),
              ),
            ),
          ),

        if (widget.columns.contains(FormTableColumn.selected))
          Expanded(
            child: SizedBox(
              height: 30,
              child: Container(
                height: 30,
                decoration: BoxDecoration(border: _getCellBorder(borderSide, null, index, FormTableColumn.selected)),
                child: Radio<int>(
                  value: index,
                  groupValue: widget.controller.selectedRowIndex(),
                  onChanged: (int? value) {
                    if (value != null) {
                      widget.controller.setSelectedRowIndex(value);
                    }
                    FocusScope.of(context).requestFocus(widget.controller.focusManager().editorFocusNode);
                  },
                  activeColor: const Color(0xFF4DB6AC),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) return lightTextColor;
                    return null;
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.values[1],
                ),
              ),
            ),
          ),

        if (widget.columns.contains(FormTableColumn.secret))
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(border: _getCellBorder(borderSide, null, index, FormTableColumn.secret)),
              child: CommonCheckbox(
                value: row.checkboxStateSecret,
                onChanged: (bool? value) {
                  FocusScope.of(context).requestFocus(widget.controller.focusManager().editorFocusNode);
                  widget.controller.setCheckboxStateSecret(index, value ?? false);
                },
              ),
            ),
          ),
        const SizedBox(width: 0),

        if (widget.columns.contains(FormTableColumn.delete))
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(border: _getCellBorder(borderSide, null, index, FormTableColumn.delete)),
            child: IconButton(
              key: Key('form_table_delete_row_$index'),
              // focusNode: focusNode,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFF666666),
                hoverColor: Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () {
                if (widget.controller.rows().length > 1) {
                  widget.controller.deleteRow(index);
                }
                FocusScope.of(context).requestFocus(widget.controller.focusManager().editorFocusNode);
              },
            ),
          ),
      ],
    );
  }
}
