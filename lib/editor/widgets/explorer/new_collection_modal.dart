import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

Future<void> showNewCollectionModal(BuildContext context) {
  return showDialog(context: context, builder: (dialogContext) => const NewCollectionModal());
}

class NewCollectionModal extends StatefulWidget {
  const NewCollectionModal({super.key});

  @override
  State<NewCollectionModal> createState() => _NewCollectionModalState();
}

class _NewCollectionModalState extends State<NewCollectionModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _folderController.text = _nameController.text;
    });
  }

  Future<String?> _getCollectionPath() async {
    final config = context.read<Config>();
    late String? path;
    if (config.isTest) {
      path = './test/support/';
    } else {
      // Need to find a way to mock the file selector in integration tests
      path = await getDirectoryPath();
    }

    return path;
  }

  Future<void> _onBrowse() async {
    final path = await _getCollectionPath();
    print('path: $path');
    if (path != null) {
      setState(() {
        _locationController.text = path;
      });
    }
  }

  Future<void> _onCreate() async {
    final location = _locationController.text;
    final folderName = _nameController.text;

    if (location.isNotEmpty && folderName.isNotEmpty) {
      final collectionPath = path.join(location, folderName);
      context.read<ExplorerRepo>().createCollection(collectionPath);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 450,
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Collection',
                  style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFFD4D4D4), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Name:', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14)),
                      const SizedBox(height: 24),
                      const Text('Location:', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14)),
                      if (_nameController.text.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Folder Name:', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        key: Key('new_collection_name_input'),
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
                        decoration: textFieldDecor,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: Key('new_collection_location_input'),
                        controller: _locationController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
                        decoration: textFieldDecorReadOnly,
                      ),
                      const SizedBox(height: 16),
                      if (_nameController.text.isNotEmpty)
                        TextField(
                          key: Key('new_collection_folder_name_input'),
                          controller: _folderController,
                          readOnly: true,
                          style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
                          decoration: textFieldDecorReadOnly,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const SizedBox(height: 45),
                    ElevatedButton(
                      key: ValueKey("browse_btn"),
                      onPressed: _onBrowse,
                      style: commonButtonStyle,
                      child: const Text('Browse'),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  key: ValueKey("create_btn"),
                  onPressed: _onCreate,
                  style: commonButtonStyle,
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
