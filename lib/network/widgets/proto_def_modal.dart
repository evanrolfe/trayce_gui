import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../common/style.dart';
import '../models/proto_def.dart';
import '../repo/proto_def_repo.dart';

Future<void> showProtoDefModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogContext) => const ProtoDefModal(),
  );
}

class ProtoDefModal extends StatefulWidget {
  const ProtoDefModal({super.key});

  @override
  State<ProtoDefModal> createState() => _ProtoDefModalState();
}

class _ProtoDefModalState extends State<ProtoDefModal> {
  List<ProtoDef> _protoDefs = [];

  @override
  void initState() {
    super.initState();
    _loadProtoDefs();
  }

  Future<void> _loadProtoDefs() async {
    final protoDefRepo = context.read<ProtoDefRepo>();
    final protoDefs = await protoDefRepo.getAll();
    setState(() {
      _protoDefs = protoDefs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252526),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Proto Definitions',
                  style: TextStyle(
                    color: Color(0xFFD4D4D4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFD4D4D4),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Manage your .proto file definitions',
                  style: TextStyle(
                    color: Color(0xFFD4D4D4),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    const XTypeGroup typeGroup = XTypeGroup(
                      label: 'protobuf',
                      extensions: <String>['proto'],
                    );
                    final XFile? file = await openFile(
                        acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                    final filePath = file?.path;

                    if (filePath != null) {
                      final contents = await File(filePath).readAsString();

                      final fileName = path.basename(filePath);
                      final protoDef = ProtoDef(
                        name: fileName,
                        filePath: filePath,
                        protoFile: contents,
                        createdAt: DateTime.now(),
                      );

                      final protoDefRepo = context.read<ProtoDefRepo>();
                      await protoDefRepo.save(protoDef);
                      await _loadProtoDefs(); // Refresh the list
                    }
                  },
                  style: commonButtonStyle,
                  child: const Text('Upload'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF474747),
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: const Color(0xFF474747).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(2), // Name
                            1: FlexColumnWidth(4), // Path
                            2: FlexColumnWidth(2), // Created At
                            3: FlexColumnWidth(1), // Actions
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D2D2D),
                              ),
                              children: [
                                _buildHeaderCell('Name'),
                                _buildHeaderCell('Path'),
                                _buildHeaderCell('Created At'),
                                _buildHeaderCell('Actions'),
                              ],
                            ),
                            ..._protoDefs.map((protoDef) => TableRow(
                                  children: [
                                    _buildCell(protoDef.name),
                                    _buildCell(protoDef.filePath),
                                    _buildCell(protoDef.createdAt.toString()),
                                    _buildCell('', alignment: Alignment.center),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: commonButtonStyle,
                        child: const Text('Ok'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD4D4D4),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
