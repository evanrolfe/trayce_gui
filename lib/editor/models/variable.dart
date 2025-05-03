class Variable {
  String name;
  String? value;
  bool enabled;
  bool secret;
  bool local;

  Variable({
    required this.name,
    required this.value,
    required this.enabled,
    this.secret = false,
    this.local = false,
  });
}
