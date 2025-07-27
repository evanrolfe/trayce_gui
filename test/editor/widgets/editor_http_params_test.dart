import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
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

  group('Editor HTTP Params', () {
    testWidgets('new request with params and save', (WidgetTester tester) async {
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

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Enter params
      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 1);
      paramsController.rows()[0].keyController.text = 'a';
      paramsController.rows()[0].valueController.text = 'b';
      await tester.pumpAndSettle();

      expect(paramsController.rows().length, 2);
      paramsController.rows()[1].keyController.text = 'c';
      paramsController.rows()[1].valueController.text = 'd';

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(contents, contains('https://example.com?a=b&c=d'));
      expect(
        contents,
        contains('''params:query {
  a: b
  c: d
}'''),
      );

      // Cleanup the files
      deleteFile(path);
    });
  });
}
