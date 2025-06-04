import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trayce/network/repo/flow_repo.dart';

import '../../common/selectable_table.dart';
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
  final FocusNode _tableFocusNode = FocusNode();
  late final StreamSubscription _flowsSub;
  List<models.Flow> _flows = [];

  @override
  void initState() {
    super.initState();

    // Subscribe to verification events
    _flowsSub = context.read<EventBus>().on<EventDisplayFlows>().listen((event) {
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
    _tableFocusNode.dispose();
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
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('flow_table_search_input'),
                  focusNode: _searchFocusNode,
                  style: textFieldStyle,
                  decoration: textFieldDecor.copyWith(hintText: 'Search...'),
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
          child: SelectableTable<models.Flow>(
            controller: widget.controller,
            columnWidths: widget.columnWidths,
            onColumnResize: widget.onColumnResize,
            rows: _flows,
            focusNode: _tableFocusNode,
            onRowSelected: (flow) {
              setState(() {
                selectedFlowID = flow?.id;
                widget.onFlowSelected(flow);
              });
            },
            columns: [
              SelectableTableColumn(title: '#', cellBuilder: (flow) => flow.id?.toString() ?? ''),
              SelectableTableColumn(title: 'Protocol', cellBuilder: (flow) => flow.l7Protocol),
              SelectableTableColumn(title: 'Source', cellBuilder: (flow) => flow.source),
              SelectableTableColumn(title: 'Destination', cellBuilder: (flow) => flow.dest),
              SelectableTableColumn(title: 'Operation', cellBuilder: (flow) => flow.request?.operationCol() ?? ''),
              SelectableTableColumn(
                title: 'Response',
                cellBuilder: (flow) => flow.response?.responseCol() ?? '',
                cellDecorationBuilder:
                    (flow, text) => BoxDecoration(
                      color: _getStatusColor(text),
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                    ),
                cellTextAlign: TextAlign.center,
                cellTextWidth: 40,
              ),
            ],
            rowHeight: 25,
            headerHeight: 25,
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
}
