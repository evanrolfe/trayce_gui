import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';

class EnvironmentRepo {
  final AppStorageI _appStorage;

  EnvironmentRepo(this._appStorage);

  void save(Collection collection, Environment environment) {
    final envPath = path.join(collection.dir.path, 'environments');
    final envDir = Directory(envPath);
    if (!envDir.existsSync()) {
      envDir.createSync(recursive: true);
    }

    // Save environment
    final bruStr = environment.toBru();
    if (!environment.file.existsSync()) {
      environment.file.createSync(recursive: true);
    }
    environment.file.writeAsStringSync(bruStr);

    // Save the environment's secret vars to app storage
    _appStorage.saveSecretVars(collection.dir.path, environment.fileName(), environment.secretVars());
  }
}
