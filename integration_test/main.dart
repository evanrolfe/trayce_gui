import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/main.dart' as app;

import 'containers_modal_test.dart' as containers_modal_test;
import 'editor_create_collection_test.dart' as editor_create_collection;
import 'editor_modifying_requests.dart' as editor_modifying_requests;
import 'editor_new_request_in_folder_test.dart' as editor_new_request_in_folder;
import 'editor_saving_request.dart' as editor_saving_request;
import 'editor_sending_a_request.dart' as editor_sending_a_request;
import 'editor_sending_a_request_with_script_test.dart' as editor_sending_a_request_with_script;
import 'flow_table_test.dart' as flow_table_test;
import 'grpc_parsing.dart' as grpc_parsing_test;
import 'license_key_test.dart' as license_key_test;
import 'proto_def_modal.dart' as proto_def_modal_test;
// NOTE: This is how we have to run integration tests (as opposed to letting flutter test run multiple tests)
// because of this open issue: https://github.com/flutter/flutter/issues/135673

const licenseKey = 'ce8d3bb0-40f4-4d68-84c2-1388e5263051';
const licenseKeyInvalid = '6f95fe90-cdfc-4054-9515-84bba62f7f1d';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration test', (tester) async {
    // Create screenshots directory
    final screenshotsDir = Directory('screenshots');
    if (!screenshotsDir.existsSync()) {
      screenshotsDir.createSync();
    }

    // Start the mock trayce API server
    final trayceApi = await ShelfTestServer.create();
    trayceApi.handler.expect("GET", "/verify/$licenseKey", (request) async {
      return shelf.Response.ok('{"status": "active"}', headers: {"content-type": "application/json"});
    });
    trayceApi.handler.expect("GET", "/verify/$licenseKeyInvalid", (request) async {
      return shelf.Response.ok('{"status": "inactive"}', headers: {"content-type": "application/json"});
    });

    // Start the real app once for all tests
    app.main(['--test', '--trayce-api-url', trayceApi.url.toString()]);

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
      {'func': editor_new_request_in_folder.test},
      {'func': editor_modifying_requests.test},
      {'func': editor_saving_request.test},
      {'f': 1, 'func': editor_sending_a_request.test},
      {'func': editor_sending_a_request_with_script.test},
      {'func': editor_create_collection.test},
      {'func': license_key_test.test},
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
