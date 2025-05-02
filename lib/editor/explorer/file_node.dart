class FileNode {
  final String name;
  final bool isDirectory;
  final List<FileNode> children = [];
  bool isExpanded;

  FileNode({
    required this.name,
    this.isDirectory = false,
    List<FileNode>? initialChildren,
    this.isExpanded = false,
  }) {
    if (initialChildren != null) {
      children.addAll(initialChildren);
    }
  }

  FileNode copyWith({bool? isExpanded}) {
    return FileNode(
      name: name,
      isDirectory: isDirectory,
      initialChildren: children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
