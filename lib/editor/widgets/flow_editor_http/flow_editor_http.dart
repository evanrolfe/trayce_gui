import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/form_table_state.dart';
import 'package:trayce/editor/widgets/common/headers_table_read_only.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_controller.dart';
import 'package:trayce/utils/parsing.dart';

import '../../../common/dropdown_style.dart';
import '../../../common/style.dart';
import 'focus_manager.dart';

// EventSaveIntent is sent by editor tabs when the user wants to save the flow but is
// focused on the tab, not the editor
class EventSaveIntent {
  final ValueKey tabKey;

  const EventSaveIntent(this.tabKey);
}

class EventSendRequest {
  final ValueKey tabKey;

  EventSendRequest(this.tabKey);
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
  final ExplorerNode? node;
  final Request request;
  final ValueKey tabKey;

  const FlowEditorHttp({super.key, this.node, required this.request, required this.tabKey});

  @override
  State<FlowEditorHttp> createState() => _FlowEditorHttpState();
}

class _FlowEditorHttpState extends State<FlowEditorHttp> with TickerProviderStateMixin {
  // Static form options
  static const List<String> _formatOptions = ['Unformatted', 'JSON', 'HTML'];
  static const List<String> _httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  // State variables
  bool isDividerHovered = false;
  bool _isSending = false;

  // Controllers
  late TabController _bottomTabController;
  late TabController _topTabController;
  late final FormController _formController;
  late final EditorFocusManager _focusManager;

  // Response vars
  String? _respStatusMsg;
  Color _respStatusColor = Colors.green;
  List<Header> _respHeaders = [];
  String _selectedFormat = 'Unformatted';
  late final Request _formRequest; // the request as it appears in the form
  http.Response? _response;

  @override
  void initState() {
    super.initState();
    HttpEditorState.initialize();

    // Init the tab controllers
    _bottomTabController = TabController(length: 2, vsync: this);
    _topTabController = TabController(length: 2, vsync: this);
    _topTabController.addListener(() {
      setState(() {}); // This will trigger a rebuild when the tab changes
    });

    // Init the form request
    _formRequest = Request.blank();
    _formRequest.copyValuesFrom(widget.request);

    void setStateCallback() => setState(() {});
    final config = context.read<Config>();

    // Init the focus manager
    _focusManager = EditorFocusManager(context.read<EventBus>(), widget.tabKey);
    _focusManager.urlFocusNode.requestFocus(); // Request focus on URL input when widget is first opened

    _formController = FormController(
      _formRequest,
      widget.request,
      context.read<EventBus>(),
      widget.tabKey,
      config,
      setStateCallback,
      _focusManager,
    );

    context.read<EventBus>().on<EventSaveIntent>().listen((event) {
      if (event.tabKey == widget.tabKey) {
        saveFlow();
      }
    });

    context.read<EventBus>().on<EventSendRequest>().listen((event) {
      if (event.tabKey == widget.tabKey) {
        sendRequest();
      }
    });
  }

  Future<void> saveFlow() async {
    context.read<EventBus>().fire(EventSaveRequest(_formRequest, widget.tabKey));
    widget.request.copyValuesFrom(_formRequest);
  }

  Future<void> sendRequest() async {
    setState(() {
      _isSending = true;
    });
    FocusScope.of(context).requestFocus(_focusManager.editorFocusNode);

    try {
      final explorerRepo = context.read<ExplorerRepo>();
      List<ExplorerNode> nodeHierarchy = [];
      if (widget.node != null) nodeHierarchy = explorerRepo.getNodeHierarchy(widget.node!);

      _response = await SendRequest(request: _formRequest, nodeHierarchy: nodeHierarchy).send();

      // Set the selected format
      final contentType = _response!.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('json')) {
        _selectedFormat = 'JSON';
      } else if (contentType.contains('html') || contentType.contains('xml')) {
        _selectedFormat = 'HTML';
      } else {
        _selectedFormat = 'Unformatted';
      }

      // Display the response
      displayResponse();
    } catch (e) {
      _response = null;
      setState(() {
        _respStatusMsg = 'Error';
        _respStatusColor = statusErrorColor;
        _formController.respBodyController.text = 'Error: $e';
        _respHeaders = [];
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void displayResponse() {
    if (_response == null) return;
    final statusCode = _response!.statusCode;

    setState(() {
      _respHeaders = _response!.headers.entries.map((e) => Header(name: e.key, value: e.value, enabled: true)).toList();
      _respStatusMsg = '$statusCode ${_response!.reasonPhrase}';
      if (statusCode < 200) {
        _respStatusColor = statusProtocolColor;
      } else if (statusCode >= 200 && statusCode < 300) {
        _respStatusColor = statusOkColor;
      } else if (statusCode >= 300 && statusCode < 500) {
        _respStatusColor = statusWarningColor;
      } else {
        _respStatusColor = statusErrorColor;
      }
      // Format the response body based on the selected format
      if (_selectedFormat == 'JSON') {
        _formController.respBodyController.text = formatJson(_response!.body);
      } else if (_selectedFormat == 'HTML') {
        _formController.respBodyController.text = formatHTML(_response!.body);
      } else {
        _formController.respBodyController.text = _response!.body;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Unfocus when the widget is no longer visible
    if (!mounted) {
      _focusManager.editorFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _bottomTabController.dispose();

    _formController.dispose();
    _focusManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int bodyTypeIndex = 1;

    if (_formController.selectedBodyType == FormController.bodyTypeOptions[0]) {
      bodyTypeIndex = 0;
    } else if (_formController.selectedBodyType == FormController.bodyTypeOptions[4]) {
      // Form URL encoded
      bodyTypeIndex = 2;
    } else if (_formController.selectedBodyType == FormController.bodyTypeOptions[5]) {
      // Multi part form
      bodyTypeIndex = 3;
    } else if (_formController.selectedBodyType == FormController.bodyTypeOptions[6]) {
      // File
      bodyTypeIndex = 4;
    }

    final tabContentBorder = Border(
      top: BorderSide(width: 0, color: backgroundColor),
      left: BorderSide(width: 0),
      right: BorderSide(width: 0),
      bottom: BorderSide(width: 0, color: backgroundColor),
    );

    return ValueListenableBuilder<double>(
      valueListenable: HttpEditorState.heightNotifier,
      builder: (context, middlePaneHeight, _) {
        return Focus(
          focusNode: _focusManager.editorFocusNode,
          canRequestFocus: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusManager.editorFocusNode.requestFocus(),
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
                            key: const Key('flow_editor_http_method_dropdown'),
                            focusNode: _focusManager.methodFocusNode,
                            value: _formController.selectedMethod,
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
                                  _formController.setMethod(newValue);
                                });
                                _focusManager.editorFocusNode.requestFocus();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleLineCodeEditor(
                            key: const Key('flow_editor_http_url_input'),
                            controller: _formController.urlController,
                            onSavePressed: saveFlow,
                            onEnterPressed: sendRequest,
                            focusNode: _focusManager.urlFocusNode,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF474747), width: 1),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('flow_editor_http_send_btn'),
                          onPressed: sendRequest,
                          style: commonButtonStyle.copyWith(minimumSize: WidgetStateProperty.all(const Size(80, 36))),
                          child:
                              _isSending
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                  : const Text('Send'),
                        ),
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
                                    border: Border(
                                      top: BorderSide(width: 1),
                                      left: BorderSide(width: 0),
                                      right: BorderSide(width: 0),
                                      bottom: BorderSide(width: 0),
                                    ),
                                  ),
                                  child: DefaultTabController(
                                    length: 2,
                                    animationDuration: Duration.zero,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 30,
                                          decoration: BoxDecoration(border: tabContentBorder),
                                          child: Focus(
                                            focusNode: _focusManager.topTabFocusNode,
                                            canRequestFocus: true,
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
                                                    unselectedLabelStyle: const TextStyle(
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                    tabs: [
                                                      GestureDetector(
                                                        onTapDown: (_) {
                                                          _topTabController.animateTo(0);
                                                          _focusManager.topTabFocusNode.requestFocus();
                                                        },
                                                        child: Container(
                                                          color: Colors.blue.withOpacity(0.0),
                                                          child: const SizedBox(
                                                            width: 100,
                                                            child: Tab(text: 'Headers'),
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTapDown: (_) {
                                                          _topTabController.animateTo(1);
                                                          _focusManager.topTabFocusNode.requestFocus();
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
                                                if (_topTabController.index == 1) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    width: 120,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: const Color(0xFF474747), width: 1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: DropdownButton2<String>(
                                                      key: const Key('flow_editor_http_body_type_dropdown'),
                                                      focusNode: _focusManager.bodyTypeFocusNode,
                                                      value: _formController.selectedBodyType,
                                                      underline: Container(),
                                                      dropdownStyleData: DropdownStyleData(
                                                        decoration: dropdownDecoration,
                                                        width: 150,
                                                      ),
                                                      buttonStyleData: ButtonStyleData(
                                                        padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                                      ),
                                                      menuItemStyleData: menuItemStyleData,
                                                      iconStyleData: iconStyleData,
                                                      style: textFieldStyle,
                                                      isExpanded: true,
                                                      items:
                                                          FormController.bodyTypeOptions.map((String format) {
                                                            return DropdownMenuItem<String>(
                                                              value: format,
                                                              child: Padding(
                                                                padding: EdgeInsets.symmetric(horizontal: 8),
                                                                child: Text(format),
                                                              ),
                                                            );
                                                          }).toList(),
                                                      onChanged: _formController.setBodyType,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TabBarView(
                                            controller: _topTabController,
                                            children: [
                                              SingleChildScrollView(
                                                child: FormTable(
                                                  stateManager: _formController.headersController,
                                                  onSavePressed: saveFlow,
                                                ),
                                              ),
                                              IndexedStack(
                                                index: bodyTypeIndex,
                                                children: [
                                                  // No Body
                                                  Center(
                                                    child: Text(
                                                      'No Body',
                                                      style: TextStyle(color: Color(0xFF808080), fontSize: 16),
                                                    ),
                                                  ),
                                                  // Text editor for text/json/xml
                                                  MultiLineCodeEditor(
                                                    focusNode: _focusManager.reqBodyFocusNode,
                                                    border: tabContentBorder,
                                                    controller: _formController.reqBodyController,
                                                  ),
                                                  // Form Table Form URL Encoded
                                                  SingleChildScrollView(
                                                    child: FormTable(
                                                      stateManager: _formController.formUrlEncodedController,
                                                      onSavePressed: saveFlow,
                                                    ),
                                                  ),
                                                  // Form Table Multi Part Form
                                                  SingleChildScrollView(
                                                    child: FormTable(
                                                      stateManager: _formController.multipartFormController,
                                                      onSavePressed: saveFlow,
                                                      columns: [
                                                        FormTableColumn.enabled,
                                                        FormTableColumn.key,
                                                        FormTableColumn.valueFile,
                                                        FormTableColumn.contentType,
                                                        FormTableColumn.delete,
                                                      ],
                                                    ),
                                                  ),
                                                  // Form Table File
                                                  SingleChildScrollView(
                                                    child: FormTable(
                                                      stateManager: _formController.fileController,
                                                      onSavePressed: saveFlow,
                                                      columns: [
                                                        FormTableColumn.valueFile,
                                                        FormTableColumn.contentType,
                                                        FormTableColumn.selected,
                                                        FormTableColumn.delete,
                                                      ],
                                                    ),
                                                  ),
                                                ],
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
                                            if (_respStatusMsg != null) ...[
                                              Container(
                                                height: 20,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: _respStatusColor,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _respStatusMsg!,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                width: 120,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: const Color(0xFF474747), width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: DropdownButton2<String>(
                                                  key: const Key('flow_editor_http_format_dropdown'),
                                                  focusNode: _focusManager.formatFocusNode,
                                                  value: _selectedFormat,
                                                  underline: Container(),
                                                  dropdownStyleData: DropdownStyleData(
                                                    decoration: dropdownDecoration,
                                                    width: 120,
                                                  ),
                                                  buttonStyleData: ButtonStyleData(
                                                    padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                                  ),
                                                  menuItemStyleData: menuItemStyleData,
                                                  iconStyleData: iconStyleData,
                                                  style: textFieldStyle,
                                                  isExpanded: true,
                                                  items:
                                                      _formatOptions.map((String format) {
                                                        return DropdownMenuItem<String>(
                                                          value: format,
                                                          child: Padding(
                                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                                            child: Text(format),
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (String? newValue) {
                                                    if (newValue != null) {
                                                      setState(() {
                                                        _selectedFormat = newValue;
                                                      });
                                                      displayResponse();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 20),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          controller: _bottomTabController,
                                          children: [
                                            MultiLineCodeEditor(
                                              focusNode: _focusManager.respBodyFocusNode,
                                              border: tabContentBorder,
                                              controller: _formController.respBodyController,
                                            ),
                                            SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: HeadersTableReadOnly(headers: _respHeaders),
                                              ),
                                            ),
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
