class EventDisplayAlert {
  final String message;

  EventDisplayAlert(this.message);
}

class EventEditorNodeModified {
  final String nodePath;
  final bool isDifferent;

  EventEditorNodeModified(this.nodePath, this.isDifferent);
}
