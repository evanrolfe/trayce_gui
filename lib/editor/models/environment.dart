import 'dart:io';

import 'request.dart';
import 'utils.dart';
import 'variable.dart';

class Environment {
  List<Variable> vars;
  File file;

  Environment({required this.vars, required this.file});

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

  String fileName() {
    final fileName = file.path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  void save() {
    final bruStr = toBru();
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);
  }
}
