import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CellBuilder<T> = String Function(T row);
typedef CellDecorationBuilder<T> = BoxDecoration? Function(T row, String text);
typedef RowKeyGetter<T> = Object? Function(T row);

abstract class Identifiable {
  int getTableKey();
}

class SelectableTableColumn<T> {
  final String title;
  final CellBuilder<T> cellBuilder;
  final CellDecorationBuilder<T>? cellDecorationBuilder;
  final TextAlign cellTextAlign;
  final double? cellTextWidth;

  SelectableTableColumn({
    required this.title,
    required this.cellBuilder,
    this.cellDecorationBuilder,
    this.cellTextAlign = TextAlign.left,
    this.cellTextWidth,
  });
}

class SelectableTable<T extends Identifiable> extends StatefulWidget {
  final ScrollController controller;
  final List<double> columnWidths;
  final Function(int, double) onColumnResize;
  final List<SelectableTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T?) onRowSelected;
  final double rowHeight;
  final double headerHeight;
  final FocusNode? focusNode;

  const SelectableTable({
    super.key,
    required this.controller,
    required this.columnWidths,
    required this.onColumnResize,
    required this.columns,
    required this.rows,
    required this.onRowSelected,
    required this.rowHeight,
    required this.headerHeight,
    this.focusNode,
  });

  @override
  State<SelectableTable<T>> createState() => _SelectableTableState<T>();
}

class _SelectableTableState<T extends Identifiable> extends State<SelectableTable<T>> {
  T? selectedRow;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  int getSelectedRowIndex() {
    if (selectedRow == null) return -1;
    return widget.rows.indexWhere((row) => row.getTableKey() == selectedRow!.getTableKey());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row
        Container(
          height: widget.headerHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF333333),
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return Row(
                children: List.generate(widget.columns.length, (colIndex) {
                  return SizedBox(
                    width: totalWidth * widget.columnWidths[colIndex],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.columns[colIndex].title,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFD4D4D4)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        // Table Body
        Expanded(
          child: Focus(
            focusNode: _focusNode,
            // autofocus: true,
            onKeyEvent: (node, event) {
              // Handle Arrow Up
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (selectedRow == null) {
                  return KeyEventResult.handled;
                }

                final nextIndex = getSelectedRowIndex() - 1;
                if (nextIndex < 0) {
                  return KeyEventResult.handled;
                }
                final nextRow = widget.rows[nextIndex];
                setState(() {
                  selectedRow = nextRow;
                  widget.onRowSelected(nextRow);
                });
                return KeyEventResult.handled;
              }
              // Handle Arrow Down
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (selectedRow == null) return KeyEventResult.handled;
                final nextIndex = getSelectedRowIndex() + 1;
                if (nextIndex > widget.rows.length - 1) return KeyEventResult.handled;
                final nextRow = widget.rows[nextIndex];
                setState(() {
                  selectedRow = nextRow;
                  widget.onRowSelected(nextRow);
                });
                return KeyEventResult.handled;
              }
              return KeyEventResult.handled;
            },
            child: Scrollbar(
              thumbVisibility: true,
              controller: widget.controller,
              thickness: 8,
              radius: const Radius.circular(4),
              child: ListView.builder(
                controller: widget.controller,
                itemCount: widget.rows.length,
                cacheExtent: 1000,
                itemExtent: widget.rowHeight,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                itemBuilder: (context, index) {
                  final row = widget.rows[index];
                  bool isHovered = false;
                  return StatefulBuilder(
                    builder:
                        (context, setState) => MouseRegion(
                          onEnter: (_) => setState(() => isHovered = true),
                          onExit: (_) => setState(() => isHovered = false),
                          child: GestureDetector(
                            onTap: () {
                              this.setState(() {
                                selectedRow = row;
                                widget.onRowSelected(row);
                              });
                              FocusScope.of(context).requestFocus(_focusNode);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: const Border(bottom: BorderSide(color: Colors.black)),
                                color:
                                    selectedRow != null && selectedRow!.getTableKey() == row.getTableKey()
                                        ? const Color(0xFF4DB6AC).withAlpha(77)
                                        : isHovered
                                        ? const Color(0xFF2D2D2D).withAlpha(77)
                                        : null,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final totalWidth = constraints.maxWidth;
                                  return Stack(
                                    children: [
                                      Row(
                                        children: List.generate(widget.columns.length, (colIndex) {
                                          final col = widget.columns[colIndex];
                                          final text = col.cellBuilder(row);
                                          final decoration = col.cellDecorationBuilder?.call(row, text);
                                          final width = totalWidth * widget.columnWidths[colIndex];
                                          if (col.cellTextWidth != null && col.cellDecorationBuilder != null) {
                                            // Special case for decorated cell with fixed width
                                            return SizedBox(
                                              width: width,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: IntrinsicWidth(
                                                  child: Container(
                                                    width: col.cellTextWidth,
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                                    decoration: decoration,
                                                    child: Text(
                                                      text,
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFFD4D4D4)),
                                                      textAlign: col.cellTextAlign,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return SizedBox(
                                            width: width,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                              child: Text(
                                                text,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFFD4D4D4)),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: col.cellTextAlign,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      ...List.generate(widget.columns.length - 1, (i) {
                                        double leftOffset =
                                            totalWidth * widget.columnWidths.take(i + 1).reduce((a, b) => a + b);
                                        return _buildDivider(i, totalWidth, leftOffset);
                                      }),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(int index, double totalWidth, double leftOffset) {
    return Positioned(
      left: leftOffset - 1.5,
      top: 0,
      bottom: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          onPanUpdate: (details) {
            double newLeftWidth = widget.columnWidths[index] * totalWidth + details.delta.dx;
            double newRightWidth = widget.columnWidths[index + 1] * totalWidth - details.delta.dx;
            if (newLeftWidth >= 10.0 && newRightWidth >= 10.0) {
              widget.onColumnResize(index, details.delta.dx / totalWidth);
            }
          },
          child: Stack(
            children: [
              Container(width: 3, color: Colors.transparent),
              Positioned(left: 1, top: 0, bottom: 0, child: Container(width: 1, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
