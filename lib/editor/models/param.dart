class Param {
  String name;
  String value;
  String type;
  bool enabled;

  Param({required this.name, required this.value, required this.type, required this.enabled});

  bool equals(Param other) {
    return name == other.name && value == other.value && type == other.type && enabled == other.enabled;
  }
}
