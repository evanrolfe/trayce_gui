import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/proto_def.dart';

class ProtoDefRepo {
  Database db;

  ProtoDefRepo({required this.db});

  Future<ProtoDef> upload(String name, String protoFilePath) async {
    // Read the proto file content
    final file = File(protoFilePath);
    final content = await file.readAsString();

    final protoDef = ProtoDef(
      name: name,
      filePath: protoFilePath,
      protoFile: content,
      createdAt: DateTime.now(),
    );

    // Save and return the ProtoDef
    return save(protoDef);
  }

  Future<ProtoDef> save(ProtoDef protoDef) async {
    // Insert new proto def
    final id = await db.insert('proto_defs', {
      'name': protoDef.name,
      'file_path': protoDef.filePath,
      'proto_file': protoDef.protoFile,
      'created_at': protoDef.createdAt.toIso8601String(),
    });

    return protoDef.copyWith(id: id);
  }

  Future<List<ProtoDef>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('proto_defs');
    return maps.map((map) => ProtoDef.fromMap(map)).toList();
  }
}
