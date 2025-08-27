import 'package:trayce/common/app_storage.dart';
import 'package:trayce/editor/models/global_environment.dart';

class GlobalEnvironmentRepo {
  final AppStorageI _appStorage;
  String? _selectedEnvName;

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
      _appStorage.saveGlobalEnvVars(environment.name, environment.toMap());
    }
  }

  Future<void> saveOne(GlobalEnvironment env) async {
    await _appStorage.deleteGlobalEnv(env.name);
    _appStorage.saveGlobalEnvVars(env.name, env.toMap());
  }

  void setSelectedEnvName(String? envName) {
    _selectedEnvName = envName;
  }

  GlobalEnvironment? getSelectedEnv() {
    if (_selectedEnvName == null) return null;

    final envs = getAll();
    return envs.firstWhere((e) => e.name == _selectedEnvName);
  }
}
