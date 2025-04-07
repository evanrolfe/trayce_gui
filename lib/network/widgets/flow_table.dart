import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trayce/network/repo/flow_repo.dart';

import '../../common/style.dart';
import '../models/flow.dart' as models;
import 'containers_modal.dart';

class FlowTable extends StatefulWidget {
  final ScrollController controller;
  final List<double> columnWidths;
  final Function(int, double) onColumnResize;
  final Function(models.Flow?) onFlowSelected;
  static const int totalItems = 10000;
  static const double minColumnWidth = 10.0;

  const FlowTable({
    super.key,
    required this.controller,
    required this.columnWidths,
    required this.onColumnResize,
    required this.onFlowSelected,
  });

  @override
  State<FlowTable> createState() => _FlowTableState();
}

class _FlowTableState extends State<FlowTable> {
  int? selectedFlowID;
  final FocusNode _searchFocusNode = FocusNode();
  late final StreamSubscription _flowsSub;
  List<models.Flow> _flows = [];

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _flowsSub = context.read<EventBus>().on<EventDisplayFlows>().listen((event) {
      print('EventDisplayFlows received: ${event.flows.length}');
      setState(() {
        _flows = event.flows;
      });
    });

    // Trigger this event initially to display the flows on load
    context.read<FlowRepo>().displayFlows();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _flowsSub.cancel();
    super.dispose();
  }

  int getSelectedFlowIndex() {
    return _flows.indexWhere((flow) => flow.id == selectedFlowID);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Input Pane
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF252526),
            border: Border(
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('flow_table_search_input'),
                  focusNode: _searchFocusNode,
                  style: textFieldStyle,
                  decoration: textFieldDecor,
                  onSubmitted: (value) {
                    context.read<FlowRepo>().setSearchTerm(value);
                    _searchFocusNode.requestFocus(); // dont loose focus when you hit enter
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => showContainersModal(context),
                style: commonButtonStyle,
                child: const Text('Containers'),
              ),
            ],
          ),
        ),
        // Table Section
        Expanded(
          child: Column(
            children: [
              // Fixed Header Row
              Container(
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  border: Border(
                    bottom: BorderSide(color: Colors.black),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    return Row(
                      children: List.generate(6, (colIndex) {
                        final titles = const ['#', 'Protocol', 'Source', 'Destination', 'Operation', 'Response'];
                        return SizedBox(
                          width: totalWidth * widget.columnWidths[colIndex],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              titles[colIndex],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFD4D4D4),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              // Scrollable Grid
              Expanded(
                child: Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    // Handle Arrow Up Press
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (selectedFlowID == null) {
                        return KeyEventResult.handled;
                      }
                      final nextIndex = getSelectedFlowIndex() - 1;
                      if (nextIndex < 0) {
                        return KeyEventResult.handled;
                      }

                      final nextFlow = _flows[nextIndex];

                      setState(() {
                        selectedFlowID = nextFlow.id;
                        widget.onFlowSelected(nextFlow);
                      });

                      return KeyEventResult.handled;
                    }

                    if (event is KeyRepeatEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      // TODO: Make this select the next flow at a set rate
                      return KeyEventResult.handled;
                    }

                    // Handle Arrow Down Press
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      if (selectedFlowID == null) {
                        return KeyEventResult.handled;
                      }
                      final nextIndex = getSelectedFlowIndex() + 1;
                      if (nextIndex > _flows.length - 1) {
                        return KeyEventResult.handled;
                      }

                      final nextFlow = _flows[nextIndex];

                      setState(() {
                        selectedFlowID = nextFlow.id;
                        widget.onFlowSelected(nextFlow);
                      });

                      return KeyEventResult.handled;
                    }

                    if (event is KeyRepeatEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      // TODO: Make this select the next flow at a set rate
                      return KeyEventResult.handled;
                    }

                    return KeyEventResult.ignored;
                  },
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: widget.controller,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: widget.controller,
                      itemCount: _flows.length,
                      cacheExtent: 1000,
                      itemExtent: 25,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      itemBuilder: (context, index) {
                        final flow = _flows[index];
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setState) => MouseRegion(
                            onEnter: (_) => setState(() => isHovered = true),
                            onExit: (_) => setState(() => isHovered = false),
                            child: GestureDetector(
                              onTap: () {
                                print('onTap: $index');
                                this.setState(() {
                                  selectedFlowID = flow.id;
                                  widget.onFlowSelected(flow);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black),
                                  ),
                                  color: selectedFlowID == flow.id
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
                                          children: [
                                            _buildCell(totalWidth * widget.columnWidths[0], flow.id?.toString() ?? ''),
                                            _buildCell(totalWidth * widget.columnWidths[1], flow.l7Protocol),
                                            _buildCell(totalWidth * widget.columnWidths[2], flow.source),
                                            _buildCell(totalWidth * widget.columnWidths[3], flow.dest),
                                            _buildCell(totalWidth * widget.columnWidths[4],
                                                flow.request?.operationCol() ?? ''),
                                            _buildCell(totalWidth * widget.columnWidths[5],
                                                flow.response?.responseCol() ?? '', true),
                                          ],
                                        ),
                                        ...List.generate(5, (i) {
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
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String text) {
    if (text.isEmpty) return Colors.transparent;

    final green = const Color(0xFF3B6118);

    if (text.toLowerCase() == 'ok') return green;

    switch (text[0]) {
      case '1':
        return const Color(0xFF514779);
      case '2':
        return green;
      case '3':
        return const Color(0xFF205A6D);
      case '4':
        return const Color(0xFF7A4C15);
      case '5':
        return const Color(0xFF7A3435);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildCell(double width, String text, [bool isResponse = false]) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: isResponse && text.isNotEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(text),
                      border: Border.all(
                        color: const Color(0xFF1E1E1E),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD4D4D4),
                      ),
                    ),
                  ),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD4D4D4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
      ),
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
            // Calculate the proposed new widths in pixels
            double newLeftWidth = widget.columnWidths[index] * totalWidth + details.delta.dx;
            double newRightWidth = widget.columnWidths[index + 1] * totalWidth - details.delta.dx;

            // Only update if both columns would remain wider than minimum
            if (newLeftWidth >= FlowTable.minColumnWidth && newRightWidth >= FlowTable.minColumnWidth) {
              widget.onColumnResize(index, details.delta.dx / totalWidth);
            }
          },
          child: Stack(
            children: [
              Container(
                width: 3,
                color: Colors.transparent,
              ),
              Positioned(
                left: 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
