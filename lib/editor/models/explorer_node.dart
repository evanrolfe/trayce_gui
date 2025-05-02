class ExplorerNode {
  final String name;
  final bool isDirectory;
  final List<ExplorerNode> children = [];
  bool isExpanded;

  ExplorerNode({
    required this.name,
    this.isDirectory = false,
    List<ExplorerNode>? initialChildren,
    this.isExpanded = false,
  }) {
    if (initialChildren != null) {
      children.addAll(initialChildren);
    }
  }

  ExplorerNode copyWith({bool? isExpanded}) {
    return ExplorerNode(
      name: name,
      isDirectory: isDirectory,
      initialChildren: children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
