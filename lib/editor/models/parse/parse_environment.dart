import 'dart:io';

import '../environment.dart';
import '../variable.dart';
import 'grammar_environment.dart';

Environment parseEnvironmentFile(File envFile) {
  final envBru = envFile.readAsStringSync();
  return parseEnvironment(envBru, envFile);
}

Environment parseEnvironment(String envBru, File envFile) {
  final bruParser = BruEnvironmentGrammar().build();
  final result = bruParser.parse(envBru.trim());

  if (!result.isSuccess) {
    throw Exception(result.message);
  }

  List<Variable> envVars = [];
  List<Variable> envSecrets = [];

  // Parse variables
  if (result.value['vars'] != null) {
    final vars = result.value['vars'] as Map<String, dynamic>;

    for (final entry in vars.entries) {
      String name = entry.key;
      bool enabled = true;

      if (name.startsWith('~')) {
        name = name.substring(1); // Remove the ~ prefix
        enabled = false;
      }

      envVars.add(Variable(name: name, value: entry.value, enabled: enabled));
    }
  }

  // Parse secrets
  if (result.value['secrets'] != null && result.value['secrets']['values'] != null) {
    final secretVars = result.value['secrets']['values'] as List<dynamic>;

    for (final secret in secretVars) {
      if (secret == null || secret == "") {
        continue;
      }

      String name = secret;
      bool enabled = true;

      if (name.startsWith('~')) {
        name = name.substring(1); // Remove the ~ prefix
        enabled = false;
      }

      envSecrets.add(Variable(name: name, value: null, enabled: enabled, secret: true));
    }
  }

  return Environment(vars: envVars + envSecrets, file: envFile);
}
