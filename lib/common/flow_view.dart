import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/common/dropdown_style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/models/flow.dart' as models;
import '../network/models/grpc_request.dart';
import '../network/models/grpc_response.dart';
import '../network/models/proto_def.dart';
import '../network/repo/proto_def_repo.dart';
import '../network/widgets/proto_def_modal.dart';
import 'tab_style.dart';

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

  const FlowView({super.key, this.selectedFlow});

  @override
  State<FlowView> createState() => _FlowViewState();
}

class _FlowViewState extends State<FlowView> {
  final ValueNotifier<double> _heightNotifier = ValueNotifier(
    FlowViewCache.height,
  );
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
        final selectedProtoDef = _protoDefs.firstWhere(
          (def) => def.name == _selectedProtoDefName,
        );
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
        final selectedProtoDef = _protoDefs.firstWhere(
          (def) => def.name == _selectedProtoDefName,
        );
        _bottomController.text = grpcResponse.toStringParsed(
          selectedProtoDef,
          grpcRequest.path,
        );
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

  Widget _buildTabs(
    int selectedIndex,
    Function(int) onTabChanged,
    bool isTopTabs,
  ) {
    return Container(
      height: tabHeight,
      padding: const EdgeInsets.only(top: 1),
      decoration: getTabBarDecoration(),
      child: Row(
        children: [
          _buildTab(
            isTopTabs ? 'Request' : 'Response',
            0,
            selectedIndex == 0,
            () => onTabChanged(0),
            isTopTabs,
          ),
          const Spacer(),
          if (isTopTabs && widget.selectedFlow?.l7Protocol == 'grpc')
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                border: Border.all(color: tabBorderColor, width: 1),
              ),
              child: DropdownButton2<String>(
                value: _selectedProtoDefName,
                underline: Container(),
                dropdownStyleData: DropdownStyleData(
                  decoration: dropdownDecoration,
                  width: 150,
                ),
                buttonStyleData: buttonStyleData,
                menuItemStyleData: menuItemStyleData,
                iconStyleData: iconStyleData,
                style: tabTextStyle,
                items: [
                  const DropdownMenuItem(
                    value: 'select',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Select .proto file'),
                    ),
                  ),
                  ..._protoDefs.map(
                    (def) => DropdownMenuItem(
                      value: def.name,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(def.name),
                      ),
                    ),
                  ),
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
                          final grpcRequest =
                              widget.selectedFlow!.request as GrpcRequest;
                          final selectedProtoDef = _protoDefs.firstWhere(
                            (def) => def.name == newValue,
                          );
                          _topController.text = grpcRequest.toStringParsed(
                            selectedProtoDef,
                          );

                          // Also update response if it's a gRPC response
                          if (widget.selectedFlow?.response != null &&
                              widget.selectedFlow!.response is GrpcResponse) {
                            final grpcResponse =
                                widget.selectedFlow!.response as GrpcResponse;
                            _bottomController.text = grpcResponse
                                .toStringParsed(
                                  selectedProtoDef,
                                  grpcRequest.path,
                                );
                          }
                        } else {
                          _topController.text =
                              widget.selectedFlow!.request.toString();
                          if (widget.selectedFlow?.response != null) {
                            _bottomController.text =
                                widget.selectedFlow!.response.toString();
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

  Widget _buildTab(
    String text,
    int index,
    bool isSelected,
    VoidCallback onTap,
    bool isTopTabs,
  ) {
    final isHovered =
        isTopTabs ? _hoveredTabIndex == index : _hoveredBottomTabIndex == index;
    return MouseRegion(
      onEnter:
          (_) => setState(() {
            if (isTopTabs) {
              _hoveredTabIndex = index;
            } else {
              _hoveredBottomTabIndex = index;
            }
          }),
      onExit:
          (_) => setState(() {
            if (isTopTabs) {
              _hoveredTabIndex = null;
            } else {
              _hoveredBottomTabIndex = null;
            }
          }),
      child: Listener(
        onPointerDown: (_) => onTap(),
        child: Container(
          padding: tabPadding,
          constraints: tabConstraints,
          decoration: getTabDecoration(
            isSelected: isSelected,
            isHovered: isHovered,
            showTopBorder: true,
          ),
          child: Center(child: Text(text, style: tabTextStyle)),
        ),
      ),
    );
  }

  TextSpan _getText(String text) {
    List<TextSpan> children = [];

    final upgradeText = "Upgrade to Trayce Pro to see SQL queries";
    final hasUpgradeText = text.contains(upgradeText);

    if (hasUpgradeText) {
      text = text.replaceAll(upgradeText, '');
    }

    children.add(
      TextSpan(
        text: text,
        style: const TextStyle(
          color: textColor,
          fontSize: tabTextSize,
          fontFamily: 'monospace',
        ),
      ),
    );

    if (hasUpgradeText) {
      children.add(
        TextSpan(
          text: "\n\n$upgradeText",
          style: const TextStyle(
            color: Colors.blue,
            fontSize: tabTextSize,
            fontFamily: 'monospace',
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue,
          ),
          recognizer:
              TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(Uri.parse('https://get.trayce.dev/'));
                },
        ),
      );
    }

    return TextSpan(children: children);
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
                          Container(height: 1, color: tabBorderColor),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.topLeft,
                              child: SelectableText.rich(
                                _getText(_topController.text),
                                style: tabTextStyle.copyWith(
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.left,
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
                          Container(height: 1, color: tabBorderColor),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _bottomController,
                                maxLines: null,
                                expands: true,
                                readOnly: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: tabTextStyle.copyWith(
                                  fontFamily: 'monospace',
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
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
                      onVerticalDragUpdate: (details) {
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(
                          details.globalPosition,
                        );
                        final newTopHeight = localPosition.dy / totalHeight;
                        if (newTopHeight > 0.1 && newTopHeight < 0.9) {
                          _saveHeight(newTopHeight);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(height: 3, color: Colors.transparent),
                          Positioned(
                            top: 1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
                              color:
                                  isDividerHovered
                                      ? tabIndicatorColor
                                      : tabBorderColor,
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
