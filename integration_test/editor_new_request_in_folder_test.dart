import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/support/helpers.dart';
import 'helpers.dart';

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
  final openCollectionMenuItem = find.text('Open Collection');
  await tester.tap(openCollectionMenuItem);

  await tester.pumpAndSettle();

  expect(find.text('collection1'), findsOneWidget);
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('myfolder'), findsOneWidget);
  expect(find.text('my-request'), findsOneWidget);

  // Right-click on the myfolder item
  final myfolderItem = find.text('myfolder');
  await tester.tapAt(tester.getCenter(myfolderItem), buttons: kSecondaryButton);
  await tester.pumpAndSettle();

  // Click New Folder on context menu
  await tester.tap(find.text('New Folder'));
  await tester.pumpAndSettle();

  // Enter the name of the new request
  final renameField = find.byKey(const Key('explorer_rename_input'));
  await tester.enterText(renameField, 'testfolder');
  await tester.pumpAndSettle();

  // Simulate enter key press
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Right-click on the testfolder item
  await tester.tapAt(tester.getCenter(find.text('testfolder')), buttons: kSecondaryButton);
  await tester.pumpAndSettle();

  // Click New Request on context menu
  await tester.tap(find.text('New Request'));
  await tester.pumpAndSettle();

  // Enter the name of the new request
  final searchField = find.byKey(const Key('explorer_rename_input'));
  await tester.enterText(searchField, 'i_am_new');
  await tester.pumpAndSettle();

  // Simulate enter key press
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Verify the file has been created
  final newReqFile = loadFile('test/support/collection1/myfolder/testfolder/i_am_new.bru');
  expect(newReqFile, isNotEmpty);

  // ===========================================================================
  // Close the collection and request
  // ===========================================================================
  // Close the open request tab
  await pressCtrlW(tester);
  await tester.pumpAndSettle();

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

  await deleteFolder('test/support/collection1/myfolder/testfolder');
}

Future<void> pressCtrlS(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}
