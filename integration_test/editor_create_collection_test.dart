import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/support/helpers.dart';

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

  // Find and click the PopupMenuItem with the text "Open Collection", to open collection1
  final openCollectionMenuItem = find.text('New Collection').last;
  await tester.tap(openCollectionMenuItem);
  await tester.pumpAndSettle();

  // Enter collection name
  final searchField = find.byKey(const Key('new_collection_name_input'));
  await tester.enterText(searchField, 'testcoll');

  // Pick a folder
  final browseBtn = find.byKey(const Key('browse_btn'));
  await tester.tap(browseBtn);
  await tester.pumpAndSettle();

  // Click Create
  final createBtn = find.byKey(const Key('create_btn'));
  await tester.tap(createBtn);
  await tester.pumpAndSettle();

  // Verify the collection is created
  final collection = find.text('testcoll');
  expect(collection, findsOneWidget);

  // Delete the folder
  await deleteFolder('./test/support/testcoll');
}
