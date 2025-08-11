import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

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
  late final FocusNode preRequestFocusNode;
  late final FocusNode postResponseFocusNode;
  late final List<Map<String, FocusNode>> _rowFocusNodes;
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
    preRequestFocusNode = FocusNode();
    postResponseFocusNode = FocusNode();
    _rowFocusNodes = [];
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

  Map<String, FocusNode> getRowFocusNodes(int index) {
    return _rowFocusNodes[index];
  }

  Map<String, FocusNode> getPathParamsRowFocusNodes(int index) {
    return _pathParamsRowFocusNodes[index];
  }

  Map<String, FocusNode> createRowFocusNodes() {
    final rowFocusNodes = {'key': FocusNode(), 'value': FocusNode(), 'contentType': FocusNode()};

    final index = _rowFocusNodes.length;

    rowFocusNodes['key']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'key');
    rowFocusNodes['value']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'value');
    rowFocusNodes['contentType']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'contentType');

    _rowFocusNodes.add(rowFocusNodes);
    return rowFocusNodes;
  }

  Map<String, FocusNode> createRowFocusNodesForPathParams() {
    final rowFocusNodes = {'key': FocusNode(), 'value': FocusNode(), 'contentType': FocusNode()};

    final index = _rowFocusNodes.length;

    rowFocusNodes['key']!.onKeyEvent = (node, event) => _onKeyUpRowPathParams(event, index, 'key');
    rowFocusNodes['value']!.onKeyEvent = (node, event) => _onKeyUpRowPathParams(event, index, 'value');
    rowFocusNodes['contentType']!.onKeyEvent = (node, event) => _onKeyUpRowPathParams(event, index, 'contentType');

    _pathParamsRowFocusNodes.add(rowFocusNodes);
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

  KeyEventResult _onKeyUpRow(KeyEvent event, int index, String nodeKey) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

    if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
      _eventBus.fire(EventSaveIntent(tabKey));
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      handleTabPress(index, nodeKey);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void handleTabPress(int index, String nodeKey) {
    if (nodeKey == 'key') {
      _rowFocusNodes[index]['value']!.requestFocus();
    } else if (nodeKey == 'value') {
      _rowFocusNodes[index + 1]['key']!.requestFocus();
    } else if (nodeKey == 'contentType') {
      _rowFocusNodes[index + 1]['key']!.requestFocus();
    }
  }

  KeyEventResult _onKeyUpRowPathParams(KeyEvent event, int index, String nodeKey) {
    final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

    if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
      _eventBus.fire(EventSaveIntent(tabKey));
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      handleTabPressPathParams(index, nodeKey);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void handleTabPressPathParams(int index, String nodeKey) {
    // TODO: Make this work
    // print('handleTabPressPathParams length: ${_pathParamsRowFocusNodes.length}, currentIndex: $index');
    // if (nodeKey == 'value') {
    //   _pathParamsRowFocusNodes[index + 1]['value']!.requestFocus();
    // }
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
