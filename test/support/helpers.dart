import 'dart:io';

Future<void> copyFolder(String sourcePath, String targetPath) async {
  final sourceDir = Directory(sourcePath);
  final targetDir = Directory(targetPath);

  // Create target directory if it doesn't exist
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  // Copy all contents
  await for (final entity in sourceDir.list(recursive: true)) {
    final relativePath = entity.path.substring(sourcePath.length);
    final targetEntityPath = '$targetPath$relativePath';

    if (entity is File) {
      // Copy file
      await entity.copy(targetEntityPath);
    } else if (entity is Directory) {
      // Create directory
      Directory(targetEntityPath).createSync(recursive: true);
    }
  }
}

Future<void> deleteFolder(String folderPath) async {
  final directory = Directory(folderPath);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}
