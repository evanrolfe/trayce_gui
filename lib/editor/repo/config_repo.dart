import 'dart:io';

import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/config.dart';

class ConfigRepo {
  final AppStorageI _appStorage;
  late final Config config;

  ConfigRepo(this._appStorage, List<String> commandLineArgs, Directory appSupportDir) {
    final isTest = (commandLineArgs.contains('--test'));
    final trayceApiUrl =
        (commandLineArgs.contains('--trayce-api-url'))
            ? commandLineArgs[commandLineArgs.indexOf('--trayce-api-url') + 1]
            : Config.defaultTrayceApiUrl;

    config = Config(isTest: isTest, trayceApiUrl: trayceApiUrl, appSupportDir: appSupportDir.path);
  }

  Config get() {
    return config;
  }
}
