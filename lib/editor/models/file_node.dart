import 'dart:io';

sealed class FileNode {}

class NodeCollection extends FileNode {
  Directory? dir;
  File file;
  String name;

  NodeCollection({required this.file, required this.name});
}

class FolderNode extends FileNode {}

class RequestNode extends FileNode {}
