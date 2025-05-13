class Assertion {
  String name;
  String value;
  bool enabled;

  Assertion({required this.name, required this.value, required this.enabled});

  bool equals(Assertion other) {
    return name == other.name && value == other.value && enabled == other.enabled;
  }
}
