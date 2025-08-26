import 'dart:io';

import 'package:path/path.dart' as path;

class Config {
  final bool isTest;
  final String trayceApiUrl;
  final String appSupportDir;
  final String appDocsDir;
  String npmCommand;
  int agentPort;

  static const defaultTrayceApiUrl = 'https://get.trayce.dev'; // no trailing slash
  static const defaultNpmCommand = 'npm';
  static const defaultAgentPort = 50052;

  Config({
    required this.isTest,
    required this.trayceApiUrl,
    required this.appSupportDir,
    required this.appDocsDir,
    this.npmCommand = defaultNpmCommand,
    this.agentPort = defaultAgentPort,
  });

  static Config fromArgs(List<String> args, Directory appSupportDir, Directory appDocsDir) {
    final isTest = (args.contains('--test'));
    final trayceApiUrl =
        (args.contains('--trayce-api-url')) ? args[args.indexOf('--trayce-api-url') + 1] : defaultTrayceApiUrl;

    return Config(
      isTest: isTest,
      trayceApiUrl: trayceApiUrl,
      appSupportDir: appSupportDir.path,
      appDocsDir: appDocsDir.path,
    );
  }

  String nodeJsDir() {
    return path.join(appSupportDir, 'nodejs');
  }
}
