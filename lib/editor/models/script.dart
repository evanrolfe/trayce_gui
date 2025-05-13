class Script {
  String? req;
  String? res;

  Script({this.req, this.res});

  bool equals(Script other) {
    return req == other.req && res == other.res;
  }
}
