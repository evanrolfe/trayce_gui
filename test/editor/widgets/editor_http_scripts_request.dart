import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
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

  group('Editor HTTP Request Scripts', () {
    // Sets up the editor
    Future<(Widget, dynamic)> initWidget(WidgetTester tester, WidgetDependencies widgetDeps) async {
      await tester.binding.setSurfaceSize(const Size(1600, 800));

      // Init widget
      final widget = widgetDeps.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open collection1
      final openCollectionBtn = find.byKey(const Key('editor_tabs_open_collection_button'));
      expect(openCollectionBtn, findsOneWidget);
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();
      expect(find.text('collection1'), findsOneWidget);

      return (widget, null);
    }

    testWidgets('new request with pre-request script, save, and send', (WidgetTester tester) async {
      // Store original error handler and set custom one
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
      when(() => deps.httpClient.send(any(), any())).thenAnswer((_) async => http.Response('Mocked Response', 200));

      await initWidget(tester, deps);
      await tester.pumpAndSettle();

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
      urlInput.controller.text = 'https://example.com/';
      await tester.pumpAndSettle();

      // Click Script tab
      await tester.tap(find.text('Script'));
      await tester.pumpAndSettle();

      // Change the pre-request script
      final preRequestEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      preRequestEditor.controller.text = 'console.log("Hello, World!");';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(contents, contains('https://example.com/'));

      expect(
        contents,
        contains('''script:pre-request {
  console.log("Hello, World!");
}'''),
      );

      deleteFile(path);
    });
  });
}
