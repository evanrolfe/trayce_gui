import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

class EventDisplayAlert {
  final String message;

  EventDisplayAlert(this.message);
}

class EventEditorNodeModified {
  final ValueKey tabKey;
  final bool isDifferent;

  EventEditorNodeModified(this.tabKey, this.isDifferent);
}

class EditorSelectionChanged {
  final CodeLineEditingController controller;

  EditorSelectionChanged(this.controller);
}
