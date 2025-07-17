import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/parse/parse_environment.dart';

class CollectionRepo {
  final AppStorageI _appStorage;

  CollectionRepo(this._appStorage);

  Collection load(Directory dir) {
    final file = File('${dir.path}/collection.bru');

    // Load environments
    List<Environment> environments = [];
    final envPath = path.join(dir.path, 'environments');

    // Load all *.bru files from the environments directory
    final envDir = Directory(envPath);
    if (envDir.existsSync()) {
      final envFiles = envDir.listSync().whereType<File>().where((file) => file.path.endsWith('.bru'));
      for (final envFile in envFiles) {
        final env = parseEnvironmentFile(envFile);
        environments.add(env);

        // Load the environment's secret vars from app storage
        _loadEnvironmentSecretVars(env, dir.path);
      }
    }

    // Load the collection
    final collectionStr = file.readAsStringSync();
    final collection = parseCollection(collectionStr, file, dir, environments);

    collection.file = file;
    collection.dir = dir;

    return collection;
  }

  void save(Collection collection) {
    final bruStr = collection.toBru();
    final file = collection.file;

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);

    if (collection.environments.isEmpty) return;

    final envPath = path.join(collection.dir.path, 'environments');
    final envDir = Directory(envPath);
    if (!envDir.existsSync()) {
      envDir.createSync(recursive: true);
    }

    // Save all environments
    for (final environment in collection.environments) {
      final bruStr = environment.toBru();
      if (!environment.file.existsSync()) {
        environment.file.createSync(recursive: true);
      }
      environment.file.writeAsStringSync(bruStr);

      // Save the environment's secret vars to app storage
      _appStorage.saveSecretVars(collection.dir.path, environment.fileName(), environment.secretVars());
    }
  }

  Future<void> _loadEnvironmentSecretVars(Environment environment, String collectionPath) async {
    final secretVars = await _appStorage.getSecretVars(collectionPath, environment.fileName());

    for (final entry in secretVars.entries) {
      final key = entry.key;
      final value = entry.value;

      for (final varr in environment.vars) {
        if (varr.name == key && varr.secret) {
          varr.value = value;
          break;
        }
      }
    }
  }
}
