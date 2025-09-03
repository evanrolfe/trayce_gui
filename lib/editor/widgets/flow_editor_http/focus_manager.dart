import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

enum TableForm { queryParams, pathParams, requestVars, responseVars, runtimeVars, files, headers, multipart }

class EditorFocusManager {
  late final FocusNode editorFocusNode;
  late final FocusNode methodFocusNode;
  late final FocusNode bodyTypeFocusNode;
  late final FocusNode authTypeFocusNode;
  late final FocusNode formatFocusNode;
  late final FocusNode topTabFocusNode;
  late final FocusNode urlFocusNode;
  late final FocusNode checkboxFocusNode;
  late final FocusNode reqBodyFocusNode;
  late final FocusNode respBodyFocusNode;
  late final FocusNode respOutputFocusNode;
  late final FocusNode preRequestFocusNode;
  late final FocusNode postResponseFocusNode;
  late final Map<TableForm, List<Map<String, FocusNode>>> _rowFocusNodes;
  late final List<Map<String, FocusNode>> _pathParamsRowFocusNodes;

  late final FocusNode authApiKeyKeyFocusNode;
  late final FocusNode authApiKeyValueFocusNode;
  late final FocusNode authApiKeyPlacementFocusNode;
  late final FocusNode authBasicUsernameFocusNode;
  late final FocusNode authBasicPasswordFocusNode;
  late final FocusNode authBearerTokenFocusNode;

  final EventBus _eventBus;
  final ValueKey tabKey;

  EditorFocusManager(this._eventBus, this.tabKey) {
    editorFocusNode = FocusNode();
    methodFocusNode = FocusNode();
    bodyTypeFocusNode = FocusNode();
    authTypeFocusNode = FocusNode();
    formatFocusNode = FocusNode();
    topTabFocusNode = FocusNode();
    urlFocusNode = FocusNode();
    checkboxFocusNode = FocusNode();
    reqBodyFocusNode = FocusNode();
    respBodyFocusNode = FocusNode();
    respOutputFocusNode = FocusNode();
    preRequestFocusNode = FocusNode();
    postResponseFocusNode = FocusNode();
    _rowFocusNodes = {
      TableForm.queryParams: [],
      TableForm.pathParams: [],
      TableForm.requestVars: [],
      TableForm.responseVars: [],
      TableForm.runtimeVars: [],
      TableForm.files: [],
      TableForm.headers: [],
      TableForm.multipart: [],
    };
    _pathParamsRowFocusNodes = [];

    authApiKeyKeyFocusNode = FocusNode();
    authApiKeyValueFocusNode = FocusNode();
    authApiKeyPlacementFocusNode = FocusNode();
    authBasicUsernameFocusNode = FocusNode();
    authBasicPasswordFocusNode = FocusNode();
    authBearerTokenFocusNode = FocusNode();

    editorFocusNode.onKeyEvent = _onKeyUp;
    methodFocusNode.onKeyEvent = _onKeyUp;
    bodyTypeFocusNode.onKeyEvent = _onKeyUp;
    authTypeFocusNode.onKeyEvent = _onKeyUp;
    formatFocusNode.onKeyEvent = _onKeyUp;
    topTabFocusNode.onKeyEvent = _onKeyUp;
    urlFocusNode.onKeyEvent = _onKeyUp;
    checkboxFocusNode.onKeyEvent = _onKeyUp;
    reqBodyFocusNode.onKeyEvent = _onKeyUpMultiLine;
    respBodyFocusNode.onKeyEvent = _onKeyUpMultiLine;
    preRequestFocusNode.onKeyEvent = _onKeyUpMultiLine;
    respOutputFocusNode.onKeyEvent = _onKeyUpMultiLine;
    postResponseFocusNode.onKeyEvent = _onKeyUpMultiLine;
    authApiKeyKeyFocusNode.onKeyEvent = _onKeyUpAuthApiKeyKey;
    authApiKeyValueFocusNode.onKeyEvent = _onKeyUpAuthApiKeyValue;
    authApiKeyPlacementFocusNode.onKeyEvent = _onKeyUp;
    authBasicUsernameFocusNode.onKeyEvent = _onKeyUpAuthBasicUsername;
    authBasicPasswordFocusNode.onKeyEvent = _onKeyUpAuthBasicPassword;
    authBearerTokenFocusNode.onKeyEvent = _onKeyUp;

    // Add listener to transfer focus when method dropdown loses focus
    methodFocusNode.addListener(() {
      if (!methodFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
    bodyTypeFocusNode.addListener(() {
      if (!bodyTypeFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
    authTypeFocusNode.addListener(() {
      if (!authTypeFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
    formatFocusNode.addListener(() {
      if (!formatFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
    checkboxFocusNode.addListener(() {
      if (!checkboxFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
  }

  Map<String, FocusNode> getRowFocusNodes(TableForm tableForm, int index) {
    final nodes = _rowFocusNodes[tableForm];
    if (nodes == null) return {};

    return nodes[index];
  }

  Map<String, FocusNode> getPathParamsRowFocusNodes(int index) {
    return _pathParamsRowFocusNodes[index];
  }

  Map<String, FocusNode> createRowFocusNodes(TableForm tableForm) {
    final rowFocusNodes = {'key': FocusNode(), 'value': FocusNode(), 'contentType': FocusNode()};

    final index = _rowFocusNodes[tableForm]!.length;

    rowFocusNodes['key']!.onKeyEvent = (node, event) => _onKeyUpRow(event, tableForm, index, 'key');
    rowFocusNodes['value']!.onKeyEvent = (node, event) => _onKeyUpRow(event, tableForm, index, 'value');
    rowFocusNodes['contentType']!.onKeyEvent = (node, event) => _onKeyUpRow(event, tableForm, index, 'contentType');

    _rowFocusNodes[tableForm]!.add(rowFocusNodes);
    return rowFocusNodes;
  }

  KeyEventResult _onKeyUpAuthApiKeyKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      authApiKeyValueFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    return _onKeyUp(node, event);
  }

  KeyEventResult _onKeyUpAuthApiKeyValue(FocusNode node, KeyEvent event) {
    return _onKeyUp(node, event);
  }

  KeyEventResult _onKeyUpAuthBasicUsername(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      authBasicPasswordFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    return _onKeyUp(node, event);
  }

  KeyEventResult _onKeyUpAuthBasicPassword(FocusNode node, KeyEvent event) {
    return _onKeyUp(node, event);
  }

  KeyEventResult _onKeyUp(FocusNode node, KeyEvent event) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
        _eventBus.fire(EventSaveIntent(tabKey));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN && isCmdPressed) {
        _eventBus.fire(EventNewRequest());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW && isCmdPressed) {
        _eventBus.fire(EventCloseCurrentNode());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _eventBus.fire(EventSendRequest(tabKey));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // _onKeyUpMultiLine is the same as _onKeyUp but it doesnt send the request when you hit enter
  KeyEventResult _onKeyUpMultiLine(FocusNode node, KeyEvent event) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
        _eventBus.fire(EventSaveIntent(tabKey));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN && isCmdPressed) {
        _eventBus.fire(EventNewRequest());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW && isCmdPressed) {
        _eventBus.fire(EventCloseCurrentNode());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onKeyUpRow(KeyEvent event, TableForm formType, int index, String nodeKey) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

    if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
      _eventBus.fire(EventSaveIntent(tabKey));
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      handleTabPress(formType, index, nodeKey);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void handleTabPress(TableForm formType, int index, String nodeKey) {
    final nodes = _rowFocusNodes[formType];
    if (nodes == null) return;

    if (nodeKey == 'key') {
      nodes[index]['value']!.requestFocus();
    } else if (nodeKey == 'value') {
      nodes[index + 1]['key']!.requestFocus();
    } else if (nodeKey == 'contentType') {
      nodes[index + 1]['key']!.requestFocus();
    }
  }

  void dispose() {
    editorFocusNode.dispose();
    methodFocusNode.dispose();
    bodyTypeFocusNode.dispose();
    authTypeFocusNode.dispose();
    formatFocusNode.dispose();
    topTabFocusNode.dispose();
    urlFocusNode.dispose();
    checkboxFocusNode.dispose();
    reqBodyFocusNode.dispose();
    respBodyFocusNode.dispose();
    respOutputFocusNode.dispose();
    preRequestFocusNode.dispose();
    postResponseFocusNode.dispose();
    authApiKeyKeyFocusNode.dispose();
    authApiKeyValueFocusNode.dispose();
    authApiKeyPlacementFocusNode.dispose();
    authBasicUsernameFocusNode.dispose();
    authBasicPasswordFocusNode.dispose();
    authBearerTokenFocusNode.dispose();
  }
}
