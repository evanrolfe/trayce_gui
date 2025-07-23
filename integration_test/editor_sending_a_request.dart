import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
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
  // Change the URL, Method, Body & Headers
  // ===========================================================================
  // Change the URL
  final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
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
  expect(sentRequestBody, '{"hello": "world"}');

  final responseEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).last);
  expect(responseEditor.controller.text, expectedFormattedJson);

  // Assert that the formatting is "JSON"
  final formatDropdown = find.byKey(const Key('flow_editor_http_format_dropdown')).first;
  expect(tester.widget<DropdownButton2<String>>(formatDropdown).value, 'JSON');

  // ===========================================================================
  // Change formatting to "Unformatted"
  // ===========================================================================
  await tester.tap(formatDropdown.first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Unformatted'));
  await tester.pumpAndSettle();

  expect(responseEditor.controller.text, jsonResponse);

  // Clear the sent request for the next test to use
  sentRequest = null;
  sentRequestBody = null;

  // ===========================================================================
  // Open an existing request
  // ===========================================================================
  // Click on the myfolder item
  final myfolderItem = find.text('myfolder');
  await tester.tap(myfolderItem);
  await tester.pumpAndSettle();

  // Right-click on one.bru request
  final oneReq = find.text('one');
  await tester.tapAt(tester.getCenter(oneReq), buttons: kSecondaryButton);
  await tester.pumpAndSettle();

  // Click open on context menu
  final openItem = find.text('Open');
  await tester.tap(openItem);
  await tester.pumpAndSettle();

  // ===========================================================================
  // Change a header+variable on the request
  // ===========================================================================
  // Change the URL
  final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')).last);
  urlInput2.controller.text = path.join(server.url.toString(), 'test_endpoint');
  await tester.pumpAndSettle();

  // Set a header
  await tester.tap(find.text('Headers').first);
  await tester.pumpAndSettle();
  final headersTable2 = tester.widget<FormTable>(find.byType(FormTable));
  final headersManager2 = headersTable2.controller;

  headersManager2.rows()[1].keyController.text = 'A';
  headersManager2.rows()[1].valueController.text = 'added-on-form';
  await tester.pumpAndSettle();

  // Set a variable
  await tester.tap(find.text('Variables').first);
  await tester.pumpAndSettle();
  final varsManager = tester.widget<FormTable>(find.byType(FormTable)).controller;

  varsManager.rows()[0].keyController.text = 'A_var';
  varsManager.rows()[0].valueController.text = 'added-on-form';
  await tester.pumpAndSettle();

  // ===========================================================================
  // Change a folder header+variable
  // ===========================================================================
  // Right-click on the myfolder item
  await tester.tapAt(tester.getCenter(myfolderItem), buttons: 2);
  await tester.pumpAndSettle();

  // Click open on context menu
  final settingsItem = find.text('Settings');
  await tester.tap(settingsItem);
  await tester.pumpAndSettle();

  final headersTable3 = tester.widget<FormTable>(find.byType(FormTable).last);
  final headersManager3 = headersTable3.controller;

  // Change the key text of the first header row
  expect(headersManager3.rows().length, 4);

  headersManager3.rows()[0].keyController.text = 'E';
  headersManager3.rows()[0].valueController.text = 'added-by-test';
  await tester.pumpAndSettle();

  // Set a variable
  await tester.tap(find.text('Variables').last);
  await tester.pumpAndSettle();
  final varsManager3 = tester.widget<FormTable>(find.byType(FormTable).last).controller;

  varsManager3.rows()[0].keyController.text = 'B_var';
  varsManager3.rows()[0].valueController.text = 'added-on-folder';
  await tester.pumpAndSettle();

  // Save the changes
  await tester.tap(find.byKey(Key('save_btn')));
  await tester.pumpAndSettle();

  // Expect the file to be changed
  final folderBru = loadFile(folderBruPath);
  expect(folderBru, contains('E: added-by-test'));
  expect(folderBru, contains('B_var: added-on-folder'));

  // ===========================================================================
  // Change a collection Header+Variable
  // ===========================================================================
  // Right-click on the myfolder item
  final collectionItem = find.text('collection1');
  await tester.tapAt(tester.getCenter(collectionItem), buttons: 2);
  await tester.pumpAndSettle();

  // Click open on context menu
  final settingsItem2 = find.text('Settings');
  await tester.tap(settingsItem2);
  await tester.pumpAndSettle();

  final headersTable4 = tester.widget<FormTable>(find.byType(FormTable).last);
  final headersManager4 = headersTable4.controller;

  // Change the key text of the first header row
  expect(headersManager4.rows().length, 5);

  headersManager4.rows()[4].keyController.text = 'F';
  headersManager4.rows()[4].valueController.text = 'added-by-test-collection';
  await tester.pumpAndSettle();

  // Set a variable
  await tester.tap(find.text('Variables').last);
  await tester.pumpAndSettle();
  final varsManager4 = tester.widget<FormTable>(find.byType(FormTable).last).controller;

  varsManager4.rows()[0].keyController.text = 'C_var';
  varsManager4.rows()[0].valueController.text = 'added-on-collection';
  await tester.pumpAndSettle();

  // Save the changes
  await tester.tap(find.byKey(Key('save_btn')));
  await tester.pumpAndSettle();

  // Expect the file to be changed
  final collectionBru = loadFile(collectionBruPath);
  expect(collectionBru, contains('F: added-by-test-collection'));
  expect(collectionBru, contains('C_var: added-on-collection'));

  // ===========================================================================
  // Change an environment vars
  // ===========================================================================
  final envDropdown = find.byKey(const Key('editor_tabs_env_dropdown')).first;

  await tester.tap(envDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Configure'));
  await tester.pumpAndSettle();

  final envTable = tester.widget<FormTable>(find.byType(FormTable).last);
  final envController = envTable.controller;

  envController.rows()[2].keyController.text = 'G_var';
  envController.rows()[2].valueController.text = 'added-on-env';

  envController.rows()[3].keyController.text = 'H_var';
  envController.rows()[3].valueController.text = 'added-on-env-secret!';
  envController.rows()[3].checkboxStateSecret = true;

  await tester.tap(find.byKey(Key('save_btn')));
  await tester.pumpAndSettle();

  // Select the dev environment
  await tester.tap(envDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('dev'));
  await tester.pumpAndSettle();

  // Verify the environment is saved correctly
  final envBru = loadFile(envBruPath);
  expect(envBru, contains('G_var: added-on-env'));
  expect(
    envBru,
    contains('''vars:secret [
  my_password,
  H_var
]'''),
  );

  // ===========================================================================
  // Send a request
  // ===========================================================================
  server.handler.expect("POST", "/test_endpoint", (request) async {
    sentRequest = request;
    sentRequestBody = await sentRequest!.readAsString();

    return shelf.Response.ok(jsonResponse, headers: {"content-type": "application/json"});
  });

  await tester.tap(sendBtn);
  await tester.pumpAndSettle();

  // print("=====> headers:");
  // for (final header in sentRequest!.headers.entries) {
  //   print("${header.key}: ${header.value}");
  // }

  // Check the headers
  expect(sentRequest!.method, 'POST');
  expect(sentRequest!.headers['a'], "set from collection");
  expect(sentRequest!.headers['b'], "set from folder");
  expect(sentRequest!.headers['c'], "set from folder");
  expect(sentRequest!.headers['d'], "set from collection");
  expect(sentRequest!.headers['e'], "added-by-test");
  expect(sentRequest!.headers['f'], "added-by-test-collection");
  expect(sentRequest!.headers['g'], "added-on-env");
  expect(sentRequest!.headers['h'], "added-on-env-secret!");
  expect(sentRequest!.headers['x-auth-token'], "abcd1234");
  expect(sentRequestBody, '{"hello": "world"}');

  // ===========================================================================
  // Close the request
  // ===========================================================================
  // Restore the original files
  saveFile(folderBruPath, originalFolderBru);
  saveFile(collectionBruPath, originalCollectionBru);
  saveFile(envBruPath, originalEnvBru);

  // Close the open request tab
  await pressCtrlW(tester);
  await tester.pumpAndSettle();

  final yesBtn = find.byKey(const Key('confirm_dialog_yes_btn'));
  await tester.tap(yesBtn);
  await tester.pumpAndSettle();

  await server.close();
}
