import 'variable.dart';

class GlobalEnvironment {
  String name;

  List<Variable> vars;

  GlobalEnvironment({required this.name, required this.vars});

  Map<String, String> toMap() {
    final output = <String, String>{};
    for (final varr in vars) {
      output[varr.name] = varr.value ?? '';
    }
    return output;
  }

  static GlobalEnvironment fromMap(String name, Map<String, dynamic> map) {
    final vars = <Variable>[];
    for (final varr in map.entries) {
      vars.add(Variable(name: varr.key, value: varr.value, enabled: true));
    }

    return GlobalEnvironment(name: name, vars: vars);
  }
}
