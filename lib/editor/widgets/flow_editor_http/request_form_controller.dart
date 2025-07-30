import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_files_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_headers_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_multipart_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_params_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/path_params_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/query_params_controller.dart';

class RequestFormController {
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

  late final FormHeadersController headersController;
  late final QueryParamsController queryParamsController;
  late final PathParamsController pathParamsController;
  late final FormVarsController varsController;
  late final FormParamsController formUrlEncodedController;
  late final FormMultipartController multipartFormController;
  late final FormFilesController fileController;

  final EditorFocusManager _focusManager;
  final EventBus eventBus;
  final Config config;
  final FilePickerI filePicker;

  final Function() setState;

  // _formRequest is the request as it currently exists in the editor
  late final Request _formRequest;
  // _widgetRequest is the request as it exists in the widget (and on file)
  late final Request _widgetRequest;
  // _tabKey is the tab key of this editor tab, and it used in sending events back to the tabbar so it knows which tab the events relate to
  final ValueKey _tabKey;

  RequestFormController(
    this._formRequest,
    this._widgetRequest,
    this.eventBus,
    this._tabKey,
    this.config,
    this.filePicker,
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

    // Query Params
    queryParamsController = QueryParamsController(
      onStateChanged: setState,
      initialRows: _formRequest.getQueryParamsFromURL(),
      urlController: urlController,
      onModified: _queryParamsTableModified,
      config: config,
      focusManager: _focusManager,
    );

    // Path Params
    pathParamsController = PathParamsController(
      onStateChanged: setState,
      initialRows: _formRequest.getPathParams(),
      onModified: _pathParamsTableModified,
      config: config,
      focusManager: _focusManager,
    );

    // Headers
    headersController = FormHeadersController(
      onStateChanged: setState,
      initialRows: _formRequest.headers,
      onModified: _headersModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );

    // Vars
    varsController = FormVarsController(
      onStateChanged: setState,
      onModified: _varsModified,
      initialRows: _formRequest.requestVars,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );

    // Form URL Encoded
    // Convert the params to Headers for the FormTableStateManager
    List<Param> params = [];
    if (_formRequest.bodyFormUrlEncoded != null) {
      params = (_formRequest.bodyFormUrlEncoded as FormUrlEncodedBody).params;
    }
    formUrlEncodedController = FormParamsController(
      onStateChanged: setState,
      initialRows: params,
      onModified: _formUrlEncodedModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );

    // Multipart Form
    // Set the multi part files on the FormTableStateManager
    List<MultipartFile> files = [];
    if (_formRequest.bodyMultipartForm != null) {
      files = (_formRequest.bodyMultipartForm as MultipartFormBody).files;
    }
    multipartFormController = FormMultipartController(
      onStateChanged: setState,
      initialRows: files,
      onModified: _multipartFormModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );

    // File
    List<FileBodyItem> fileItems = [];
    if (_formRequest.bodyFile != null) {
      fileItems = (_formRequest.bodyFile as FileBody).files;
    }
    fileController = FormFilesController(
      onStateChanged: setState,
      initialRows: fileItems,
      onModified: _fileModified,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );
  }

  void _urlModified() {
    final url = urlController.text;
    if (url == _formRequest.url) return;

    _formRequest.setUrl(url);

    final pathParams = _formRequest.getPathParamsFromURL();
    pathParamsController.setParams(pathParams);

    if (!compareParams(queryParamsController.getParams(), _formRequest.getQueryParamsFromURL())) {
      final params = _formRequest.getQueryParamsFromURL();
      queryParamsController.mergeParams(params);

      _formRequest.params = params;
    }

    _flowModified();
  }

  void _queryParamsTableModified() {
    if (compareParams(queryParamsController.getParams(), _formRequest.getQueryParamsFromURL())) return;

    final params = queryParamsController.getParams();
    _formRequest.setQueryParamsOnURL(params);
    _formRequest.setQueryParams(params);

    urlController.removeListener(_urlModified);
    urlController.text = _formRequest.url;
    urlController.addListener(_urlModified);

    _flowModified();
  }

  void _pathParamsTableModified() {
    final params = pathParamsController.getParams();
    _formRequest.setPathParams(params);
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
    _formRequest.setRequestVars(varsController.getVars());
    _flowModified();
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
