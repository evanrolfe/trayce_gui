import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';

Future<void> test(WidgetTester tester) async {
  await tester.pumpAndSettle();

  // Find and click the Network tab
  final networkTab = find.byIcon(Icons.edit);
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

  // Click on the myfolder item
  final myfolderItem = find.text('myfolder');
  await tester.tap(myfolderItem);
  await tester.pumpAndSettle();

  // Right-click on one.bru request
  final oneReq = find.text('one.bru');
  await tester.tapAt(tester.getCenter(oneReq), buttons: 2);
  await tester.pumpAndSettle();

  // Click open on context menu
  final openItem = find.text('Open');
  await tester.tap(openItem);
  await tester.pumpAndSettle();

  final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
  expect(urlInput.controller.text, 'http://www.github.com/one');

  // Right-click on two.bru request
  final twoReq = find.text('two.bru');
  await tester.tapAt(tester.getCenter(twoReq), buttons: 2);
  await tester.pumpAndSettle();

  // Click open on context menu
  final openItem2 = find.text('Open');
  await tester.tap(openItem2);
  await tester.pumpAndSettle();

  final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
  expect(urlInput2.controller.text, 'http://trayce.dev/two');

  // await tester.pumpAndSettle(const Duration(seconds: 5));
}
