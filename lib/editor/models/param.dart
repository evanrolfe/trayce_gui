enum ParamType { query, path, form }

class Param {
  String name;
  String value;
  ParamType type;
  bool enabled;

  Param({required this.name, required this.value, required this.type, required this.enabled});

  bool equals(Param other) {
    return name == other.name && value == other.value && type == other.type && enabled == other.enabled;
  }
}

compareParams(List<Param> a, List<Param> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    final aParam = a[i];
    final bParam = b[i];
    if (aParam.enabled != bParam.enabled || aParam.name != bParam.name || aParam.value != bParam.value) {
      return false;
    }
  }
  return true;
}
