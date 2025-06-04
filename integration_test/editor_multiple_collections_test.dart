import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  // Find and click the PopupMenuItem with the text "Open Collection", to open collection1
  final openCollectionMenuItem = find.text('Open Collection');
  await tester.tap(openCollectionMenuItem);
  await tester.pumpAndSettle();

  expect(find.text('collection1'), findsOneWidget);
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('myfolder'), findsOneWidget);
  expect(find.text('my-request.bru'), findsOneWidget);

  // Find and click the IconButton with the key 'open_collection_btn'
  await tester.tap(openCollectionBtn);
  await tester.pumpAndSettle();

  // Find and click the PopupMenuItem with the text "Open Collection", to open collection2
  await tester.tap(openCollectionMenuItem);
  await tester.pumpAndSettle();

  expect(find.text('collection2'), findsOneWidget);
  expect(find.text('test-request.bru'), findsOneWidget);

  // await tester.pumpAndSettle(const Duration(seconds: 3));
}
