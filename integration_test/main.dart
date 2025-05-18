import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/main.dart' as app;

import 'containers_modal_test.dart' as containers_modal_test;
import 'editor_modifying_requests.dart' as editor_modifying_requests;
import 'editor_saving_request.dart' as editor_saving_request;
import 'flow_table_test.dart' as flow_table_test;
import 'grpc_parsing.dart' as grpc_parsing_test;
import 'proto_def_modal.dart' as proto_def_modal_test;
// NOTE: This is how we have to run integration tests (as opposed to letting flutter test run multiple tests)
// because of this open issue: https://github.com/flutter/flutter/issues/135673

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration test', (tester) async {
    // Create screenshots directory
    final screenshotsDir = Directory('screenshots');
    if (!screenshotsDir.existsSync()) {
      screenshotsDir.createSync();
    }

    // Start the real app once for all tests
    app.main(['--test']);

    // Add a longer initial pump and settle to ensure app is fully loaded
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Connect to DB
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactory.openDatabase('tmp.db');

    List<Map<String, dynamic>> tests = [
      {'func': proto_def_modal_test.test},
      {'func': grpc_parsing_test.test},
      {'func': containers_modal_test.test},
      {'func': flow_table_test.test},
      {'func': editor_modifying_requests.test},
      {'func': editor_saving_request.test},
      // {'func': editor_multiple_collections_test.test},
    ];

    bool isFocused = tests.any((test) => test.containsKey('f'));

    for (var test in tests) {
      if (isFocused && !test.containsKey('f')) continue;

      await test['func'](tester, db);
      await truncateDb(db);
    }

    await db.close();
  });
}

Future<void> truncateDb(Database db) async {
  await db.delete('flows');
  await db.delete('proto_defs');
}
