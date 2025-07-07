import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/common/form_table_state.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

class FormController {
  static const List<String> bodyTypeOptions = [
    'No Body',
    'Text',
    'JSON',
    'XML',
    'Form URL Encoded',
    'Multipart Form',
    'Files',
  ];

  late String selectedMethod;
  late String selectedBodyType;

  final CodeLineEditingController urlController = CodeLineEditingController();
  final CodeLineEditingController reqBodyController = CodeLineEditingController();
  final CodeLineEditingController respBodyController = CodeLineEditingController();

  late final FormTableStateManager headersController;
  late final FormTableStateManager varsController;
  late final FormTableStateManager formUrlEncodedController;
  late final FormTableStateManager multipartFormController;
  late final FormTableStateManager fileController;

  final EditorFocusManager _focusManager;
  final EventBus eventBus;
  final Config config;

  final Function() setState;

  // _formRequest is the request as it currently exists in the editor
  late final Request _formRequest;
  // _widgetRequest is the request as it exists in the widget (and on file)
  late final Request _widgetRequest;
  // _tabKey is the tab key of this editor tab, and it used in sending events back to the tabbar so it knows which tab the events relate to
  final ValueKey _tabKey;

  FormController(
    this._formRequest,
    this._widgetRequest,
    this.eventBus,
    this._tabKey,
    this.config,
    this.setState,
    this._focusManager,
  ) {
    selectedMethod = _formRequest.method.toUpperCase();

    // URL
    urlController.text = _formRequest.url;
    urlController.addListener(_urlModified);

    // Body
    final body = _formRequest.getBody();
    if (body != null) {
      reqBodyController.text = body.toString();
    }
    reqBodyController.addListener(_reqBodyModified);

    // Body Type
    switch (_formRequest.bodyType) {
      case BodyType.text:
        selectedBodyType = bodyTypeOptions[1];
      case BodyType.json:
        selectedBodyType = bodyTypeOptions[2];
      case BodyType.xml:
        selectedBodyType = bodyTypeOptions[3];
      case BodyType.formUrlEncoded:
        selectedBodyType = bodyTypeOptions[4];
      case BodyType.multipartForm:
        selectedBodyType = bodyTypeOptions[5];
      case BodyType.file:
        selectedBodyType = bodyTypeOptions[6];
      default:
        selectedBodyType = bodyTypeOptions[0];
    }

    // Headers
    headersController = FormTableStateManager(
      onStateChanged: setState,
      initialRows: _formRequest.headers,
      onModified: _headersModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
    );

    // Vars
    varsController = FormTableStateManager(
      onStateChanged: setState,
      initialRows: [],
      onModified: _varsModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
    );

    // Form URL Encoded
    // Convert the params to Headers for the FormTableStateManager
    List<Header> paramsForManager = [];
    if (_formRequest.bodyFormUrlEncoded != null) {
      final params = (_formRequest.bodyFormUrlEncoded as FormUrlEncodedBody).params;
      paramsForManager = params.map((p) => Header(name: p.name, value: p.value, enabled: p.enabled)).toList();
    }
    formUrlEncodedController = FormTableStateManager(
      onStateChanged: setState,
      initialRows: paramsForManager,
      onModified: _formUrlEncodedModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
    );

    // Multipart Form
    // Set the multi part files on the FormTableStateManager
    multipartFormController = FormTableStateManager(
      onStateChanged: setState,
      initialRows: [],
      onModified: _multipartFormModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
    );

    if (_formRequest.bodyMultipartForm != null) {
      final filesForManager = (_formRequest.bodyMultipartForm as MultipartFormBody).files;
      multipartFormController.setMultipartFiles(filesForManager);
    }

    // File
    fileController = FormTableStateManager(
      onStateChanged: setState,
      initialRows: [],
      onModified: _fileModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
    );

    if (_formRequest.bodyFile != null) {
      final filesForManager = (_formRequest.bodyFile as FileBody).files;
      fileController.setFiles(filesForManager);
    }
  }

  void _urlModified() {
    _formRequest.setUrl(urlController.text);
    _flowModified();
  }

  void setMethod(String method) {
    selectedMethod = method;
    _formRequest.setMethod(selectedMethod.toLowerCase());
    _flowModified();
  }

  void _reqBodyModified() {
    final bodyContent = reqBodyController.text;
    if (bodyContent == _formRequest.getBody()?.toString()) return;
    _formRequest.setBodyContent(bodyContent);
    _flowModified();
  }

  void setBodyType(String? newValue) {
    if (newValue == null) return;

    reqBodyController.removeListener(_reqBodyModified);

    if (newValue == bodyTypeOptions[0]) {
      reqBodyController.text = '';
      _formRequest.setBodyType(BodyType.none);
    } else if (newValue == bodyTypeOptions[1]) {
      reqBodyController.text = _formRequest.bodyText?.toString() ?? '';
      _formRequest.setBodyType(BodyType.text);
    } else if (newValue == bodyTypeOptions[2]) {
      reqBodyController.text = _formRequest.bodyJson?.toString() ?? '';
      _formRequest.setBodyType(BodyType.json);
    } else if (newValue == bodyTypeOptions[3]) {
      reqBodyController.text = _formRequest.bodyXml?.toString() ?? '';
      _formRequest.setBodyType(BodyType.xml);
    } else if (newValue == bodyTypeOptions[4]) {
      _formRequest.setBodyType(BodyType.formUrlEncoded);
    } else if (newValue == bodyTypeOptions[5]) {
      _formRequest.setBodyType(BodyType.multipartForm);
    } else if (newValue == bodyTypeOptions[6]) {
      _formRequest.setBodyType(BodyType.file);
    }

    setState();
    selectedBodyType = newValue;

    reqBodyController.addListener(_reqBodyModified);

    _flowModified();
  }

  void _headersModified() {
    _formRequest.setHeaders(headersController.getHeaders());
    _flowModified();
  }

  void _varsModified() {
    print('varsModified');
  }

  void _formUrlEncodedModified() {
    final params = formUrlEncodedController.getParams();
    _formRequest.setBodyFormURLEncodedContent(params);
    _flowModified();
  }

  void _multipartFormModified() {
    final files = multipartFormController.getMultipartFiles();
    _formRequest.setBodyMultipartFormContent(files);
    _flowModified();
  }

  void _fileModified() {
    final files = fileController.getFiles();
    _formRequest.setBodyFilesContent(files);
    _flowModified();
  }

  void _flowModified() {
    final isDifferent = !_formRequest.equals(_widgetRequest);

    eventBus.fire(EventEditorNodeModified(_tabKey, isDifferent));
  }

  void dispose() {
    urlController.removeListener(_urlModified);
    reqBodyController.removeListener(_reqBodyModified);

    urlController.dispose();
    reqBodyController.dispose();
    respBodyController.dispose();
    headersController.dispose();
    formUrlEncodedController.dispose();
    multipartFormController.dispose();
    fileController.dispose();
  }
}
