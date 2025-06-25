import 'package:flutter/widgets.dart';

class HttpFocusManager {
  late final FocusNode editorFocusNode;
  late final FocusNode methodFocusNode;
  late final FocusNode bodyTypeFocusNode;
  late final FocusNode formatFocusNode;
  late final FocusNode topTabFocusNode;
  late final FocusNode urlFocusNode;
  late final FocusNode checkboxFocusNode;
  late final KeyEventResult Function(FocusNode node, KeyEvent event) onKeyUp;

  HttpFocusManager(this.onKeyUp) {
    editorFocusNode = FocusNode();
    methodFocusNode = FocusNode();
    bodyTypeFocusNode = FocusNode();
    formatFocusNode = FocusNode();
    topTabFocusNode = FocusNode();
    urlFocusNode = FocusNode();
    checkboxFocusNode = FocusNode();

    editorFocusNode.onKeyEvent = onKeyUp;
    methodFocusNode.onKeyEvent = onKeyUp;
    bodyTypeFocusNode.onKeyEvent = onKeyUp;
    formatFocusNode.onKeyEvent = onKeyUp;
    topTabFocusNode.onKeyEvent = onKeyUp;
    checkboxFocusNode.onKeyEvent = onKeyUp;

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
      print('checkboxFocusNode focus: ${checkboxFocusNode.hasFocus}');
      if (!checkboxFocusNode.hasFocus) {
        editorFocusNode.requestFocus();
      }
    });
  }

  void dispose() {
    editorFocusNode.dispose();
    methodFocusNode.dispose();
    bodyTypeFocusNode.dispose();
    formatFocusNode.dispose();
    topTabFocusNode.dispose();
    urlFocusNode.dispose();
    checkboxFocusNode.dispose();
  }
}
