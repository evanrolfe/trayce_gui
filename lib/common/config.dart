import 'dart:io';

import 'package:path/path.dart' as path;

class Config {
  final bool isTest;
  final String trayceApiUrl;
  final String appSupportDir;
  String npmCommand;

  static const defaultTrayceApiUrl = 'https://get.trayce.dev'; // no trailing slash
  static const defaultNpmCommand = 'npm';

  Config({
    required this.isTest,
    required this.trayceApiUrl,
    required this.appSupportDir,
    this.npmCommand = defaultNpmCommand,
  });

  static Config fromArgs(List<String> args, Directory appSupportDir) {
    final isTest = (args.contains('--test'));
    final trayceApiUrl =
        (args.contains('--trayce-api-url')) ? args[args.indexOf('--trayce-api-url') + 1] : defaultTrayceApiUrl;

    return Config(
      isTest: isTest,
      trayceApiUrl: trayceApiUrl,
      appSupportDir: appSupportDir.path,
      npmCommand: defaultNpmCommand,
    );
  }

  String nodeJsDir() {
    return path.join(appSupportDir, 'nodejs');
  }
}
