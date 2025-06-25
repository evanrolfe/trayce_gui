import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/common/form_table_state.dart';

class FormTable extends StatelessWidget {
  final FormTableStateManager stateManager;
  final VoidCallback? onSavePressed;
  final List<FormTableColumn> columns;
  final FocusNode focusNode;

  const FormTable({
    super.key,
    required this.stateManager,
    this.onSavePressed,
    required this.focusNode,
    this.columns = const [FormTableColumn.enabled, FormTableColumn.key, FormTableColumn.value, FormTableColumn.delete],
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: borderColor, width: 1);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
      child: Column(
        children: [
          // Static header row
          Row(
            children: [
              if (columns.contains(FormTableColumn.enabled))
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
              if (columns.contains(FormTableColumn.key))
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
                    height: 30,
                    alignment: Alignment.centerLeft,
                    child: const Text('Key', style: TextStyle(color: Color(0xFF666666))),
                  ),
                ),
              const SizedBox(width: 0),

              if (columns.contains(FormTableColumn.value) || columns.contains(FormTableColumn.valueFile))
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
                    height: 30,
                    alignment: Alignment.centerLeft,
                    child: const Text('Value', style: TextStyle(color: Color(0xFF666666))),
                  ),
                ),

              if (columns.contains(FormTableColumn.contentType))
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
                    height: 30,
                    alignment: Alignment.centerLeft,
                    child: const Text('Content-Type', style: TextStyle(color: Color(0xFF666666))),
                  ),
                ),

              if (columns.contains(FormTableColumn.selected))
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide)),
                    height: 30,
                    alignment: Alignment.centerLeft,
                    child: const Text('Selected', style: TextStyle(color: Color(0xFF666666))),
                  ),
                ),

              if (columns.contains(FormTableColumn.delete))
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
          ...List.generate(stateManager.rows.length, (index) {
            final row = stateManager.rows[index];
            return _buildRow(context, index, row, borderSide);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index, FormTableRow row, BorderSide borderSide) {
    late BorderSide borderBottom;
    if (index == stateManager.rows.length - 1) {
      borderBottom = BorderSide(color: borderColor, width: 1);
    } else {
      borderBottom = BorderSide.none;
    }

    return Row(
      children: [
        if (columns.contains(FormTableColumn.enabled))
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide, bottom: borderBottom)),
            child: Checkbox(
              value: row.checkboxState,
              onChanged: (bool? value) {
                FocusScope.of(context).requestFocus(focusNode);
                stateManager.setCheckboxState(index, value ?? false);
              },
              side: BorderSide.none,
              activeColor: const Color(0xFF4DB6AC),
            ),
          ),
        const SizedBox(width: 0),
        if (columns.contains(FormTableColumn.key))
          Expanded(
            child: SizedBox(
              height: 30,
              child: SingleLineCodeEditor(
                key: Key('form_table_key_$index'),
                border: Border(top: borderSide, left: borderSide, bottom: borderBottom),
                controller: row.keyController,
                onTabPressed: () => stateManager.handleTabPress(index, true),
                onSavePressed: onSavePressed,
                focusNode: row.keyFocusNode,
                onFocusChange: () {
                  context.read<EventBus>().fire(EditorSelectionChanged(row.keyController));
                },
              ),
            ),
          ),
        const SizedBox(width: 0),
        if (columns.contains(FormTableColumn.value))
          Expanded(
            child: SizedBox(
              height: 30,
              child: SingleLineCodeEditor(
                key: Key('form_table_value_$index'),
                border: Border(top: borderSide, left: borderSide, bottom: borderBottom),
                controller: row.valueController,
                onTabPressed: () => stateManager.handleTabPress(index, false),
                onSavePressed: onSavePressed,
                focusNode: row.valueFocusNode,
                onFocusChange: () {
                  context.read<EventBus>().fire(EditorSelectionChanged(row.valueController));
                },
              ),
            ),
          ),
        if (columns.contains(FormTableColumn.valueFile))
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              height: 30,
              decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide, bottom: borderBottom)),
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
                            FocusScope.of(context).requestFocus(focusNode);
                            stateManager.uploadValueFile(index);
                          },
                          style: commonButtonStyle.copyWith(minimumSize: WidgetStateProperty.all(const Size(80, 36))),
                          child: const Text('Browse', style: TextStyle(color: Color(0xFF666666))),
                        ),
              ),
            ),
          ),
        const SizedBox(width: 0),
        if (columns.contains(FormTableColumn.contentType))
          Expanded(
            child: SizedBox(
              height: 30,
              child: SingleLineCodeEditor(
                key: Key('form_table_content_type_$index'),
                border: Border(top: borderSide, left: borderSide, bottom: borderBottom),
                controller: row.contentTypeController,
                onTabPressed: () => stateManager.handleTabPress(index, false),
                onSavePressed: onSavePressed,
                focusNode: row.contentTypeFocusNode,
                onFocusChange: () {
                  context.read<EventBus>().fire(EditorSelectionChanged(row.valueController));
                },
              ),
            ),
          ),

        if (columns.contains(FormTableColumn.selected))
          Expanded(
            child: SizedBox(
              height: 30,
              child: Container(
                height: 30,
                decoration: BoxDecoration(border: Border(top: borderSide, left: borderSide, bottom: borderBottom)),
                child: Radio<int>(
                  value: index,
                  groupValue: stateManager.selectedRowIndex,
                  onChanged: (int? value) {
                    if (value != null) {
                      stateManager.setSelectedRowIndex(value);
                    }
                    FocusScope.of(context).requestFocus(focusNode);
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

        if (columns.contains(FormTableColumn.delete))
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              border: Border(top: borderSide, left: borderSide, right: borderSide, bottom: borderBottom),
            ),
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
                if (stateManager.rows.length > 1) {
                  stateManager.deleteRow(index);
                }
                FocusScope.of(context).requestFocus(focusNode);
              },
            ),
          ),
      ],
    );
  }
}
