import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/environment_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/headers_table_read_only.dart';
import 'package:trayce/editor/widgets/common/inline_tab_bar.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_api_key_form.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_basic_form.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_bearer_form.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_inherit.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_not_implemented.dart';
import 'package:trayce/editor/widgets/flow_editor_http/request_form_controller.dart';
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
  final ExplorerNode collectionNode;
  final ExplorerNode? node; // the node will be null if the request is not saved yet
  final Request request;
  final ValueKey tabKey;

  const FlowEditorHttp({
    super.key,
    required this.collectionNode,
    this.node,
    required this.request,
    required this.tabKey,
  });

  @override
  State<FlowEditorHttp> createState() => _FlowEditorHttpState();
}

class _FlowEditorHttpState extends State<FlowEditorHttp> with TickerProviderStateMixin {
  // Static form options
  static const List<String> _formatOptions = ['Unformatted', 'JSON', 'HTML'];
  static const List<String> _httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];
  static const List<String> _topTabTitles = ['Params', 'Body', 'Headers', 'Auth', 'Variables', 'Script'];
  static const List<String> _bottomTabTitles = ['Response', 'Headers', 'Output'];

  // State variables
  bool isDividerHovered = false;
  bool _isSending = false;
  int _scriptTypeIndex = 0;

  // Controllers
  late TabController _bottomTabController;
  late TabController _topTabController;
  late final RequestFormController _formController;
  late final EditorFocusManager _focusManager;

  // Response vars
  String? _respStatusMsg;
  Color _respStatusColor = Colors.green;
  List<Header> _respHeaders = [];
  String _selectedFormat = 'Unformatted';
  late final Request _formRequest; // the request as it appears in the form
  http.Response? _response;
  List<String> _consoleOutput = [];

  @override
  void initState() {
    super.initState();
    HttpEditorState.initialize();

    // Init the tab controllers
    _bottomTabController = TabController(length: _bottomTabTitles.length, vsync: this);
    _topTabController = TabController(length: _topTabTitles.length, vsync: this);
    _topTabController.addListener(() {
      setState(() {}); // This will trigger a rebuild when the tab changes
    });

    // Init the form request
    _formRequest = Request.blank();
    _formRequest.copyValuesFrom(widget.request);

    void setStateCallback() {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }

    final config = context.read<ConfigRepo>().get();

    // Init the focus manager
    _focusManager = EditorFocusManager(context.read<EventBus>(), widget.tabKey);
    _focusManager.urlFocusNode.requestFocus(); // Request focus on URL input when widget is first opened

    _formController = RequestFormController(
      _formRequest,
      widget.request,
      context.read<EventBus>(),
      widget.tabKey,
      config,
      context.read<FilePickerI>(),
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
      final explorerService = context.read<ExplorerService>();
      final runtimeVarsRepo = context.read<RuntimeVarsRepo>();
      final config = context.read<ConfigRepo>().get();
      final httpClient = context.read<HttpClientI>();
      final sendResult =
          await SendRequest(
            httpClient: httpClient,
            request: _formRequest,
            node: widget.node,
            collectionNode: widget.collectionNode,
            explorerService: explorerService,
            runtimeVarsRepo: runtimeVarsRepo,
            environmentRepo: context.read<EnvironmentRepo>(),
            config: config,
          ).send();

      _response = sendResult.response;
      _consoleOutput = sendResult.output;

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
      displayConsoleOutput();
    } catch (e) {
      _response = null;
      print("sendRequest error $e");
      setState(() {
        _respStatusMsg = 'Error';
        _respStatusColor = statusErrorColor;
        _formController.respBodyController.text = 'Error: $e';
        _respHeaders = [];
      });
      rethrow;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void displayResponse() {
    print("===============> displayResponse");
    if (_response == null) return;
    final statusCode = _response!.statusCode;
    print("===============> ${_response!.statusCode} ${_response!.body}");
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

  void displayConsoleOutput() {
    setState(() {
      _formController.respOutputController.text = _consoleOutput.join('\n');
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
    int authTypeIndex = 0;

    if (_formController.selectedBodyType == RequestFormController.bodyTypeOptions[0]) {
      bodyTypeIndex = 0;
    } else if (_formController.selectedBodyType == RequestFormController.bodyTypeOptions[4]) {
      // Form URL encoded
      bodyTypeIndex = 2;
    } else if (_formController.selectedBodyType == RequestFormController.bodyTypeOptions[5]) {
      // Multi part form
      bodyTypeIndex = 3;
    } else if (_formController.selectedBodyType == RequestFormController.bodyTypeOptions[6]) {
      // File
      bodyTypeIndex = 4;
    }

    if (_formController.selectedAuthType == RequestFormController.authTypeOptions[0]) {
      authTypeIndex = 0;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[1]) {
      // API Key
      authTypeIndex = 1;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[2]) {
      // Basic Auth
      authTypeIndex = 2;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[3]) {
      // Bearer Token
      authTypeIndex = 3;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[4]) {
      // Digest
      authTypeIndex = 4;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[5]) {
      // OAuth2
      authTypeIndex = 5;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[6]) {
      // WSSE
      authTypeIndex = 6;
    } else if (_formController.selectedAuthType == RequestFormController.authTypeOptions[7]) {
      // Inherit
      authTypeIndex = 7;
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
                          decoration: methodDropdownDecoration,
                          child: DropdownButton2<String>(
                            key: const Key('flow_editor_http_method_dropdown'),
                            focusNode: _focusManager.methodFocusNode,
                            value: _formController.selectedMethod,
                            underline: Container(),
                            dropdownStyleData: DropdownStyleData(
                              decoration: dropdownDecoration,
                              width: 100,
                              openInterval: Interval(0.0, 0.0),
                            ),
                            buttonStyleData: ButtonStyleData(
                              padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                              overlayColor: WidgetStateProperty.all(Colors.amber),
                            ),
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
                          child: URLInput(
                            key: const Key('flow_editor_http_url_input'),
                            controller: _formController.urlController,
                            onEnterPressed: sendRequest,
                            focusNode: _focusManager.urlFocusNode,
                            decoration: BoxDecoration(color: const Color(0xFF2E2E2E)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('flow_editor_http_send_btn'),
                          onPressed: sendRequest,
                          style: commonButtonStyle.copyWith(
                            minimumSize: WidgetStateProperty.all(const Size(80, 36)),
                            backgroundColor: WidgetStateProperty.all(selectedMenuItemColor),
                          ),
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
                                  : const Text(
                                    'Send',
                                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
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
                                                  child: InlineTabBar(
                                                    controller: _topTabController,
                                                    tabTitles: _topTabTitles,
                                                    focusNode: _focusManager.topTabFocusNode,
                                                  ),
                                                ),
                                                // -----------------------------------------------------------
                                                // Body Type Dropdown
                                                // -----------------------------------------------------------
                                                if (_topTabController.index == 1) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    width: 120,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: const Color(0xFF474747), width: 0),
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
                                                        openInterval: Interval(0.0, 0.0),
                                                      ),
                                                      buttonStyleData: ButtonStyleData(
                                                        padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                                      ),
                                                      menuItemStyleData: menuItemStyleData,
                                                      iconStyleData: iconStyleData,
                                                      style: textFieldStyle,
                                                      isExpanded: true,
                                                      items:
                                                          RequestFormController.bodyTypeOptions.map((String format) {
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
                                                // -----------------------------------------------------------
                                                // Auth Type Dropdown
                                                // -----------------------------------------------------------
                                                if (_topTabController.index == 3) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    width: 120,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: const Color(0xFF474747), width: 0),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: DropdownButton2<String>(
                                                      key: const Key('flow_editor_http_auth_type_dropdown'),
                                                      focusNode: _focusManager.authTypeFocusNode,
                                                      value: _formController.selectedAuthType,
                                                      underline: Container(),
                                                      dropdownStyleData: DropdownStyleData(
                                                        decoration: dropdownDecoration,
                                                        width: 150,
                                                        openInterval: Interval(0.0, 0.0),
                                                      ),
                                                      buttonStyleData: ButtonStyleData(
                                                        padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                                      ),
                                                      menuItemStyleData: menuItemStyleData,
                                                      iconStyleData: iconStyleData,
                                                      style: textFieldStyle,
                                                      isExpanded: true,
                                                      items:
                                                          RequestFormController.authTypeOptions.map((String format) {
                                                            return DropdownMenuItem<String>(
                                                              value: format,
                                                              child: Padding(
                                                                padding: EdgeInsets.symmetric(horizontal: 8),
                                                                child: Text(format),
                                                              ),
                                                            );
                                                          }).toList(),
                                                      onChanged: _formController.setAuthType,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                ],
                                                // -----------------------------------------------------------
                                                // Script Type Dropdown
                                                // -----------------------------------------------------------
                                                if (_topTabController.index == 5) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    width: 130,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: const Color(0xFF474747), width: 0),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: DropdownButton2<String>(
                                                      key: const Key('flow_editor_script_type_dropdown'),
                                                      focusNode: _focusManager.authTypeFocusNode,
                                                      value: _scriptTypeIndex == 0 ? 'Pre-Request' : 'Post-Response',
                                                      underline: Container(),
                                                      dropdownStyleData: DropdownStyleData(
                                                        decoration: dropdownDecoration,
                                                        width: 150,
                                                        openInterval: Interval(0.0, 0.0),
                                                      ),
                                                      buttonStyleData: ButtonStyleData(
                                                        padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                                      ),
                                                      menuItemStyleData: menuItemStyleData,
                                                      iconStyleData: iconStyleData,
                                                      style: textFieldStyle,
                                                      isExpanded: true,
                                                      items:
                                                          ['Pre-Request', 'Post-Response'].map((String format) {
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
                                                            _scriptTypeIndex = newValue == 'Pre-Request' ? 0 : 1;
                                                          });
                                                        }
                                                      },
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
                                              // -----------------------------------------------------------
                                              // Params Tab
                                              // -----------------------------------------------------------
                                              SingleChildScrollView(
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.only(left: 20, top: 10),
                                                      child: Text(
                                                        'Query Params',
                                                        style: TextStyle(
                                                          color: Color(0xFF666666),
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    FormTable(
                                                      controller: _formController.queryParamsController,
                                                      columns: [
                                                        FormTableColumn.key,
                                                        FormTableColumn.value,
                                                        FormTableColumn.delete,
                                                      ],
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.only(left: 20, top: 10),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            'Path Params',
                                                            style: TextStyle(
                                                              color: Color(0xFF666666),
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Tooltip(
                                                            message:
                                                                'The Path Params table is automatically populated whenever a segment starting with : is added to the URL.\nFor example: http://localhost/api/users/:id',
                                                            child: const Icon(
                                                              Icons.help_outline,
                                                              size: 16,
                                                              color: Color(0xFF666666),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    FormTable(
                                                      controller: _formController.pathParamsController,
                                                      columns: [FormTableColumn.key, FormTableColumn.value],
                                                      readOnlyColumns: [FormTableColumn.key],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // -----------------------------------------------------------
                                              // Body Tab
                                              // -----------------------------------------------------------
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
                                                      controller: _formController.formUrlEncodedController,
                                                      columns: [
                                                        FormTableColumn.enabled,
                                                        FormTableColumn.key,
                                                        FormTableColumn.value,
                                                        FormTableColumn.delete,
                                                      ],
                                                    ),
                                                  ),
                                                  // Form Table Multi Part Form
                                                  SingleChildScrollView(
                                                    child: FormTable(
                                                      controller: _formController.multipartFormController,
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
                                                      controller: _formController.fileController,
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
                                              // -----------------------------------------------------------
                                              // Headers Tab
                                              // -----------------------------------------------------------
                                              SingleChildScrollView(
                                                child: FormTable(
                                                  controller: _formController.headersController,
                                                  columns: [
                                                    FormTableColumn.enabled,
                                                    FormTableColumn.key,
                                                    FormTableColumn.value,
                                                    FormTableColumn.delete,
                                                  ],
                                                ),
                                              ),
                                              // -----------------------------------------------------------
                                              // Auth Tab
                                              // -----------------------------------------------------------
                                              IndexedStack(
                                                index: authTypeIndex,
                                                children: [
                                                  // No Body
                                                  Center(
                                                    child: Text(
                                                      'No Auth',
                                                      style: TextStyle(color: Color(0xFF808080), fontSize: 16),
                                                    ),
                                                  ),
                                                  // API Key
                                                  AuthApiKeyForm(
                                                    controller: _formController.authApiKeyController,
                                                    keyFocusNode: _focusManager.authApiKeyKeyFocusNode,
                                                    valueFocusNode: _focusManager.authApiKeyValueFocusNode,
                                                    placementFocusNode: _focusManager.authApiKeyPlacementFocusNode,
                                                  ),
                                                  // Basic Auth
                                                  AuthBasicForm(
                                                    controller: _formController.authBasicController,
                                                    usernameFocusNode: _focusManager.authBasicUsernameFocusNode,
                                                    passwordFocusNode: _focusManager.authBasicPasswordFocusNode,
                                                  ),
                                                  // Bearer Token
                                                  AuthBearerForm(
                                                    controller: _formController.authBearerController,
                                                    tokenFocusNode: _focusManager.authBearerTokenFocusNode,
                                                  ),
                                                  // Digest
                                                  AuthNotImplemented(authType: 'Digest auth'),
                                                  // OAuth2
                                                  AuthNotImplemented(authType: 'OAuth2'),
                                                  // WSSE
                                                  AuthNotImplemented(authType: 'WSSE auth'),
                                                  // Inherit
                                                  AuthInherit(),
                                                ],
                                              ),
                                              // -----------------------------------------------------------
                                              // Variables Tab
                                              // -----------------------------------------------------------
                                              SingleChildScrollView(
                                                child: FormTable(
                                                  controller: _formController.varsController,
                                                  columns: [
                                                    FormTableColumn.enabled,
                                                    FormTableColumn.key,
                                                    FormTableColumn.value,
                                                    FormTableColumn.delete,
                                                  ],
                                                ),
                                              ),
                                              // -----------------------------------------------------------
                                              // Script Tab
                                              // -----------------------------------------------------------
                                              IndexedStack(
                                                index: _scriptTypeIndex,
                                                children: [
                                                  // Pre-Request Script
                                                  MultiLineCodeEditor(
                                                    focusNode: _focusManager.preRequestFocusNode,
                                                    border: tabContentBorder,
                                                    controller: _formController.preRequestController,
                                                  ),
                                                  // Post Response Scrip
                                                  MultiLineCodeEditor(
                                                    focusNode: _focusManager.postResponseFocusNode,
                                                    border: tabContentBorder,
                                                    controller: _formController.postResponseController,
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
                                              child: InlineTabBar(
                                                controller: _bottomTabController,
                                                tabTitles: _bottomTabTitles,
                                                tabTooltips: [
                                                  'Response Body',
                                                  'Response Headers',
                                                  'The console output from scripts',
                                                ],
                                                focusNode: _focusManager.topTabFocusNode,
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
                                                    openInterval: Interval(0.0, 0.0),
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
                                              readOnly: true,
                                            ),
                                            SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: HeadersTableReadOnly(headers: _respHeaders),
                                              ),
                                            ),
                                            MultiLineCodeEditor(
                                              focusNode: _focusManager.respOutputFocusNode,
                                              border: tabContentBorder,
                                              controller: _formController.respOutputController,
                                              readOnly: true,
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
