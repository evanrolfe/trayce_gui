import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double minPaneWidth = 200.0;
const Color textColor = Color(0xFFD4D4D4);
const String leftPaneWidthKey = 'editor_left_pane_width';
const double defaultPaneWidth = 250.0;

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

class EditorCache {
  static double? _cachedWidth;

  static Future<void> preloadWidth() async {
    if (_cachedWidth != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedWidth = prefs.getDouble(leftPaneWidthKey);
  }

  static double get width => _cachedWidth ?? -1;

  static Future<void> saveWidth(double width) async {
    _cachedWidth = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(leftPaneWidthKey, width);
  }
}

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final ValueNotifier<double> _widthNotifier;
  late final List<FileNode> _files;

  // Add this method to sort nodes
  void _sortNodes(List<FileNode> nodes) {
    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });
  }

  @override
  void initState() {
    super.initState();
    _widthNotifier = ValueNotifier(EditorCache.width);
    EditorCache.preloadWidth().then((_) {
      _widthNotifier.value = EditorCache.width;
    });

    _files = [
      FileNode(
        name: 'src',
        isDirectory: true,
        isExpanded: true,
        initialChildren: [
          FileNode(name: 'main.dart'),
          FileNode(name: 'utils.dart'),
          FileNode(
            name: 'widgets',
            isDirectory: true,
            initialChildren: [
              FileNode(name: 'button.dart'),
              FileNode(name: 'input.dart'),
            ],
          ),
        ],
      ),
      FileNode(
        name: 'test',
        isDirectory: true,
        initialChildren: [
          FileNode(name: 'widget_test.dart'),
        ],
      ),
      FileNode(name: 'README.md'),
      FileNode(name: 'pubspec.yaml'),
      FileNode(name: '.gitignore'),
    ];

    // Sort initial files
    _sortNodes(_files);
    for (var node in _files) {
      if (node.isDirectory) {
        _sortNodes(node.children);
      }
    }
  }

  Widget _buildFileTree(FileNode node, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Draggable<FileNode>(
          data: node,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.only(left: indent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (node.isDirectory)
                    const Icon(
                      Icons.folder,
                      color: textColor,
                      size: 20,
                    ),
                  if (!node.isDirectory)
                    const Icon(
                      Icons.insert_drive_file,
                      color: textColor,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    node.name,
                    style: const TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),
          child: DragTarget<FileNode>(
            onWillAccept: (data) {
              // Only prevent dropping onto itself or its own children
              if (data == null) return false;
              if (data == node) return false;

              // Prevent dropping a parent into its own child
              if (data.isDirectory) {
                FileNode? parent = _findParentNode(node);
                while (parent != null) {
                  if (parent == data) return false;
                  parent = _findParentNode(parent);
                }
              }

              // Allow dropping on directories
              if (node.isDirectory) return true;

              // For files, only allow dropping next to them
              return true;
            },
            onAccept: (data) {
              setState(() {
                // Remove from old location
                _removeNode(data);
                // Add to new location
                if (node.isDirectory) {
                  node.children.add(data);
                  _sortNodes(node.children);
                } else {
                  // If dropping on a file, add to the same directory
                  final parentNode = _findParentNode(node);
                  if (parentNode != null) {
                    final index = parentNode.children.indexOf(node);
                    parentNode.children.insert(index + 1, data);
                    _sortNodes(parentNode.children);
                  } else {
                    // If no parent found, add to root
                    _files.add(data);
                    _sortNodes(_files);
                  }
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return InkWell(
                onTap: () {
                  if (node.isDirectory) {
                    setState(() {
                      node.isExpanded = !node.isExpanded;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.only(left: indent, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.teal.withAlpha(77)
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (node.isDirectory)
                        Icon(
                          node.isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: textColor,
                          size: 20,
                        ),
                      Icon(
                        node.isDirectory
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        color: textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        node.name,
                        style: const TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileTree(
                child,
                indent: indent + 24,
              )),
      ],
    );
  }

  void _removeNode(FileNode node) {
    // Remove from root level
    if (_files.remove(node)) return;

    // Remove from nested directories
    for (var file in _files) {
      if (_removeNodeFromChildren(file, node)) return;
    }
  }

  bool _removeNodeFromChildren(FileNode parent, FileNode nodeToRemove) {
    if (parent.children.remove(nodeToRemove)) return true;

    for (var child in parent.children) {
      if (_removeNodeFromChildren(child, nodeToRemove)) return true;
    }

    return false;
  }

  FileNode? _findParentNode(FileNode node) {
    for (var file in _files) {
      final parent = _findParentInNode(file, node);
      if (parent != null) return parent;
    }
    return null;
  }

  FileNode? _findParentInNode(FileNode current, FileNode node) {
    if (current.children.contains(node)) return current;

    for (var child in current.children) {
      final parent = _findParentInNode(child, node);
      if (parent != null) return parent;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _widthNotifier,
      builder: (context, leftPaneWidth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final effectiveWidth = leftPaneWidth < 0
                ? (defaultPaneWidth / totalWidth).clamp(0.0, 1.0)
                : leftPaneWidth;

            return Stack(
              children: [
                Row(
                  children: [
                    Container(
                      width: totalWidth * effectiveWidth,
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._files
                                  .map((node) => _buildFileTree(node))
                                  .toList(),
                              // Add root-level drop target
                              DragTarget<FileNode>(
                                onWillAccept: (data) {
                                  if (data == null) return false;
                                  // Don't accept if it's already at root level
                                  return _findParentNode(data) != null;
                                },
                                onAccept: (data) {
                                  setState(() {
                                    _removeNode(data);
                                    _files.add(data);
                                    _sortNodes(_files);
                                  });
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: candidateData.isNotEmpty
                                          ? Colors.teal.withAlpha(77)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: totalWidth * (1 - effectiveWidth),
                      child: const Center(
                        child: Text(
                          'Right pane',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: totalWidth * effectiveWidth - 1.5,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newLeftWidth =
                            effectiveWidth * totalWidth + details.delta.dx;
                        final newRightWidth =
                            (1 - effectiveWidth) * totalWidth -
                                details.delta.dx;

                        if (newLeftWidth >= minPaneWidth &&
                            newRightWidth >= minPaneWidth) {
                          _saveWidth(newLeftWidth / totalWidth);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 3,
                            color: Colors.transparent,
                          ),
                          Positioned(
                            left: 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveWidth(double width) async {
    await EditorCache.saveWidth(width);
    _widthNotifier.value = width;
  }

  @override
  void dispose() {
    _widthNotifier.dispose();
    super.dispose();
  }
}
