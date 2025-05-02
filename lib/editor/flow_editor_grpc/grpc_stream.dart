import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/code_editor/code_editor_multi.dart';
import 'package:trayce/network/repo/flow_repo.dart';

import '../../common/selectable_table.dart';

class GrpcStreamMessage implements Identifiable {
  final int id;
  final String message;
  final String time;
  GrpcStreamMessage({required this.id, required this.message, required this.time});

  @override
  int getTableKey() => id;
}

class GrpcStream extends StatefulWidget {
  const GrpcStream({super.key});

  @override
  State<GrpcStream> createState() => _GrpcStreamState();
}

class _GrpcStreamState extends State<GrpcStream> {
  final ScrollController _controller = ScrollController();
  final List<double> _columnWidths = [0.7, 0.3];
  final FocusNode _tableFocusNode = FocusNode();
  final CodeLineEditingController _messageController = CodeLineEditingController();
  final ValueNotifier<double> _leftPaneWidth = ValueNotifier(0.5);
  bool _isDividerHovered = false;

  int? selectedMessageID;
  late final StreamSubscription _flowsSub;
  List<GrpcStreamMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _flowsSub = context.read<EventBus>().on<EventDisplayFlows>().listen((event) {
      print('EventDisplayFlows received: ${event.flows.length}');
      setState(() {
        _messages = [
          GrpcStreamMessage(id: 1, message: 'Hello, world!', time: '12:00:01'),
          GrpcStreamMessage(id: 2, message: 'Received response', time: '12:00:02'),
          GrpcStreamMessage(id: 3, message: 'Hello, world!', time: '12:00:01'),
          GrpcStreamMessage(id: 4, message: 'Received response', time: '12:00:02'),
          GrpcStreamMessage(id: 5, message: 'Hello, world!', time: '12:00:01'),
          GrpcStreamMessage(id: 6, message: 'Received response', time: '12:00:02'),
          GrpcStreamMessage(id: 7, message: 'Hello, world!', time: '12:00:01'),
          GrpcStreamMessage(id: 8, message: 'Received response', time: '12:00:02'),
        ];
      });
    });

    // Trigger this event initially to display the flows on load
    context.read<FlowRepo>().displayFlows();
  }

  @override
  void dispose() {
    _tableFocusNode.dispose();
    _flowsSub.cancel();
    _messageController.dispose();
    _leftPaneWidth.dispose();
    super.dispose();
  }

  void _onColumnResize(int index, double delta) {
    setState(() {
      final newWidths = List<double>.from(_columnWidths);
      newWidths[index] += delta;
      newWidths[index + 1] -= delta;
      // Clamp to reasonable values
      if (newWidths[index] < 0.1 || newWidths[index + 1] < 0.1) return;
      _columnWidths[0] = newWidths[0];
      _columnWidths[1] = newWidths[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _leftPaneWidth,
      builder: (context, leftPaneWidth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final leftWidth = constraints.maxWidth * leftPaneWidth;
            final rightWidth = constraints.maxWidth * (1 - leftPaneWidth);

            return Stack(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: leftWidth,
                      child: SelectableTable<GrpcStreamMessage>(
                        controller: _controller,
                        columnWidths: _columnWidths,
                        onColumnResize: _onColumnResize,
                        rows: _messages,
                        focusNode: _tableFocusNode,
                        onRowSelected: (row) {
                          setState(() {
                            selectedMessageID = row?.id;
                            if (row != null) {
                              _messageController.text = row.message;
                            }
                          });
                        },
                        columns: [
                          SelectableTableColumn(title: 'Message', cellBuilder: (msg) => msg.message),
                          SelectableTableColumn(title: 'Time', cellBuilder: (msg) => msg.time),
                        ],
                        rowHeight: 25,
                        headerHeight: 25,
                      ),
                    ),
                    SizedBox(
                      width: rightWidth,
                      child: MultiLineCodeEditor(
                        controller: _messageController,
                        border: Border(top: BorderSide(color: borderColor, width: 1)),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: leftWidth - 1.5,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => _isDividerHovered = true),
                    onExit: (_) => setState(() => _isDividerHovered = false),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(details.globalPosition);
                        final newLeftWidth = localPosition.dx / constraints.maxWidth;

                        if (newLeftWidth > 0.2 && newLeftWidth < 0.8) {
                          _leftPaneWidth.value = newLeftWidth;
                        }
                      },
                      child: Stack(
                        children: [
                          Container(width: 3, color: Colors.transparent),
                          Positioned(
                            left: 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: _isDividerHovered ? const Color(0xFF4DB6AC) : const Color(0xFF474747),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
