class Script {
  String? req;
  String? res;

  Script({this.req, this.res});

  bool equals(Script other) {
    return req == other.req && res == other.res;
  }

  bool isEmpty() {
    return (req == null || req!.isEmpty) && (res == null || res!.isEmpty);
  }

  Script deepCopy() {
    return Script(req: req, res: res);
  }
}
