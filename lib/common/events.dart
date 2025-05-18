import 'package:flutter/foundation.dart';

class EventDisplayAlert {
  final String message;

  EventDisplayAlert(this.message);
}

class EventEditorNodeModified {
  final ValueKey tabKey;
  final bool isDifferent;

  EventEditorNodeModified(this.tabKey, this.isDifferent);
}
