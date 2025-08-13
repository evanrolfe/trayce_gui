import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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
    print("Copied nodejs files to: ${nodejsDir.path}");
  } catch (e) {
    print("Error setting up NodeJS: $e");
  }
}

/// Recursively copies a folder from assets to the target directory
Future<void> _copyAssetFolder(String assetPath, String targetPath) async {
  try {
    // Get the asset manifest to find all files in the folder
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Filter assets that start with the specified path
    final assetFiles = manifestMap.keys.where((String key) => key.startsWith('$assetPath/')).toList();

    for (final assetFile in assetFiles) {
      // Get the relative path from the asset folder
      final relativePath = assetFile.substring(assetPath.length + 1);
      final targetFile = File('$targetPath/$relativePath');

      // Create parent directories if they don't exist
      final parentDir = targetFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // Copy the file
      final bytes = await rootBundle.load(assetFile);
      await targetFile.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }
  } catch (e) {
    print("Error copying asset folder: $e");
    rethrow;
  }
}

/// Runs npm install in the specified directory
Future<void> _runNpmInstall(String directoryPath) async {
  try {
    final result = await Process.run('npm', ['install'], workingDirectory: directoryPath);
    if (result.exitCode != 0) {
      throw Exception('npm install failed with exit code ${result.exitCode}: ${result.stderr}');
    }
  } catch (e) {
    print("Error running npm install: $e");
  }
}
