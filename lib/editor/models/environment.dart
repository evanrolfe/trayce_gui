import 'dart:io';

import 'package:path/path.dart' as path;

import 'request.dart';
import 'utils.dart';
import 'variable.dart';

class Environment {
  // file properties:
  File file;

  // .bru properties:
  List<Variable> vars;

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

  static Environment blank(String collectionPath) {
    final envsDir = Directory(path.join(collectionPath, 'environments'));

    // Create a new environment file
    final envFileName = 'untitled.bru';
    final envFile = File(path.join(envsDir.path, envFileName));

    return Environment(file: envFile, vars: []);
  }
}
