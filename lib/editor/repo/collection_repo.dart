import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/parse/parse_collection.dart';
import 'package:trayce/editor/models/parse/parse_environment.dart';

class CollectionRepo {
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
      }
    }

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
    }
  }
}
