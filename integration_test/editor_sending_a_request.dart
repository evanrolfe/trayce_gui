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

import 'helpers.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';
const expectedFormattedJson = '''{
  "message": "Hello, World!",
  "status": 200
}''';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('editor-sidebar-btn'));
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // Find and click the IconButton with the key 'collection_btn'
  final openCollectionBtn = find.byKey(const Key('collection_btn'));
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
  final headersManager = headersTable.stateManager;

  headersManager.rows[0].keyController.text = 'X-Auth-Token';
  headersManager.rows[0].valueController.text = '1234abcd';
  await tester.pumpAndSettle();

  headersManager.rows[1].keyController.text = 'Content-Type';
  headersManager.rows[1].valueController.text = 'application/json';
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
  // Open a collection
  // ===========================================================================
  // Find and click the IconButton with the key 'collection_btn'
  await tester.tap(openCollectionBtn);
  await tester.pumpAndSettle();

  // Find and click the PopupMenuItem with the text "Open Collection"
  final openCollectionMenuItem = find.text('Open Collection');
  await tester.tap(openCollectionMenuItem);
  await tester.pumpAndSettle();

  expect(find.text('collection1'), findsOneWidget);
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('myfolder'), findsOneWidget);
  expect(find.text('my-request'), findsOneWidget);

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
  // Change the URL, Method, Body & Headers
  // ===========================================================================
  // Change the URL
  final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')).last);
  urlInput2.controller.text = path.join(server.url.toString(), 'test_endpoint');
  await tester.pumpAndSettle();

  // Set a header
  await tester.tap(find.text('Headers').first);
  await tester.pumpAndSettle();
  final headersTable2 = tester.widget<FormTable>(find.byType(FormTable));
  final headersManager2 = headersTable2.stateManager;

  headersManager2.rows[2].keyController.text = 'HI';
  headersManager2.rows[2].valueController.text = 'ivebeensetontehform';
  await tester.pumpAndSettle();

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

  // Che
  expect(sentRequest!.method, 'POST');
  expect(sentRequest!.headers['hello'], 'world');
  expect(sentRequest!.headers['hey'], "i'm from the folder");
  expect(sentRequest!.headers['heythere'], "im the collection");
  expect(sentRequest!.headers['HI'], "ivebeensetontehform");
  expect(sentRequestBody, '{"hello": "world"}');

  // ===========================================================================
  // Close the request
  // ===========================================================================
  // Close the open request tab
  await pressCtrlW(tester);
  await tester.pumpAndSettle();

  final yesBtn = find.byKey(const Key('confirm_dialog_yes_btn'));
  await tester.tap(yesBtn);
  await tester.pumpAndSettle();

  await server.close();
}
