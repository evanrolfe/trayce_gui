import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/editor.dart';

import '../../support/helpers.dart';
import '../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;

  setUpAll(() async {
    deps = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
  });

  group('Editor', () {
    testWidgets('open collection and CTRL+N to create a new request and save it', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
      final widget = await deps.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open collection1
      final openCollectionBtn = find.byKey(const Key('editor_tabs_open_collection_button'));
      expect(openCollectionBtn, findsOneWidget);
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();
      expect(find.text('collection1'), findsOneWidget);

      // Find and click the three dots icon
      final rootBtn = find.byKey(const Key('collection_btn'));
      await tester.tap(rootBtn);
      await tester.pumpAndSettle();

      // Find and click "New Request"
      final newReqBtn = find.text('New Request');
      expect(newReqBtn, findsOneWidget);
      await tester.tap(newReqBtn);
      await tester.pumpAndSettle();

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(contents, contains('https://example.com'));

      // Cleanup the files
      deleteFile(path);
    });

    testWidgets('new collection and CTRL+N to create a new request and save it', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/');
      when(() => deps.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/test_collection/hello.bru');

      final widget = await deps.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open collection1
      final openCollectionBtn = find.byKey(const Key('editor_tabs_new_collection_button'));
      expect(openCollectionBtn, findsOneWidget);
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();

      // Enter collection name
      final searchField = find.byKey(const Key('new_collection_name_input'));
      await tester.enterText(searchField, 'test_collection');

      // Pick a folder
      final browseBtn = find.byKey(const Key('browse_btn'));
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      // Click Create
      final createBtn = find.byKey(const Key('create_btn'));
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Check collection was created
      final collPath = './test/support/test_collection/collection.bru';
      final collContents = loadFile(collPath);
      expect(collContents, contains('type: collection'));

      // Find and click the three dots icon
      final rootBtn = find.byKey(const Key('collection_btn'));
      await tester.tap(rootBtn);
      await tester.pumpAndSettle();

      // Find and click "New Request"
      final newReqBtn = find.text('New Request');
      expect(newReqBtn, findsOneWidget);
      await tester.tap(newReqBtn);
      await tester.pumpAndSettle();

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      // final reqPath = './test/support/test_collection/hello.bru';
      // final contents = loadFile(reqPath);
      // expect(contents, contains('https://example.com'));

      // Cleanup the files
      deleteFolderSync("test/support/test_collection");
    });
  });
}
