import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/headers_table_read_only.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';

import '../../../common/dropdown_style.dart';
import '../../../common/style.dart';
import 'grpc_stream.dart';

// Create a static notifier that all instances can share
class GrpcEditorState {
  static final ValueNotifier<double> heightNotifier = ValueNotifier(0.5);

  static double? _cachedMiddlePaneHeight;
  static const String middlePaneHeightKey = 'grpc_editor_middle_pane_height';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _cachedMiddlePaneHeight = prefs.getDouble(middlePaneHeightKey);
    if (_cachedMiddlePaneHeight != null) {
      heightNotifier.value = _cachedMiddlePaneHeight!;
    }
    _initialized = true;
  }

  static Future<void> saveHeight(double height) async {
    _cachedMiddlePaneHeight = height;
    heightNotifier.value = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(middlePaneHeightKey, height);
  }
}

class FlowEditorGrpc extends StatefulWidget {
  const FlowEditorGrpc({super.key});

  @override
  State<FlowEditorGrpc> createState() => _FlowEditorGrpcState();
}

class _FlowEditorGrpcState extends State<FlowEditorGrpc> with TickerProviderStateMixin {
  bool isDividerHovered = false;
  bool enableTLS = false;
  late TabController _bottomTabController;
  late TabController _topTabController;
  final CodeLineEditingController _responseController = CodeLineEditingController();
  final CodeLineEditingController _urlController = CodeLineEditingController();
  final CodeLineEditingController _bodyController = CodeLineEditingController();
  late final FormTableStateManager _headersController;
  String _selectedMethod = 'GET';
  static const List<String> _httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  final ScrollController _disabledScrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 2, vsync: this);
    _bottomTabController = TabController(length: 3, vsync: this);
    GrpcEditorState.initialize();

    _headersController = FormTableStateManager(onStateChanged: () => setState(() {}), initialRows: []);
  }

  @override
  void dispose() {
    _bottomTabController.dispose();
    _topTabController.dispose();
    _responseController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _headersController.dispose();
    _disabledScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: GrpcEditorState.heightNotifier,
      builder: (context, middlePaneHeight, _) {
        return Column(
          children: [
            // HTTP Label Pane
            Container(
              height: 30,
              color: lightBackgroundColor,
              child: const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'gRPC',
                    style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // Top fixed-height pane
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: lightBackgroundColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 20),
                child: Row(
                  children: [
                    Container(
                      height: 29,
                      width: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: const Color(0xFF474747), width: 1),
                          top: BorderSide(color: const Color(0xFF474747), width: 1),
                          bottom: BorderSide(color: const Color(0xFF474747), width: 1),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        color: const Color(0xFF2E2E2E),
                      ),
                      child: IconButton(
                        icon: Icon(enableTLS ? Icons.lock : Icons.lock_open, size: 16, color: const Color(0xFFD4D4D4)),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            enableTLS = !enableTLS;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: SingleLineCodeEditor(
                        controller: _urlController,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E2E),
                          border: Border(
                            top: BorderSide(color: borderColor, width: 1),
                            right: BorderSide(width: 0),
                            bottom: BorderSide(width: 0),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: const Color(0xFF474747), width: 1),
                            right: BorderSide(color: const Color(0xFF474747), width: 1),
                            bottom: BorderSide(color: const Color(0xFF474747), width: 1),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: DropdownButton2<String>(
                          value: _selectedMethod,
                          underline: Container(),
                          dropdownStyleData: DropdownStyleData(decoration: dropdownDecoration, width: 100),
                          buttonStyleData: ButtonStyleData(padding: const EdgeInsets.only(left: 4, top: 2, right: 4)),
                          menuItemStyleData: menuItemStyleData,
                          iconStyleData: iconStyleData,
                          style: textFieldStyle,
                          isExpanded: true,
                          items:
                              _httpMethods.map((String method) {
                                return DropdownMenuItem<String>(
                                  value: method,
                                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(method)),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedMethod = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () {}, style: commonButtonStyle, child: const Text('Invoke')),
                  ],
                ),
              ),
            ),
            // Middle and bottom panes with resizable divider
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final middleHeight = constraints.maxHeight * middlePaneHeight;
                  final bottomHeight = constraints.maxHeight * (1 - middlePaneHeight);

                  return Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth,
                            height: middleHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[700]!, width: 0)),
                              ),
                              child: DefaultTabController(
                                length: 2,
                                animationDuration: Duration.zero,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 30,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TabBar(
                                              controller: _topTabController,
                                              dividerColor: Colors.transparent,
                                              labelColor: const Color(0xFFD4D4D4),
                                              unselectedLabelColor: const Color(0xFF808080),
                                              indicator: const UnderlineTabIndicator(
                                                borderSide: BorderSide(width: 1, color: Color(0xFF4DB6AC)),
                                              ),
                                              labelPadding: EdgeInsets.zero,
                                              padding: EdgeInsets.zero,
                                              isScrollable: true,
                                              tabAlignment: TabAlignment.start,
                                              labelStyle: const TextStyle(fontWeight: FontWeight.normal),
                                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                                              tabs: [
                                                GestureDetector(
                                                  onTapDown: (_) => _topTabController.animateTo(0),
                                                  child: Container(
                                                    color: Colors.blue.withOpacity(0.0),
                                                    child: const SizedBox(width: 100, child: Tab(text: 'Message')),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTapDown: (_) => _topTabController.animateTo(1),
                                                  child: Container(
                                                    color: Colors.blue.withOpacity(0.0),
                                                    child: const SizedBox(width: 100, child: Tab(text: 'Metadata')),
                                                  ),
                                                ),
                                              ],
                                              overlayColor: MaterialStateProperty.resolveWith<Color?>((
                                                Set<MaterialState> states,
                                              ) {
                                                if (states.contains(MaterialState.hovered)) {
                                                  return hoveredItemColor.withAlpha(hoverAlpha);
                                                }
                                                return null; // Default for other states
                                              }),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {},
                                            style: tabbarButtonStyle,
                                            child: const Text('Generate Message'),
                                          ),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        controller: _topTabController,
                                        children: [
                                          MultiLineCodeEditor(controller: _bodyController),
                                          SingleChildScrollView(child: FormTable(stateManager: _headersController)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            height: bottomHeight,
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    height: 30,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TabBar(
                                            controller: _bottomTabController,
                                            dividerColor: Colors.transparent,
                                            labelColor: const Color(0xFFD4D4D4),
                                            unselectedLabelColor: const Color(0xFF808080),
                                            indicator: const UnderlineTabIndicator(
                                              borderSide: BorderSide(width: 1, color: Color(0xFF4DB6AC)),
                                            ),
                                            labelPadding: EdgeInsets.zero,
                                            padding: EdgeInsets.zero,
                                            isScrollable: true,
                                            tabAlignment: TabAlignment.start,
                                            labelStyle: const TextStyle(fontWeight: FontWeight.normal),
                                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                                            tabs: [
                                              GestureDetector(
                                                onTapDown: (_) => _bottomTabController.animateTo(0),
                                                child: Container(
                                                  color: Colors.blue.withOpacity(0.0),
                                                  child: const SizedBox(width: 100, child: Tab(text: 'Responses')),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTapDown: (_) => _bottomTabController.animateTo(1),
                                                child: Container(
                                                  color: Colors.blue.withOpacity(0.0),
                                                  child: const SizedBox(width: 100, child: Tab(text: 'Response')),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTapDown: (_) => _bottomTabController.animateTo(2),
                                                child: Container(
                                                  color: Colors.blue.withOpacity(0.0),
                                                  child: const SizedBox(width: 100, child: Tab(text: 'Metadata')),
                                                ),
                                              ),
                                            ],
                                            overlayColor: MaterialStateProperty.resolveWith<Color?>((
                                              Set<MaterialState> states,
                                            ) {
                                              if (states.contains(MaterialState.hovered)) {
                                                return hoveredItemColor.withAlpha(hoverAlpha);
                                              }
                                              return null; // Default for other states
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          height: 20,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('OK', style: TextStyle(color: Colors.white)),
                                        ),
                                        const SizedBox(width: 20),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _bottomTabController,
                                      children: [
                                        Padding(padding: const EdgeInsets.only(top: 20), child: GrpcStream()),
                                        MultiLineCodeEditor(controller: _responseController),
                                        Padding(padding: const EdgeInsets.all(20.0), child: HeadersTableReadOnly()),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: middleHeight - 1.5,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeRow,
                          onEnter: (_) => setState(() => isDividerHovered = true),
                          onExit: (_) => setState(() => isDividerHovered = false),
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              final localPosition = box.globalToLocal(details.globalPosition);
                              final newMiddleHeight = localPosition.dy / constraints.maxHeight;

                              if (newMiddleHeight > 0.1 && newMiddleHeight < 0.9) {
                                GrpcEditorState.saveHeight(newMiddleHeight);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(height: 3, color: Colors.transparent),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 1,
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
              ),
            ),
          ],
        );
      },
    );
  }
}
