import 'request.dart';
import 'utils.dart';
import 'variable.dart';

class Environment {
  List<Variable> vars;

  Environment({required this.vars});

  String toBru() {
    var bru = '';

    // Convert variables to bru
    final openVars = vars.where((v) => !v.secret).toList();
    if (openVars.isNotEmpty) {
      bru += '${variablesToBru(openVars, 'vars')}\n';
    }

    // Convert secrets to bru
    final secretsVars = vars.where((v) => v.secret).toList();
    if (secretsVars.isNotEmpty) {
      bru += '\nvars:secret [\n';
      for (var i = 0; i < secretsVars.length; i++) {
        final v = secretsVars[i];
        final isLast = i == secretsVars.length - 1;
        bru += '${indentString(v.name)}${isLast ? '' : ','}\n';
      }
      bru += ']\n';
    }

    return bru;
  }
}
