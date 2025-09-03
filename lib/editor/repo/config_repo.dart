import 'dart:io';

import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/config.dart';

class ConfigRepo {
  final AppStorageI _appStorage;
  late final Config config;

  ConfigRepo(this._appStorage, List<String> commandLineArgs, Directory appSupportDir, Directory appDocsDir) {
    final isTest = (commandLineArgs.contains('--test'));
    final trayceApiUrl =
        (commandLineArgs.contains('--trayce-api-url'))
            ? commandLineArgs[commandLineArgs.indexOf('--trayce-api-url') + 1]
            : Config.defaultTrayceApiUrl;

    config = Config(
      isTest: isTest,
      trayceApiUrl: trayceApiUrl,
      appSupportDir: appSupportDir.path,
      appDocsDir: appDocsDir.path,
    );
  }

  Future<void> loadSettings() async {
    final npmCommand = await _appStorage.getConfigValue('npmCommand');
    final agentPort = await _appStorage.getConfigValue('agentPort');
    final codeCommand = await _appStorage.getConfigValue('codeCommand');

    if (npmCommand.isNotEmpty) config.npmCommand = npmCommand;
    if (agentPort.isNotEmpty) config.agentPort = int.parse(agentPort);
    if (codeCommand.isNotEmpty) config.codeCommand = codeCommand;
  }

  void save() async {
    await _appStorage.saveConfigValue('npmCommand', config.npmCommand);
    await _appStorage.saveConfigValue('agentPort', config.agentPort.toString());
    await _appStorage.saveConfigValue('codeCommand', config.codeCommand);
  }

  Config get() {
    return config;
  }
}
