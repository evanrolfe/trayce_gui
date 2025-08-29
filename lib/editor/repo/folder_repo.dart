import 'dart:io';

import 'package:trayce/editor/models/folder.dart';
import 'package:trayce/editor/models/parse/parse_folder.dart';
import 'package:trayce/editor/models/request.dart';

class FolderRepo {
  Folder load(Directory dir) {
    final file = File('${dir.path}/folder.bru');

    // Handle folders without folder.bru file
    if (!file.existsSync()) {
      return Folder(
        file: file,
        dir: dir,
        type: 'folder',
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
        authType: AuthType.none,
      );
    }

    final folderStr = file.readAsStringSync();
    final folder = parseFolder(folderStr, file, dir);

    folder.file = file;
    folder.dir = dir;

    return folder;
  }

  void save(Folder folder) {
    final bruStr = folder.toBru();
    final file = folder.file;

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(bruStr);
  }
}
