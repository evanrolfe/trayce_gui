import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:trayce/editor/widgets/explorer/explorer.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

class EditorFocusManager {
  late final FocusNode editorFocusNode;
  late final FocusNode methodFocusNode;
  late final FocusNode bodyTypeFocusNode;
  late final FocusNode formatFocusNode;
  late final FocusNode topTabFocusNode;
  late final FocusNode urlFocusNode;
  late final FocusNode checkboxFocusNode;
  late final FocusNode reqBodyFocusNode;
  late final FocusNode respBodyFocusNode;
  late final List<Map<String, FocusNode>> _rowFocusNodes;

  final EventBus _eventBus;
  final ValueKey tabKey;

  EditorFocusManager(this._eventBus, this.tabKey) {
    editorFocusNode = FocusNode();
    methodFocusNode = FocusNode();
    bodyTypeFocusNode = FocusNode();
    formatFocusNode = FocusNode();
    topTabFocusNode = FocusNode();
    urlFocusNode = FocusNode();
    checkboxFocusNode = FocusNode();
    reqBodyFocusNode = FocusNode();
    respBodyFocusNode = FocusNode();
    _rowFocusNodes = [];

    editorFocusNode.onKeyEvent = _onKeyUp;
    methodFocusNode.onKeyEvent = _onKeyUp;
    bodyTypeFocusNode.onKeyEvent = _onKeyUp;
    formatFocusNode.onKeyEvent = _onKeyUp;
    topTabFocusNode.onKeyEvent = _onKeyUp;
    urlFocusNode.onKeyEvent = _onKeyUp;
    checkboxFocusNode.onKeyEvent = _onKeyUp;
    reqBodyFocusNode.onKeyEvent = _onKeyUp;
    respBodyFocusNode.onKeyEvent = _onKeyUp;

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

  Map<String, FocusNode> createRowFocusNodes() {
    final rowFocusNodes = {'key': FocusNode(), 'value': FocusNode(), 'contentType': FocusNode()};

    final index = _rowFocusNodes.length;

    rowFocusNodes['key']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'key');
    rowFocusNodes['value']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'value');
    rowFocusNodes['contentType']!.onKeyEvent = (node, event) => _onKeyUpRow(event, index, 'contentType');

    _rowFocusNodes.add(rowFocusNodes);
    return rowFocusNodes;
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

  void dispose() {
    editorFocusNode.dispose();
    methodFocusNode.dispose();
    bodyTypeFocusNode.dispose();
    formatFocusNode.dispose();
    topTabFocusNode.dispose();
    urlFocusNode.dispose();
    checkboxFocusNode.dispose();
    reqBodyFocusNode.dispose();
    respBodyFocusNode.dispose();
  }
}
