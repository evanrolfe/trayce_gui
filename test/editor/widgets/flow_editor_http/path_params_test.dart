import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';

import '../../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;
  final collection = Collection(
    file: File('test.collection'),
    dir: Directory('test.collection'),
    type: 'http',
    environments: [],
    headers: [],
    query: [],
    authType: AuthType.none,
    requestVars: [],
    responseVars: [],
  );

  setUpAll(() async {
    deps = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
  });

  group('Path Params Form URL Input => Form Table population', () {
    testWidgets('loading a request with path params', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com/users/:id/show/:fields';
      request.params = [
        Param(name: 'id', value: '1', type: ParamType.path, enabled: true),
        Param(name: 'fields', value: 'name,age', type: ParamType.path, enabled: true),
      ];

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(
        FlowEditorHttp(
          collectionNode: CollectionNode(name: 'Test Collection', collection: collection, children: []),
          request: request,
          tabKey: tabKey,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com/users/:id/show/:fields');
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final paramsController = paramsTable.controller;

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'id');
      expect(paramsController.rows()[0].valueController.text, '1');
      expect(paramsController.rows()[1].keyController.text, 'fields');
      expect(paramsController.rows()[1].valueController.text, 'name,age');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');
    });

    testWidgets('adding path params to the URL, and adding values to the URL, then adding more path params', (
      WidgetTester tester,
    ) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(
        FlowEditorHttp(
          collectionNode: CollectionNode(name: 'Test Collection', collection: collection, children: []),
          request: request,
          tabKey: tabKey,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final paramsController = paramsTable.controller;
      expect(paramsController.rows()[0].keyController.text, '');
      expect(paramsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com/users/:id/show/:fields';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'id');
      expect(paramsController.rows()[0].valueController.text, '');
      expect(paramsController.rows()[1].keyController.text, 'fields');
      expect(paramsController.rows()[1].valueController.text, '');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Add values to the path params
      paramsController.rows()[0].valueController.text = '1';
      paramsController.rows()[1].valueController.text = '2';
      await tester.pumpAndSettle();

      // Add more path params to the URL
      urlInput.controller.text = 'https://example.com/:version/users/:id/show/:fields';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 4);
      expect(paramsController.rows()[0].keyController.text, 'version');
      expect(paramsController.rows()[0].valueController.text, '');
      expect(paramsController.rows()[1].keyController.text, 'id');
      expect(paramsController.rows()[1].valueController.text, '1');
      expect(paramsController.rows()[2].keyController.text, 'fields');
      expect(paramsController.rows()[2].valueController.text, '2');
      expect(paramsController.rows()[3].keyController.text, '');
      expect(paramsController.rows()[3].valueController.text, '');
    });

    testWidgets('adding path params to the URL, and adding values to the URL, then deleting a path param', (
      WidgetTester tester,
    ) async {
      // Create a test request
      final request = Request.blank();

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(
        FlowEditorHttp(
          collectionNode: CollectionNode(name: 'Test Collection', collection: collection, children: []),
          request: request,
          tabKey: tabKey,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();

      // Click on Params tab
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final paramsController = paramsTable.controller;
      expect(paramsController.rows()[0].keyController.text, '');
      expect(paramsController.rows()[0].valueController.text, '');
      await tester.pumpAndSettle();

      // Add a query param to the URL
      urlInput.controller.text = 'https://example.com/users/:id/show/:fields';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 3);
      expect(paramsController.rows()[0].keyController.text, 'id');
      expect(paramsController.rows()[0].valueController.text, '');
      expect(paramsController.rows()[1].keyController.text, 'fields');
      expect(paramsController.rows()[1].valueController.text, '');
      expect(paramsController.rows()[2].keyController.text, '');
      expect(paramsController.rows()[2].valueController.text, '');

      // Add values to the path params
      paramsController.rows()[0].valueController.text = '1';
      paramsController.rows()[1].valueController.text = '2';
      await tester.pumpAndSettle();

      // Add more path params to the URL
      urlInput.controller.text = 'https://example.com/show/:fields';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'fields');
      expect(paramsController.rows()[0].valueController.text, '2');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');
    });

    testWidgets(
      'adding path params to the URL, and adding values to the URL, then adding more path params in the middle',
      (WidgetTester tester) async {
        // Create a test request
        final request = Request.blank();

        final tabKey = const ValueKey('test_tab');
        final widget = deps.wrapWidget(
          FlowEditorHttp(
            collectionNode: CollectionNode(name: 'Test Collection', collection: collection, children: []),
            request: request,
            tabKey: tabKey,
          ),
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Set URL
        final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
        urlInput.controller.text = 'https://example.com';
        await tester.pumpAndSettle();

        // Click on Params tab
        await tester.tap(find.text('Params'));
        await tester.pumpAndSettle();

        // Verify the params
        final paramsTable = tester.widget<FormTable>(find.byType(FormTable).last);
        final paramsController = paramsTable.controller;
        expect(paramsController.rows()[0].keyController.text, '');
        expect(paramsController.rows()[0].valueController.text, '');
        await tester.pumpAndSettle();

        // Add a query param to the URL
        urlInput.controller.text = 'https://example.com/users/:id/show/:fields';
        await tester.pumpAndSettle();

        // Verify the params
        expect(paramsController.rows().length, 3);
        expect(paramsController.rows()[0].keyController.text, 'id');
        expect(paramsController.rows()[0].valueController.text, '');
        expect(paramsController.rows()[1].keyController.text, 'fields');
        expect(paramsController.rows()[1].valueController.text, '');
        expect(paramsController.rows()[2].keyController.text, '');
        expect(paramsController.rows()[2].valueController.text, '');

        // Add values to the path params
        paramsController.rows()[0].valueController.text = '1';
        paramsController.rows()[1].valueController.text = '2';
        await tester.pumpAndSettle();

        // Add more path params to the URL
        urlInput.controller.text = 'https://example.com/users/:id/:name/show/:fields';
        await tester.pumpAndSettle();

        // Verify the params
        expect(paramsController.rows().length, 4);
        expect(paramsController.rows()[0].keyController.text, 'id');
        expect(paramsController.rows()[0].valueController.text, '1');
        expect(paramsController.rows()[1].keyController.text, 'name');
        expect(paramsController.rows()[1].valueController.text, '');
        expect(paramsController.rows()[2].keyController.text, 'fields');
        expect(paramsController.rows()[2].valueController.text, '2');
        expect(paramsController.rows()[3].keyController.text, '');
        expect(paramsController.rows()[3].valueController.text, '');
      },
    );

    testWidgets('loading a request with path params, then deleting them', (WidgetTester tester) async {
      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com/users/:id/show/:fields';
      request.params = [
        Param(name: 'id', value: '1', type: ParamType.path, enabled: true),
        Param(name: 'fields', value: 'name,age', type: ParamType.path, enabled: true),
      ];

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(
        FlowEditorHttp(
          collectionNode: CollectionNode(name: 'Test Collection', collection: collection, children: []),
          request: request,
          tabKey: tabKey,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Params'));
      await tester.pumpAndSettle();

      // Change the URL to delete the :fields path param
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com/users/:id/show/:fields');
      urlInput.controller.text = 'https://example.com/users/:id/';
      await tester.pumpAndSettle();

      // Verify the params
      final paramsTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final paramsController = paramsTable.controller;
      expect(paramsController.rows().length, 2);
      expect(paramsController.rows()[0].keyController.text, 'id');
      expect(paramsController.rows()[0].valueController.text, '1');
      expect(paramsController.rows()[1].keyController.text, '');
      expect(paramsController.rows()[1].valueController.text, '');

      // Change the URL to delete the :id path param
      urlInput.controller.text = 'https://example.com/';
      await tester.pumpAndSettle();

      // Verify the params
      expect(paramsController.rows().length, 1);
      expect(paramsController.rows()[0].keyController.text, '');
      expect(paramsController.rows()[0].valueController.text, '');
    });
  });
}
