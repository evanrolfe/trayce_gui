import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
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

  group('Loading a request', () {
    testWidgets('a request with body: form-urlencoded', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.formUrlEncoded,
        bodyFormUrlEncoded: FormUrlEncodedBody(
          params: [
            Param(name: 'XXXX', value: 'YYYY', type: ParamType.form, enabled: true),
            Param(name: 'ZZZZ', value: 'WWWW', type: ParamType.form, enabled: false),
          ],
        ),
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      expect(tester.widget<DropdownButton2<String>>(bodyTypeDropdown).value, 'Form URL Encoded');

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);
      expect(tableManager.rows()[0].keyController.text, 'XXXX');
      expect(tableManager.rows()[0].valueController.text, 'YYYY');
      expect(tableManager.rows()[0].checkboxState, true);

      expect(tableManager.rows()[1].keyController.text, 'ZZZZ');
      expect(tableManager.rows()[1].valueController.text, 'WWWW');
      expect(tableManager.rows()[1].checkboxState, false);

      expect(tableManager.rows()[2].keyController.text, '');
      expect(tableManager.rows()[2].valueController.text, '');
      expect(tableManager.rows()[2].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: form-multipart', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.multipartForm,
        bodyMultipartForm: MultipartFormBody(
          files: [
            MultipartFile(name: 'XXXX', value: '/home/trayce/x.txt', enabled: true),
            MultipartFile(name: 'ZZZZ', value: '/home/trayce/y.txt', enabled: false),
            MultipartFile(name: 'YYYY', value: '/home/trayce/z.txt', enabled: true, contentType: 'text/plain'),
          ],
        ),
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      expect(tester.widget<DropdownButton2<String>>(bodyTypeDropdown).value, 'Multipart Form');

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 4);
      expect(tableManager.rows()[0].keyController.text, 'XXXX');
      expect(tableManager.rows()[0].valueFile, '/home/trayce/x.txt');
      expect(tableManager.rows()[0].contentTypeController.text, '');
      expect(tableManager.rows()[0].checkboxState, true);

      expect(tableManager.rows()[1].keyController.text, 'ZZZZ');
      expect(tableManager.rows()[1].valueFile, '/home/trayce/y.txt');
      expect(tableManager.rows()[1].contentTypeController.text, '');
      expect(tableManager.rows()[1].checkboxState, false);

      expect(tableManager.rows()[2].keyController.text, 'YYYY');
      expect(tableManager.rows()[2].valueFile, '/home/trayce/z.txt');
      expect(tableManager.rows()[2].contentTypeController.text, 'text/plain');
      expect(tableManager.rows()[2].checkboxState, true);

      expect(tableManager.rows()[3].keyController.text, '');
      expect(tableManager.rows()[3].valueFile, isNull);
      expect(tableManager.rows()[3].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: file', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.file,
        bodyFile: FileBody(
          files: [
            FileBodyItem(filePath: '/home/trayce/y.txt', selected: true),
            FileBodyItem(filePath: '/home/trayce/z.txt', selected: false, contentType: 'text/plain'),
          ],
        ),
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      expect(tester.widget<DropdownButton2<String>>(bodyTypeDropdown).value, 'Files');

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);
      expect(tableManager.selectedRowIndex(), 0);
      expect(tableManager.rows()[0].valueFile, '/home/trayce/y.txt');
      expect(tableManager.rows()[0].contentTypeController.text, '');

      expect(tableManager.rows()[1].valueFile, '/home/trayce/z.txt');
      expect(tableManager.rows()[1].contentTypeController.text, 'text/plain');

      expect(tableManager.rows()[2].valueFile, isNull);
      expect(tableManager.rows()[2].contentTypeController.text, '');

      await tester.pumpAndSettle();
    });

    testWidgets('a request with vars', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.none,
        params: [],
        headers: [],
        requestVars: [
          Variable(name: 'A', value: 'set-in-request1', enabled: true),
          Variable(name: 'B', value: 'set-in-request2', enabled: false),
        ],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Click on variables tab
      await tester.tap(find.text('Variables'));
      await tester.pumpAndSettle();

      // Verify variables
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);
      expect(tableManager.rows()[0].keyController.text, 'A');
      expect(tableManager.rows()[0].valueController.text, 'set-in-request1');
      expect(tableManager.rows()[0].checkboxState, true);

      expect(tableManager.rows()[1].keyController.text, 'B');
      expect(tableManager.rows()[1].valueController.text, 'set-in-request2');
      expect(tableManager.rows()[1].checkboxState, false);

      expect(tableManager.rows()[2].keyController.text, '');
      expect(tableManager.rows()[2].valueController.text, '');
      expect(tableManager.rows()[2].checkboxState, false);

      await tester.pumpAndSettle();
    });
  });
}
