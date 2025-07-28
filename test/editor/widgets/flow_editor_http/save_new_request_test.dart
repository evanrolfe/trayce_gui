import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

import '../../../support/helpers.dart';
import '../../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;

  setUpAll(() async {
    deps = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
  });

  group('Saving a request', () {
    testWidgets('saving a request with body: file', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      await tester.tap(bodyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;
      expect(tableManager.rows().length, 1);

      // Add a file
      tableManager.rows()[0].valueFile = '/home/trayce/x.txt';
      tableManager.rows()[0].contentTypeController.text = 'text/plain';
      await tester.pumpAndSettle();

      // Add a 2nd file
      tableManager.rows()[1].valueFile = '/home/trayce/y.txt';
      tableManager.rows()[1].contentTypeController.text = 'text/plain';
      await tester.pumpAndSettle();

      // Add a 3rd file
      tableManager.rows()[2].valueFile = '/home/trayce/z.json';
      tableManager.rows()[2].contentTypeController.text = 'application/json';

      tableManager.setSelectedRowIndex(2);
      await tester.pumpAndSettle();

      // Listen for events
      EventSaveRequest? eventReceived;
      deps.eventBus.on<EventSaveRequest>().listen((event) {
        eventReceived = event;
      });

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(eventReceived, isNotNull);

      final eventReqBody = eventReceived!.request.getBody() as FileBody;
      expect(eventReceived!.request.bodyType, BodyType.file);
      expect(eventReqBody.files.length, 3);
      expect(eventReqBody.files[0].filePath, '/home/trayce/x.txt');
      expect(eventReqBody.files[0].contentType, 'text/plain');
      expect(eventReqBody.files[1].filePath, '/home/trayce/y.txt');
      expect(eventReqBody.files[1].contentType, 'text/plain');
      expect(eventReqBody.files[2].filePath, '/home/trayce/z.json');
      expect(eventReqBody.files[2].contentType, 'application/json');
    });

    testWidgets('saving a request with variables', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = await deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Click on variables tab
      await tester.tap(find.text('Variables'));
      await tester.pumpAndSettle();

      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;
      expect(tableManager.rows().length, 1);

      // Add a variable
      tableManager.rows()[0].keyController.text = 'A';
      tableManager.rows()[0].valueController.text = 'set-in-request1';
      await tester.pumpAndSettle();

      // Add a 2nd variable
      tableManager.rows()[1].keyController.text = 'B';
      tableManager.rows()[1].valueController.text = 'set-in-request2';
      await tester.pumpAndSettle();

      // Listen for events
      EventSaveRequest? eventReceived;
      deps.eventBus.on<EventSaveRequest>().listen((event) {
        eventReceived = event;
      });

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(eventReceived, isNotNull);

      final request2 = eventReceived!.request;
      expect(request2.requestVars.length, 2);
      expect(request2.requestVars[0].name, 'A');
      expect(request2.requestVars[0].value, 'set-in-request1');
      expect(request2.requestVars[0].enabled, true);

      expect(request2.requestVars[1].name, 'B');
      expect(request2.requestVars[1].value, 'set-in-request2');
      expect(request2.requestVars[1].enabled, true);
    });
  });
}
