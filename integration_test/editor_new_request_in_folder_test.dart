import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/support/helpers.dart';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('editor-sidebar-btn'));
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // Find and click the IconButton with the key 'open_collection_btn'
  final openCollectionBtn = find.byKey(const Key('open_collection_btn'));
  await tester.tap(openCollectionBtn);
  await tester.pumpAndSettle();

  // Find and click the PopupMenuItem with the text "Open Collection"
  final openCollectionMenuItem = find.text('Open Collection');
  await tester.tap(openCollectionMenuItem);

  await tester.pumpAndSettle();

  expect(find.text('collection1'), findsOneWidget);
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('myfolder'), findsOneWidget);
  expect(find.text('my-request.bru'), findsOneWidget);

  // Right-click on the myfolder item
  final myfolderItem = find.text('myfolder');
  await tester.tapAt(tester.getCenter(myfolderItem), buttons: kSecondaryButton);
  await tester.pumpAndSettle();

  // Click New Request on context menu
  final newReqItem = find.text('New Request');
  await tester.tap(newReqItem);
  await tester.pumpAndSettle();

  // Enter the name of the new request
  final searchField = find.byKey(const Key('explorer_rename_input'));
  await tester.enterText(searchField, 'i_am_new.bru');
  await tester.pumpAndSettle();

  // Simulate enter key press
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Verify the file has been created
  final newReqFile = loadFile('test/support/collection1/myfolder/i_am_new.bru');
  expect(newReqFile, isNotEmpty);

  // ===========================================================================
  // Close the collection
  // ===========================================================================
  // Delete the new request file
  await deleteFile('test/support/collection1/myfolder/i_am_new.bru');

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
