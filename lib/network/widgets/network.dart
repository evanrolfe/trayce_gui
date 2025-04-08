import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/flow_view.dart';
import '../models/flow.dart' as models;
import 'flow_table.dart';

const double minPaneWidth = 300.0;
const Color textColor = Color(0xFFD4D4D4);
const String leftPaneWidthKey = 'network_left_pane_width';
const double defaultPaneWidth = 0.5;

class NetworkCache {
  static double? _cachedWidth;

  static Future<void> preloadWidth() async {
    if (_cachedWidth != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedWidth = prefs.getDouble(leftPaneWidthKey);
  }

  static double get width => _cachedWidth ?? defaultPaneWidth;

  static Future<void> saveWidth(double width) async {
    _cachedWidth = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(leftPaneWidthKey, width);
  }
}

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  final ScrollController _controller = ScrollController();
  final List<double> _columnWidths = [
    75.0 / 775.0, // 75px for #
    100.0 / 775.0, // 100px for Protocol
    150.0 / 775.0, // 150px for Source
    150.0 / 775.0, // 150px for Destination
    200.0 / 775.0, // 200px for Operation (expanding)
    100.0 / 775.0, // 100px for Response
  ];
  final ValueNotifier<double> _widthNotifier = ValueNotifier(NetworkCache.width);
  bool isDividerHovered = false;
  models.Flow? _selectedFlow;

  @override
  void initState() {
    super.initState();
    NetworkCache.preloadWidth().then((_) {
      _widthNotifier.value = NetworkCache.width;
    });
  }

  @override
  void dispose() {
    _widthNotifier.dispose();
    super.dispose();
  }

  void _handleColumnResize(int index, double delta) {
    setState(() {
      _columnWidths[index] += delta;
      _columnWidths[index + 1] -= delta;

      // Normalize to ensure total is exactly 1.0
      double total = _columnWidths.reduce((a, b) => a + b);
      if (total != 1.0) {
        double adjustment = (1.0 - total) / 2;
        _columnWidths[index] += adjustment;
        _columnWidths[index + 1] += adjustment;
      }
    });
  }

  void _handleFlowSelected(models.Flow? flow) {
    setState(() {
      _selectedFlow = flow;
    });
  }

  Future<void> _saveWidth(double width) async {
    await NetworkCache.saveWidth(width);
    _widthNotifier.value = width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return ValueListenableBuilder<double>(
          valueListenable: _widthNotifier,
          builder: (context, leftPaneWidth, _) {
            return Stack(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: totalWidth * leftPaneWidth,
                      child: FlowTable(
                        controller: _controller,
                        columnWidths: _columnWidths,
                        onColumnResize: _handleColumnResize,
                        onFlowSelected: _handleFlowSelected,
                      ),
                    ),
                    SizedBox(
                      width: totalWidth * (1 - leftPaneWidth),
                      child: FlowView(selectedFlow: _selectedFlow),
                    ),
                  ],
                ),
                Positioned(
                  left: totalWidth * leftPaneWidth - 1.5,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => isDividerHovered = true),
                    onExit: (_) => setState(() => isDividerHovered = false),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(details.globalPosition);
                        final newLeftWidth = localPosition.dx / totalWidth;

                        // Check if the new widths would be valid
                        final newRightWidth = 1 - newLeftWidth;
                        if ((newLeftWidth * totalWidth) >= minPaneWidth &&
                            (newRightWidth * totalWidth) >= minPaneWidth) {
                          _saveWidth(newLeftWidth);
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
                              color: isDividerHovered ? const Color(0xFF4DB6AC) : const Color(0xFF474747),
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
