import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:trayce/editor/models/variable.dart';

class EventRuntimeVarsChanged {}

class RuntimeVarsRepo {
  List<Variable> vars;
  final EventBus _eventBus;

  RuntimeVarsRepo({List<Variable>? vars, required EventBus eventBus}) : vars = vars ?? [], _eventBus = eventBus;

  void clearVars() {
    vars = <Variable>[];
    _eventBus.fire(EventRuntimeVarsChanged());
  }

  void setVar(String name, String value) {
    final varr = getVar(name);
    if (varr != null) {
      varr.value = value;
      return;
    }

    vars.add(Variable(name: name, value: value, enabled: true));
    _eventBus.fire(EventRuntimeVarsChanged());
  }

  Variable? getVar(String name) {
    return vars.firstWhereOrNull((varr) => varr.name == name);
  }

  List<Map<String, dynamic>> toMapList() {
    return vars.map((varr) => {'name': varr.name, 'value': varr.value}).toList();
  }
}
