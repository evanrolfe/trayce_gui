import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/headers_table.dart';
import 'package:trayce/editor/widgets/common/headers_table_read_only.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';

import '../../../common/dropdown_style.dart';
import '../../../common/style.dart';

// EventSaveIntent is sent by editor tabs when the user wants to save the flow but is
// focused on the tab, not the editor
class EventSaveIntent {
  final ValueKey tabKey;

  const EventSaveIntent(this.tabKey);
}

class EventSaveRequest {
  final Request request;
  final ValueKey tabKey;

  EventSaveRequest(this.request, this.tabKey);
}

// Create a static notifier that all instances can share
class HttpEditorState {
  static final ValueNotifier<double> heightNotifier = ValueNotifier(0.5);

  static double? _cachedMiddlePaneHeight;
  static const String middlePaneHeightKey = 'http_editor_middle_pane_height';

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

class FlowEditorHttp extends StatefulWidget {
  final Request request;
  final ValueKey tabKey;

  const FlowEditorHttp({super.key, required this.request, required this.tabKey});

  @override
  State<FlowEditorHttp> createState() => _FlowEditorHttpState();
}

class _FlowEditorHttpState extends State<FlowEditorHttp> with TickerProviderStateMixin {
  bool isDividerHovered = false;
  late TabController _bottomTabController;
  late TabController _topTabController;
  final CodeLineEditingController _urlController = CodeLineEditingController();
  final CodeLineEditingController _reqBodyController = CodeLineEditingController();
  final CodeLineEditingController _respBodyController = CodeLineEditingController();
  String _selectedMethod = 'GET';
  static const List<String> _httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  final ScrollController _disabledScrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: false);
  late final HeadersStateManager _headersController;
  late final FocusNode focusNode;
  late final FocusNode dropdownFocusNode;
  late final FocusNode _topTabFocusNode;

  @override
  void initState() {
    super.initState();

    _bottomTabController = TabController(length: 2, vsync: this);
    _topTabController = TabController(length: 2, vsync: this);
    HttpEditorState.initialize();

    // Add listener to _urlController
    _urlController.addListener(_flowModified);
    _reqBodyController.addListener(_flowModified);

    _selectedMethod = widget.request.method.toUpperCase();
    _urlController.text = widget.request.url;
    _headersController = HeadersStateManager(
      onStateChanged: () => setState(() {}),
      initialRows: widget.request.headers,
      onModified: _flowModified,
    );
    if (widget.request.body != null) {
      _reqBodyController.text = widget.request.body!.toString();
    }

    focusNode = FocusNode();
    dropdownFocusNode = FocusNode();
    _topTabFocusNode = FocusNode();

    focusNode.onKeyEvent = _onKeyUp;
    dropdownFocusNode.onKeyEvent = _onKeyUp;
    _topTabFocusNode.onKeyEvent = _onKeyUp;

    context.read<EventBus>().on<EventSaveIntent>().listen((event) {
      if (event.tabKey == widget.tabKey) {
        saveFlow();
      }
    });
  }

  KeyEventResult _onKeyUp(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyS && HardwareKeyboard.instance.isControlPressed) {
        saveFlow();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN && HardwareKeyboard.instance.isControlPressed) {
        context.read<EventBus>().fire(EventNewRequest());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW && HardwareKeyboard.instance.isControlPressed) {
        context.read<EventBus>().fire(EventCloseCurrentNode());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _flowModified() {
    final formReq = _getRequestFromForm();
    final isDifferent = !formReq.equals(widget.request);

    context.read<EventBus>().fire(EventEditorNodeModified(widget.tabKey, isDifferent));
  }

  Request _getRequestFromForm() {
    List<Header> headers = [];
    try {
      headers = _headersController.getHeaders();
    } catch (e) {
      // _headersController not initialized yet
    }

    TextBody? body;
    if (_reqBodyController.text.isNotEmpty) {
      body = TextBody(content: _reqBodyController.text);
    }

    final formReq = Request(
      name: widget.request.name,
      type: widget.request.type,
      seq: widget.request.seq,
      method: _selectedMethod.toLowerCase(),
      url: _urlController.text,
      body: body,
      headers: headers,
      params: [], // todo
      requestVars: [], // todo
      responseVars: [], // todo
      assertions: [], // todo
      script: null, // todo
      tests: null, // todo
      docs: null, // todo
    );

    return formReq;
  }

  Future<void> saveFlow() async {
    final newRequest = _getRequestFromForm();
    widget.request.copyValuesFrom(newRequest);
    context.read<EventBus>().fire(EventSaveRequest(newRequest, widget.tabKey));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Unfocus when the widget is no longer visible
    if (!mounted) {
      focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_flowModified);
    _reqBodyController.removeListener(_flowModified);
    _bottomTabController.dispose();
    _topTabController.dispose();
    _respBodyController.dispose();
    _reqBodyController.dispose();
    _disabledScrollController.dispose();
    _headersController.dispose();
    focusNode.dispose();
    dropdownFocusNode.dispose();
    _topTabFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: HttpEditorState.heightNotifier,
      builder: (context, middlePaneHeight, _) {
        return Focus(
          focusNode: focusNode,
          canRequestFocus: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => focusNode.requestFocus(),
            child: Column(
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
                        'HTTP',
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
                          width: 100,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: const Color(0xFF474747), width: 1),
                              left: BorderSide(color: const Color(0xFF474747), width: 1),
                              bottom: BorderSide(color: const Color(0xFF474747), width: 1),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: DropdownButton2<String>(
                            focusNode: dropdownFocusNode,
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
                                  _flowModified();
                                });
                                focusNode.requestFocus();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleLineCodeEditor(
                            key: const Key('flow_editor_http_url_input'),
                            controller: _urlController,
                            keyCallback: _onKeyUp,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF474747), width: 0),
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () {}, style: commonButtonStyle, child: const Text('Send')),
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
                                  child: DefaultTabController(
                                    length: 2,
                                    animationDuration: Duration.zero,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 30,
                                          child: Focus(
                                            focusNode: _topTabFocusNode,
                                            canRequestFocus: true,
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
                                                  onTapDown: (_) {
                                                    _topTabController.animateTo(0);
                                                    _topTabFocusNode.requestFocus();
                                                  },
                                                  child: Container(
                                                    color: Colors.blue.withOpacity(0.0),
                                                    child: const SizedBox(width: 100, child: Tab(text: 'Headers')),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTapDown: (_) {
                                                    _topTabController.animateTo(1);
                                                    _topTabFocusNode.requestFocus();
                                                  },
                                                  child: Container(
                                                    color: Colors.blue.withOpacity(0.0),
                                                    child: const SizedBox(width: 100, child: Tab(text: 'Body')),
                                                  ),
                                                ),
                                              ],
                                              overlayColor: MaterialStateProperty.resolveWith<Color?>((
                                                Set<MaterialState> states,
                                              ) {
                                                if (states.contains(MaterialState.hovered)) {
                                                  return hoveredItemColor.withAlpha(hoverAlpha);
                                                }
                                                return null;
                                              }),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TabBarView(
                                            controller: _topTabController,
                                            children: [
                                              SingleChildScrollView(
                                                child: HeadersTable(
                                                  stateManager: _headersController,
                                                  keyCallback: _onKeyUp,
                                                ),
                                              ),
                                              MultiLineCodeEditor(
                                                controller: _reqBodyController,
                                                keyCallback: _onKeyUp,
                                              ),
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
                                                      child: const SizedBox(width: 100, child: Tab(text: 'Response')),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTapDown: (_) => _bottomTabController.animateTo(1),
                                                    child: Container(
                                                      color: Colors.blue.withOpacity(0.0),
                                                      child: const SizedBox(width: 100, child: Tab(text: 'Headers')),
                                                    ),
                                                  ),
                                                ],
                                                overlayColor: MaterialStateProperty.resolveWith<Color?>((
                                                  Set<MaterialState> states,
                                                ) {
                                                  if (states.contains(MaterialState.hovered)) {
                                                    return hoveredItemColor.withAlpha(hoverAlpha);
                                                  }
                                                  return null;
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
                                              child: const Text('200 OK', style: TextStyle(color: Colors.white)),
                                            ),
                                            const SizedBox(width: 20),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          controller: _bottomTabController,
                                          children: [
                                            MultiLineCodeEditor(controller: _respBodyController, keyCallback: _onKeyUp),
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
                                    HttpEditorState.saveHeight(newMiddleHeight);
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
            ),
          ),
        );
      },
    );
  }
}
