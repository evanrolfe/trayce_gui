import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/headers_table.dart';

import '../test/support/helpers.dart';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  final oneBruPath = 'test/support/collection1/myfolder/one.bru';
  final originalOneBru = loadFile(oneBruPath);

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('editor-sidebar-btn'));
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // Find and click the IconButton with the key 'collection_btn'
  final openCollectionBtn = find.byKey(const Key('collection_btn'));
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
  // Change the request body
  // ===========================================================================
  // Click the Body tab
  await tester.tap(find.text('Body'));
  await tester.pumpAndSettle();

  // Find the MultiLineCodeEditor and get its controller
  final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);

  // Change the body text
  bodyEditor.controller.text = 'ivechanged!';
  await tester.pumpAndSettle();

  // Expect to see a * indicating modified state
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // Change it back to original content
  bodyEditor.controller.text = '{"hello": "world"}';
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Change the URL
  // ===========================================================================
  final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
  expect(urlInput.controller.text, 'http://www.github.com/one');

  // Change the URL
  urlInput.controller.text = 'http://www.github.com/oneX';
  await tester.pumpAndSettle();

  // Expect to see a *
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // Change the URL back to the original
  urlInput.controller.text = 'http://www.github.com/one';
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Change the Method
  // ===========================================================================
  final methodDropdown = find.byKey(const Key('flow_editor_http_method_dropdown')).first;

  // Select DELETE method
  await tester.tap(methodDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('DELETE'));
  await tester.pumpAndSettle();

  // Expect to see a * indicating modified state
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // Select POST method
  await tester.tap(methodDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('POST'));
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Change a Header
  // ===========================================================================
  // Click the Headers tab
  await tester.tap(find.text('Headers').first);
  await tester.pumpAndSettle();

  final headersTable = tester.widget<HeadersTable>(find.byType(HeadersTable));
  final headersManager = headersTable.stateManager;

  // Change the key text of the first header row
  headersManager.rows[0].keyController.text = 'XXXX';
  await tester.pumpAndSettle();

  // Expect to see a * indicating modified state
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // Change it back
  headersManager.rows[0].keyController.text = 'hello';
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Disable a Header
  // ===========================================================================
  // Un-check the checkbox of the first header row
  final headersTableWidget = find.byType(HeadersTable);
  final checkbox = find.descendant(of: headersTableWidget, matching: find.byType(Checkbox));
  await tester.tap(checkbox.first);
  await tester.pumpAndSettle();

  // Expect to see a * indicating modified state
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // Check the checkbox of the first header row
  await tester.tap(checkbox.first);
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Add a Header
  // ===========================================================================
  // Change the key text of the first header row
  headersManager.rows[headersManager.rows.length - 1].keyController.text = 'Im A';
  headersManager.rows[headersManager.rows.length - 2].valueController.text = 'New Header!';
  await tester.pumpAndSettle();

  // Expect to see a * indicating modified state
  expect(find.text('one*'), findsOneWidget);
  await tester.pumpAndSettle();

  // ===========================================================================
  // Delete a Header
  // ===========================================================================
  // Find and click the delete button for the first header row
  final deleteButtons = find.descendant(of: headersTableWidget, matching: find.byIcon(Icons.close));
  await tester.tap(deleteButtons.at(deleteButtons.evaluate().length - 2));
  await tester.pumpAndSettle();

  // Expect NOT to see a *
  expect(find.text('one*'), findsNothing);
  await tester.pumpAndSettle();

  // Expect the file to be unchanged
  expect(loadFile(oneBruPath), originalOneBru);

  // ===========================================================================
  // Close the collection
  // ===========================================================================
  // Right-click on collection1
  final coll1 = find.text('collection1');
  await tester.tapAt(tester.getCenter(coll1), buttons: kSecondaryButton);
  await tester.pumpAndSettle();

  // Click open on Close Collection
  final closeItem = find.text('Close Collection');
  await tester.tap(closeItem);
  await tester.pumpAndSettle();

  // await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> pressCtrlS(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}
