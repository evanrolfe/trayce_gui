import 'package:collection/collection.dart';
import 'package:trayce/editor/models/variable.dart';

class RuntimeVarsRepo {
  List<Variable> vars;

  RuntimeVarsRepo({this.vars = const []});

  void clearVars() {
    vars = [];
  }

  void setVar(String name, String value) {
    final varr = getVar(name);
    if (varr != null) {
      varr.value = value;
      return;
    }

    vars.add(Variable(name: name, value: value, enabled: true));
  }

  Variable? getVar(String name) {
    return vars.firstWhereOrNull((varr) => varr.name == name);
  }

  List<Map<String, dynamic>> toMapList() {
    return vars.map((varr) => {'name': varr.name, 'value': varr.value}).toList();
  }
}
