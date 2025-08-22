import 'package:trayce/common/app_storage.dart';
import 'package:trayce/editor/models/global_environment.dart';

class GlobalEnvironmentRepo {
  final AppStorageI _appStorage;

  GlobalEnvironmentRepo(this._appStorage);

  List<GlobalEnvironment> getAll() {
    final List<GlobalEnvironment> envs = [];
    final envMaps = _appStorage.getGlobalEnvMaps();

    for (final envMap in envMaps.entries) {
      final environment = GlobalEnvironment.fromMap(envMap.key, envMap.value);
      envs.add(environment);
    }
    return envs;
  }

  Future<void> rename(String oldName, String newName) async {
    await _appStorage.renameGlobalEnv(oldName, newName);
  }

  Future<void> save(List<GlobalEnvironment> environments) async {
    await _appStorage.deleteGlobalEnvVars();

    // Save the environment's secret vars to app storage
    for (final environment in environments) {
      print('saving global environment: ${environment.name}: ${environment.toMap()}');
      _appStorage.saveGlobalEnvVars(environment.name, environment.toMap());
    }
  }
}
