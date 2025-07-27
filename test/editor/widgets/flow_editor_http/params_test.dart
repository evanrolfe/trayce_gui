import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

import '../../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;

  setUpAll(() async {
    deps = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
  });

  group('Query Params Form URL Input => Form Table population', () {
    testWidgets('adding query params to the URL1', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;
      expect(paramsController.rows()[0].keyController.text, '');
      expect(paramsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com?a=b';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets('adding query params to the URL', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;
      expect(paramsController.rows()[0].keyController.text, '');
      expect(paramsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com?a=b';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');

      // Add another query param to the URL
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Add a third query param which is the same as the first one
      urlInput.controller.text = 'https://example.com?a=b&c=d&a=b';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 4);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, 'a');
      expect(paramsController.rows()[2].valueController.text, 'b');
      expect(paramsController.rows()[3].keyController.text, '');
      expect(paramsController.rows()[3].valueController.text, '');
    });

    testWidgets('adding only the query param key to the url', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com?a';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, '');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets('pressing backspace to delete a query param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com?a=b';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets('modifying an existing query param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=x&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'x');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');
    });

    testWidgets('pressing back space on the first query param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=x&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      urlInput.controller.text = 'https://example.com?&c=d';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'c');
      expect(paramsController.rows()[0].valueController.text, 'd');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets('an empty first query param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=x&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      urlInput.controller.text = 'https://example.com?&c=d';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'c');
      expect(paramsController.rows()[0].valueController.text, 'd');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });
  });

  group('Query Params Form Table => URL Input', () {
    testWidgets('modifying an existing query param in the table', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 3);

      // Modify the "a" query param from the table
      paramsController.rows()[0].keyController.text = 'x';
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?x=b&c=d');
    });

    testWidgets('an empty first query param value', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Delete the "d" query param from the table
      paramsController.rows()[1].valueController.text = '';
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?a=b&c=');
    });

    testWidgets('an empty first query param key and value', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, 'c');
      expect(paramsController.rows()[1].valueController.text, 'd');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Delete the "d" query param from the table
      paramsController.rows()[1].keyController.text = '';
      paramsController.rows()[1].valueController.text = '';
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?a=b');
    });

    testWidgets('deleting the first query param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 3);

      // Delete the first query pram
      paramsController.deleteRow(0);
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?c=d');

      // Verify the table
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'c');
      expect(paramsController.rows()[0].valueController.text, 'd');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets('deleting the second query param and then entering a new second param', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com?a=b&c=d';

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com?a=b&c=d';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable));
      final paramsController = paramsTable.controller;

      expect(paramsController.rows().length, 3);

      // Delete the first query pram
      paramsController.deleteRow(1);
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?a=b');

      // Verify the table
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'a');
      expect(paramsController.rows()[0].valueController.text, 'b');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');

      // Add a new second query param
      paramsController.rows()[1].keyController.text = 'x';
      paramsController.rows()[1].valueController.text = 'y';
      await tester.pumpAndSettle();

      // Verify the URL
      expect(urlInput.controller.text, 'https://example.com?a=b&x=y');
    });
  });
}
