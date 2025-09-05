import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';

import '../test/support/helpers.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';
const expectedFormattedJson = '''{
  "message": "Hello, World!",
  "status": 200
}''';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  final folderBruPath = 'test/support/collection1/myfolder/folder.bru';
  final originalFolderBru = loadFile(folderBruPath);

  final collectionBruPath = 'test/support/collection1/collection.bru';
  final originalCollectionBru = loadFile(collectionBruPath);

  final envBruPath = 'test/support/collection1/environments/dev.bru';
  final originalEnvBru = loadFile(envBruPath);

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('editor-sidebar-btn'));
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // ===========================================================================
  // Open a collection
  // ===========================================================================
  // Find and click the IconButton with the key 'collection_btn'
  final openCollectionBtn = find.byKey(const Key('collection_btn'));
  await tester.tap(openCollectionBtn);
  await tester.pumpAndSettle();

  // Find and click the PopupMenuItem with the text "Open Collection"
  final openCollectionMenuItem = find.text('Open Collection').last;
  await tester.tap(openCollectionMenuItem);
  await tester.pumpAndSettle();
  expect(find.text('collection1'), findsOneWidget);

  // Click the IconButton with the key 'collection_btn'
  await tester.tap(openCollectionBtn);
  await tester.pumpAndSettle();

  // Find and click the PopupMenuItem with the text "Open Collection"
  final newRequestMenuItem = find.text('New Request');
  await tester.tap(newRequestMenuItem);
  await tester.pumpAndSettle();

  // ===========================================================================
  // Setup mock server
  // ===========================================================================
  shelf.Request? sentRequest;
  String? sentRequestBody;
  final server = await ShelfTestServer.create();
  server.handler.expect("POST", "/test_endpoint", (request) async {
    sentRequest = request;
    sentRequestBody = await sentRequest!.readAsString();

    return shelf.Response.ok(jsonResponse, headers: {"content-type": "application/json"});
  });

  // ===========================================================================
  // Change the URL, Method, Body, Headers, and add a script
  // ===========================================================================
  // Change the URL
  final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
  urlInput.controller.text = path.join(server.url.toString(), 'test_endpoint');
  await tester.pumpAndSettle();

  // Select POST method
  final methodDropdown = find.byKey(const Key('flow_editor_http_method_dropdown')).first;
  await tester.tap(methodDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('POST'));
  await tester.pumpAndSettle();

  // Set a header
  await tester.tap(find.text('Headers').first);
  await tester.pumpAndSettle();
  final headersTable = tester.widget<FormTable>(find.byType(FormTable));
  final headersManager = headersTable.controller;

  headersManager.rows()[0].keyController.text = 'X-Auth-Token';
  headersManager.rows()[0].valueController.text = '1234abcd';
  await tester.pumpAndSettle();

  headersManager.rows()[1].keyController.text = 'Content-Type';
  headersManager.rows()[1].valueController.text = 'application/json';
  await tester.pumpAndSettle();

  // Set the body type
  await tester.tap(find.text('Body'));
  await tester.pumpAndSettle();

  final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
  await tester.tap(bodyTypeDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('JSON'));
  await tester.pumpAndSettle();

  // Set the body content
  final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
  bodyEditor.controller.text = '{"hello": "world"}';
  await tester.pumpAndSettle();

  // Set the pre-request script
  await tester.tap(find.text('Script'));
  await tester.pumpAndSettle();

  final scriptEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
  scriptEditor.controller.text = 'console.log("Hello, World!");';
  await tester.pumpAndSettle();

  // ===========================================================================
  // Hit "Send"
  // ===========================================================================
  final sendBtn = find.byKey(const Key('flow_editor_http_send_btn'));
  await tester.tap(sendBtn);
  await tester.pumpAndSettle();

  // Assert that the client will make a POST request to /
  expect(sentRequest!.method, 'POST');
  expect(sentRequest!.headers['X-Auth-Token'], '1234abcd');
  expect(sentRequest!.headers['Content-Type'], 'application/json; charset=utf-8');

  // Assert the console output
  await tester.tap(find.text('Output'));
  await tester.pumpAndSettle();

  await tester.pumpAndSettle(const Duration(seconds: 3));

  final consoleOutputEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).last);
  final consoleOutput = consoleOutputEditor.controller.text.split('\n');
  expect(consoleOutput.length, 3);
  expect(consoleOutput[0], 'Hi, from the collection! (pre)');
  expect(consoleOutput[1], 'Hello, World!');
  expect(consoleOutput[2], 'Hi, from the collection! (post)');

  await server.close();
}
