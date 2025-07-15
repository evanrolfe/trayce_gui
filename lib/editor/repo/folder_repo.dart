import 'dart:io';

import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/parse/parse_folder.dart';

class FolderRepo {
  Folder load(Directory dir) {
    final file = File('${dir.path}/folder.bru');

    final folderStr = file.readAsStringSync();
    final folder = parseFolder(folderStr);

    folder.file = file;
    folder.dir = dir;

    return folder;
  }

  void save(Folder folder) {
    if (folder.file == null) return;

    final bruStr = folder.toBru();
    final file = folder.file!;

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);
  }
}
