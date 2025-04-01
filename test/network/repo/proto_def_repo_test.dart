import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/network/models/proto_def.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';

import '../../support/database.dart';

void main() {
  late TestDatabase testDb;
  late ProtoDefRepo protoDefRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDb = await TestDatabase.instance;
    protoDefRepo = ProtoDefRepo(db: testDb.db);
  });

  tearDown(() => testDb.truncate());

  group('ProtoDefRepo', () {
    group('save()', () {
      test('it saves a proto definition to the database', () async {
        // Create and save a proto def
        final protoDef = ProtoDef(
          name: 'test.proto',
          filePath: '/path/to/test.proto',
          protoFile: 'syntax = "proto3";',
          createdAt: DateTime.now(),
        );
        final savedProtoDef = await protoDefRepo.save(protoDef);

        // Query the database directly to verify
        final List<Map<String, dynamic>> results = await testDb.db.query(
          'proto_defs',
          where: 'id = ?',
          whereArgs: [savedProtoDef.id],
        );

        expect(results.length, 1);

        final dbProtoDef = results.first;
        expect(dbProtoDef['name'], protoDef.name);
        expect(dbProtoDef['file_path'], protoDef.filePath);
        expect(dbProtoDef['proto_file'], protoDef.protoFile);
        expect(dbProtoDef['created_at'], protoDef.createdAt.toIso8601String());
      });
    });

    group('getAll()', () {
      test('it returns all proto definitions', () async {
        // Save test proto defs
        final protoDef1 = ProtoDef(
          name: 'test1.proto',
          filePath: '/path/to/test1.proto',
          protoFile: 'syntax = "proto3";',
          createdAt: DateTime.now(),
        );
        final protoDef2 = ProtoDef(
          name: 'test2.proto',
          filePath: '/path/to/test2.proto',
          protoFile: 'syntax = "proto2";',
          createdAt: DateTime.now(),
        );

        final savedProtoDef1 = await protoDefRepo.save(protoDef1);
        await protoDefRepo.save(protoDef2);

        // Get all proto defs
        final protoDefs = await protoDefRepo.getAll();

        expect(protoDefs.length, 2);

        final firstDef = protoDefs.first;
        expect(firstDef.id, savedProtoDef1.id);
        expect(firstDef.name, protoDef1.name);
        expect(firstDef.filePath, protoDef1.filePath);
        expect(firstDef.protoFile, protoDef1.protoFile);
        expect(firstDef.createdAt.toIso8601String(), protoDef1.createdAt.toIso8601String());
      });
    });

    group('upload()', () {
      test('it uploads and saves api.proto', () async {
        final protoPath = 'lib/agent/api.proto';
        final protoDef = await protoDefRepo.upload('api.proto', protoPath);

        // Verify it was saved by getting all proto defs
        final protoDefs = await protoDefRepo.getAll();
        expect(protoDefs.length, 1);

        final savedDef = protoDefs.first;
        expect(savedDef.id, protoDef.id);
        expect(savedDef.name, 'api.proto');
        expect(savedDef.filePath, protoPath);
        expect(savedDef.protoFile.isNotEmpty, true); // Should have proto file content
        expect(savedDef.createdAt.toIso8601String(), protoDef.createdAt.toIso8601String());
      });
    });
  });
}
