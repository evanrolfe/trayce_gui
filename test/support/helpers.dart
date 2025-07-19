import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// See: https://itnext.io/widget-testing-dealing-with-renderflex-overflow-errors-9488f9cf9a29
void ignoreOverflowErrors(FlutterErrorDetails details, {bool forceReport = false}) {
  bool ifIsOverflowError = false;
  bool isUnableToLoadAsset = false;
  // Detect overflow error.
  var exception = details.exception;
  if (exception is FlutterError) {
    ifIsOverflowError = !exception.diagnostics.any((e) => e.value.toString().startsWith("A RenderFlex overflowed by"));
    isUnableToLoadAsset = !exception.diagnostics.any((e) => e.value.toString().startsWith("Unable to load asset"));
  }
  // Ignore if is overflow error.
  if (ifIsOverflowError || isUnableToLoadAsset) {
    debugPrint('Ignored OverflowError');
  } else {
    FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
  }
}

void saveFile(String path, String contents) {
  try {
    final file = File(path);
    file.writeAsStringSync(contents);
  } catch (e) {
    throw Exception('Failed to save file at $path: $e');
  }
}

void copyFolderSync(String sourcePath, String targetPath) {
  final sourceDir = Directory(sourcePath);
  final targetDir = Directory(targetPath);

  // Create target directory if it doesn't exist
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  // Copy all contents
  for (final entity in sourceDir.listSync(recursive: true)) {
    final relativePath = entity.path.substring(sourcePath.length);
    final targetEntityPath = '$targetPath$relativePath';

    if (entity is File) {
      // Copy file
      entity.copySync(targetEntityPath);
    } else if (entity is Directory) {
      // Create directory
      Directory(targetEntityPath).createSync(recursive: true);
    }
  }
}

Future<void> copyFolder(String sourcePath, String targetPath) async {
  final sourceDir = Directory(sourcePath);
  final targetDir = Directory(targetPath);

  // Create target directory if it doesn't exist
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  // Copy all contents
  for (final entity in sourceDir.listSync(recursive: true)) {
    final relativePath = entity.path.substring(sourcePath.length);
    final targetEntityPath = '$targetPath$relativePath';

    if (entity is File) {
      // Copy file
      entity.copySync(targetEntityPath);
    } else if (entity is Directory) {
      // Create directory
      Directory(targetEntityPath).createSync(recursive: true);
    }
  }
}

void deleteFolderSync(String folderPath) {
  final directory = Directory(folderPath);
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

Future<void> deleteFolder(String folderPath) async {
  final directory = Directory(folderPath);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (file.existsSync()) {
    await file.delete();
  }
}

String loadFile(String path) {
  try {
    final file = File(path);
    return file.readAsStringSync();
  } catch (e) {
    throw Exception('Failed to load file: $e');
  }
}

Future<void> pressCtrlN(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}

Future<void> pressCtrlS(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}

Future<void> pressCtrlW(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}

Future<void> pressEnter(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}
