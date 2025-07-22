import 'package:file_selector/file_selector.dart' as fs;

abstract class FilePickerI {
  Future<String?> openTrayceDB();
  Future<String?> saveTrayceDB();
  Future<String?> saveBruFile(String initialDirectory);
  Future<String?> openFile();
  Future<String?> getCollectionPath();
}

// FilePicker lets you pick files & directores from the native file dialog
class FilePicker implements FilePickerI {
  @override
  Future<String?> openTrayceDB() async {
    const fs.XTypeGroup typeGroup = fs.XTypeGroup(label: 'Trayce', extensions: <String>['db']);
    final fs.XFile? file = await fs.openFile(acceptedTypeGroups: <fs.XTypeGroup>[typeGroup]);

    return file?.path;
  }

  @override
  Future<String?> saveTrayceDB() async {
    const fs.XTypeGroup typeGroup = fs.XTypeGroup(label: 'Trayce', extensions: <String>['db']);
    final fs.FileSaveLocation? file = await fs.getSaveLocation(acceptedTypeGroups: <fs.XTypeGroup>[typeGroup]);

    return file?.path;
  }

  @override
  Future<String?> saveBruFile(String initialDirectory) async {
    const fs.XTypeGroup typeGroup = fs.XTypeGroup(label: 'Trayce', extensions: <String>['bru']);
    final fs.FileSaveLocation? file = await fs.getSaveLocation(
      initialDirectory: initialDirectory,
      acceptedTypeGroups: <fs.XTypeGroup>[typeGroup],
    );

    return file?.path;
  }

  @override
  Future<String?> openFile() async {
    final result = await fs.openFile();

    return result?.path;
  }

  @override
  Future<String?> getCollectionPath() async {
    return fs.getDirectoryPath();
  }
}
