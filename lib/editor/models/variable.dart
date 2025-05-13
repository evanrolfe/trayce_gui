class Variable {
  String name;
  String? value;
  bool enabled;
  bool secret;
  bool local;

  Variable({required this.name, required this.value, required this.enabled, this.secret = false, this.local = false});

  bool equals(Variable other) {
    return name == other.name &&
        value == other.value &&
        enabled == other.enabled &&
        secret == other.secret &&
        local == other.local;
  }
}
