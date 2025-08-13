import 'dart:io';

import 'package:path_provider/path_provider.dart';

void setupNodeJs() async {
  try {
    final appSupportDir = await getApplicationSupportDirectory();

    // Create the nodejs directory path in app support directory
    final nodejsDir = Directory('${appSupportDir.path}/nodejs');

    // Check if nodejs directory already exists
    if (await nodejsDir.exists()) {
      print("NodeJS directory: ${nodejsDir.path}");
      return;
    }

    // Create the nodejs directory
    await nodejsDir.create(recursive: true);

    // Copy the nodejs folder from assets
    await _copyAssetFolder('nodejs', nodejsDir.path);

    // We commit node_modules cause its easier than running npm install each time
    // await _runNpmInstall(nodejsDir.path);
  } catch (e) {
    print("Error setting up NodeJS: $e");
  }
}

/// Recursively copies a folder from assets to the target directory
Future<void> _copyAssetFolder(String assetPath, String targetPath) async {
  await _copyUsingDirectoryStructure(assetPath, targetPath);
}

/// Copy using AssetManifest (works in development)
// Future<void> _copyUsingAssetManifest(String assetPath, String targetPath) async {
//   final manifestContent = await rootBundle.loadString('AssetManifest.json');
//   final Map<String, dynamic> manifestMap = json.decode(manifestContent);

//   // Filter assets that start with the specified path
//   final assetFiles = manifestMap.keys.where((String key) => key.startsWith('$assetPath/')).toList();

//   for (final assetFile in assetFiles) {
//     // Get the relative path from the asset folder
//     final relativePath = assetFile.substring(assetPath.length + 1);
//     final targetFile = File('$targetPath/$relativePath');

//     // Create parent directories if they don't exist
//     final parentDir = targetFile.parent;
//     if (!await parentDir.exists()) {
//       await parentDir.create(recursive: true);
//     }

//     // Copy the file
//     final bytes = await rootBundle.load(assetFile);
//     await targetFile.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
//   }
// }

/// Copy using directory structure (works in CI builds)
Future<void> _copyUsingDirectoryStructure(String assetPath, String targetPath) async {
  // Get the application documents directory as a fallback
  final appDocDir = await getApplicationDocumentsDirectory();
  final sourceDir = Directory('${appDocDir.path}/../$assetPath');

  if (!await sourceDir.exists()) {
    // Try to find the source directory in the current working directory
    final currentDir = Directory.current;
    final altSourceDir = Directory('${currentDir.path}/$assetPath');

    if (await altSourceDir.exists()) {
      await _copyDirectoryRecursively(altSourceDir, Directory(targetPath));
      return;
    }

    throw Exception('Source directory not found: ${sourceDir.path} or ${altSourceDir.path}');
  }

  await _copyDirectoryRecursively(sourceDir, Directory(targetPath));
}

/// Recursively copy a directory and all its contents
Future<void> _copyDirectoryRecursively(Directory source, Directory target) async {
  if (!await target.exists()) {
    await target.create(recursive: true);
  }

  await for (final entity in source.list(recursive: false)) {
    final targetPath = '${target.path}/${entity.path.split('/').last}';

    if (entity is File) {
      await entity.copy(targetPath);
    } else if (entity is Directory) {
      await _copyDirectoryRecursively(entity, Directory(targetPath));
    }
  }
}

/// Runs npm install in the specified directory
// Future<void> _runNpmInstall(String directoryPath) async {
//   try {
//     final result = await Process.run('npm', ['install'], workingDirectory: directoryPath);
//     if (result.exitCode != 0) {
//       throw Exception('npm install failed with exit code ${result.exitCode}: ${result.stderr}');
//     }
//   } catch (e) {
//     print("Error running npm install: $e");
//   }
// }
