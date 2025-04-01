import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/models/flow.dart' as models;
import '../network/models/grpc_request.dart';
import '../network/models/grpc_response.dart';
import '../network/models/proto_def.dart';
import '../network/repo/proto_def_repo.dart';
import '../network/widgets/proto_def_modal.dart';

const Color textColor = Color(0xFFD4D4D4);
const String topPaneHeightKey = 'flow_view_top_pane_height';
const double defaultTopPaneHeight = 0.5;

class FlowViewCache {
  static double? _cachedHeight;

  static Future<void> preloadHeight() async {
    if (_cachedHeight != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedHeight = prefs.getDouble(topPaneHeightKey);
  }

  static double get height => _cachedHeight ?? defaultTopPaneHeight;

  static Future<void> saveHeight(double height) async {
    _cachedHeight = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(topPaneHeightKey, height);
  }
}

class FlowView extends StatefulWidget {
  final models.Flow? selectedFlow;

  const FlowView({
    super.key,
    this.selectedFlow,
  });

  @override
  State<FlowView> createState() => _FlowViewState();
}

class _FlowViewState extends State<FlowView> {
  final ValueNotifier<double> _heightNotifier = ValueNotifier(FlowViewCache.height);
  bool isDividerHovered = false;
  int _selectedTopTab = 0;
  int _selectedBottomTab = 0;
  int? _hoveredTabIndex;
  int? _hoveredBottomTabIndex;
  final TextEditingController _topController = TextEditingController();
  final TextEditingController _bottomController = TextEditingController();
  List<ProtoDef> _protoDefs = [];
  String? _selectedProtoDefName;

  @override
  void initState() {
    super.initState();
    _loadProtoDefs();
    _selectedProtoDefName = 'select';
    FlowViewCache.preloadHeight().then((_) {
      _heightNotifier.value = FlowViewCache.height;
    });
  }

  Future<void> _loadProtoDefs() async {
    final protoDefRepo = context.read<ProtoDefRepo>();
    final protoDefs = await protoDefRepo.getAll();
    setState(() {
      _protoDefs = protoDefs;
    });
  }

  @override
  void didUpdateWidget(FlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFlow?.request != null) {
      if (widget.selectedFlow?.l7Protocol == 'grpc' &&
          widget.selectedFlow!.request is GrpcRequest &&
          _selectedProtoDefName != null &&
          _selectedProtoDefName != 'select' &&
          _selectedProtoDefName != 'import') {
        final grpcRequest = widget.selectedFlow!.request as GrpcRequest;
        final selectedProtoDef = _protoDefs.firstWhere((def) => def.name == _selectedProtoDefName);
        _topController.text = grpcRequest.toStringParsed(selectedProtoDef);
      } else {
        _topController.text = widget.selectedFlow!.request.toString();
      }
    } else {
      _topController.text = '';
    }

    if (widget.selectedFlow?.response != null) {
      if (widget.selectedFlow?.l7Protocol == 'grpc' &&
          widget.selectedFlow!.response is GrpcResponse &&
          widget.selectedFlow!.request is GrpcRequest &&
          _selectedProtoDefName != null &&
          _selectedProtoDefName != 'select' &&
          _selectedProtoDefName != 'import') {
        final grpcRequest = widget.selectedFlow!.request as GrpcRequest;
        final grpcResponse = widget.selectedFlow!.response as GrpcResponse;
        final selectedProtoDef = _protoDefs.firstWhere((def) => def.name == _selectedProtoDefName);
        _bottomController.text = grpcResponse.toStringParsed(selectedProtoDef, grpcRequest.path);
      } else {
        _bottomController.text = widget.selectedFlow!.response.toString();
      }
    } else {
      _bottomController.text = '';
    }
  }

  @override
  void dispose() {
    _heightNotifier.dispose();
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  Future<void> _saveHeight(double height) async {
    await FlowViewCache.saveHeight(height);
    _heightNotifier.value = height;
  }

  Widget _buildTabs(int selectedIndex, Function(int) onTabChanged, bool isTopTabs) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(
          top: BorderSide(color: Color(0xFF474747)),
        ),
      ),
      child: Row(
        children: [
          _buildTab(isTopTabs ? 'Request' : 'Response', 0, selectedIndex == 0, () => onTabChanged(0), isTopTabs),
          // _buildTab('Tab 2', 1, selectedIndex == 1, () => onTabChanged(1), isTopTabs),
          const Spacer(),
          if (isTopTabs && widget.selectedFlow?.l7Protocol == 'grpc') // Only show dropdown for gRPC flows
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF474747),
                  width: 1,
                ),
              ),
              child: DropdownButton2<String>(
                value: _selectedProtoDefName,
                underline: Container(),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border.all(color: const Color(0xFF474747)),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  useRootNavigator: true,
                  width: 200,
                  openInterval: const Interval(0, 0),
                ),
                buttonStyleData: const ButtonStyleData(
                  height: 22,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                ),
                menuItemStyleData: MenuItemStyleData(
                  height: 24,
                  padding: EdgeInsets.zero,
                ),
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down, size: 16),
                  iconEnabledColor: textColor,
                ),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'select',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Select .proto file'),
                    ),
                  ),
                  ..._protoDefs.map((def) => DropdownMenuItem(
                        value: def.name,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(def.name),
                        ),
                      )),
                  const DropdownMenuItem(
                    value: 'import',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Import .proto file'),
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue == 'import') {
                    showProtoDefModal(context).then((_) {
                      // Refresh proto definitions after modal is closed
                      _loadProtoDefs();
                    });
                  } else {
                    setState(() {
                      _selectedProtoDefName = newValue;
                      // Trigger a refresh of the text by calling didUpdateWidget's logic
                      if (widget.selectedFlow?.request != null) {
                        if (widget.selectedFlow?.l7Protocol == 'grpc' &&
                            widget.selectedFlow!.request is GrpcRequest &&
                            newValue != null &&
                            newValue != 'select' &&
                            newValue != 'import') {
                          final grpcRequest = widget.selectedFlow!.request as GrpcRequest;
                          final selectedProtoDef = _protoDefs.firstWhere((def) => def.name == newValue);
                          _topController.text = grpcRequest.toStringParsed(selectedProtoDef);

                          // Also update response if it's a gRPC response
                          if (widget.selectedFlow?.response != null && widget.selectedFlow!.response is GrpcResponse) {
                            final grpcResponse = widget.selectedFlow!.response as GrpcResponse;
                            _bottomController.text = grpcResponse.toStringParsed(selectedProtoDef, grpcRequest.path);
                          }
                        } else {
                          _topController.text = widget.selectedFlow!.request.toString();
                          if (widget.selectedFlow?.response != null) {
                            _bottomController.text = widget.selectedFlow!.response.toString();
                          }
                        }
                      }
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index, bool isSelected, VoidCallback onTap, bool isTopTabs) {
    final isHovered = isTopTabs ? _hoveredTabIndex == index : _hoveredBottomTabIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() {
        if (isTopTabs) {
          _hoveredTabIndex = index;
        } else {
          _hoveredBottomTabIndex = index;
        }
      }),
      onExit: (_) => setState(() {
        if (isTopTabs) {
          _hoveredTabIndex = null;
        } else {
          _hoveredBottomTabIndex = null;
        }
      }),
      child: Listener(
        onPointerDown: (_) => onTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(minWidth: 125),
          decoration: BoxDecoration(
            color: isSelected || isHovered ? const Color(0xFF2D2D2D) : const Color(0xFF252526),
            border: Border(
              top: BorderSide(
                color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent,
                width: 1,
              ),
              right: const BorderSide(
                color: Color(0xFF474747),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        return ValueListenableBuilder<double>(
          valueListenable: _heightNotifier,
          builder: (context, topPaneHeight, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: totalHeight * topPaneHeight,
                      child: Column(
                        children: [
                          _buildTabs(_selectedTopTab, (index) {
                            setState(() => _selectedTopTab = index);
                          }, true),
                          Container(
                            height: 1,
                            color: const Color(0xFF474747),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _topController,
                                maxLines: null,
                                expands: true,
                                readOnly: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: totalHeight * (1 - topPaneHeight),
                      child: Column(
                        children: [
                          _buildTabs(_selectedBottomTab, (index) {
                            setState(() => _selectedBottomTab = index);
                          }, false),
                          Container(
                            height: 1,
                            color: const Color(0xFF474747),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _bottomController,
                                maxLines: null,
                                expands: true,
                                readOnly: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: totalHeight * topPaneHeight - 1.5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    onEnter: (_) => setState(() => isDividerHovered = true),
                    onExit: (_) => setState(() => isDividerHovered = false),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newTopHeight = topPaneHeight + (details.delta.dy / totalHeight);
                        if (newTopHeight > 0.1 && newTopHeight < 0.9) {
                          _saveHeight(newTopHeight);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            height: 3,
                            color: Colors.transparent,
                          ),
                          Positioned(
                            top: 1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
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
