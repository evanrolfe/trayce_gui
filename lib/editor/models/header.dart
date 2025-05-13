class Header {
  String name;
  String value;
  bool enabled;

  Header({required this.name, required this.value, required this.enabled});

  bool equals(Header other) {
    return name == other.name && value == other.value && enabled == other.enabled;
  }
}
