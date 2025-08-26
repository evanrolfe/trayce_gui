import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/editor.dart';

import '../../support/helpers.dart';
import '../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;
  late WidgetDependencies deps2;

  setUpAll(() async {
    deps = await setupTestDependencies();
    deps2 = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
    await deps2.close();
  });

  group('Editor HTTP Vars', () {
    testWidgets('new request with pre-request vars and save', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
      final widget = deps.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
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

      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com/users/:id/show/:fields';
      await tester.pumpAndSettle();

      // Click auth tab
      await tester.tap(find.text('Variables'));
      await tester.pumpAndSettle();

      // Enter params
      final varsTable = tester.widget<FormTable>(find.byType(FormTable).first);
      final varsController = varsTable.controller;

      expect(varsController.rows().length, 1);
      expect(varsController.rows()[0].keyController.text, '');
      expect(varsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      varsController.rows()[0].keyController.text = 'X';
      varsController.rows()[0].valueController.text = '"hello"';

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(
        contents,
        contains('''vars:pre-request {
  X: "hello"
}'''),
      );
      // Cleanup the files
      deleteFile(path);
    });

    testWidgets('new request with post-response vars and save', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps2.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
      final widget = deps2.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
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

      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com/users/:id/show/:fields';
      await tester.pumpAndSettle();

      // Click auth tab
      await tester.tap(find.text('Variables'));
      await tester.pumpAndSettle();

      // Enter params
      final varsTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final varsController = varsTable.controller;

      expect(varsController.rows().length, 1);
      expect(varsController.rows()[0].keyController.text, '');
      expect(varsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      varsController.rows()[0].keyController.text = 'X';
      varsController.rows()[0].valueController.text = '"hello"';

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(
        contents,
        contains('''vars:post-response {
  X: "hello"
}'''),
      );
      // Cleanup the files
      deleteFile(path);
    });
  });
}
