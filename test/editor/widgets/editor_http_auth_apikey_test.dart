import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/editor.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_api_key_form.dart';

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

  group('Editor HTTP Auth ApiKey', () {
    // Sets up the editor
    Future<(Widget, dynamic)> initWidget(WidgetTester tester, WidgetDependencies widgetDeps) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;
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

    testWidgets('new request with apikey auth and save', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
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

      // Click auth tab
      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle();

      // Select Auth type
      final authTypeDropdown = find.byKey(const Key('flow_editor_http_auth_type_dropdown')).first;
      await tester.tap(authTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('API Key'));
      await tester.pumpAndSettle();

      // Populate the Auth form
      final authForm = tester.widget<AuthApiKeyForm>(find.byType(AuthApiKeyForm).first);
      final authController = authForm.controller;

      authController.getKeyController().text = 'X-Api-Key';
      authController.getValueController().text = '1234abcd';

      // Select placement
      final placementDropdown = find.byKey(const Key('flow_editor_auth_api_key_placement_dropdown')).first;
      await tester.tap(placementDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('queryparams'));
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
        contains('''auth:apikey {
  key: X-Api-Key
  value: 1234abcd
  placement: queryparams
}'''),
      );
      // Cleanup the files
      deleteFile(path);
    });

    testWidgets('open a request with apikey auth, modify it, and save', (WidgetTester tester) async {
      // Create the request
      final reqPath = './test/support/collection1/auth-apikey-test.bru';
      saveFile(reqPath, '''meta {
  name: auth-apikey-test
  type: http
  seq: 0
}

get {
  url: https://trayce.dev
  auth: apikey
}

auth:apikey {
  key: X-Api-Key
  value: 1234abcd
  placement: queryparams
}''');

      // Open collection
      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');

      await initWidget(tester, deps2);
      await tester.pumpAndSettle();

      // Click on my-request.bru request
      final myReq = find.text('auth-apikey-test').first;
      expect(myReq, findsOneWidget);
      await tester.tapAt(tester.getCenter(myReq));
      await tester.tapAt(tester.getCenter(myReq));
      await tester.pumpAndSettle();

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);

      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://trayce.dev');
      await tester.pumpAndSettle();

      // Click auth tab
      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle();

      // Verify Auth type
      expect(find.text('API Key'), findsOneWidget);

      // Verify the Auth form
      final authForm = tester.widget<AuthApiKeyForm>(find.byType(AuthApiKeyForm).first);
      final authController = authForm.controller;

      // authController.usernameController.text = 'admin';
      expect(authController.getKeyController().text, 'X-Api-Key');
      expect(authController.getValueController().text, '1234abcd');
      await tester.pumpAndSettle();
      expect(authController.getPlacement().name, 'queryparams');

      // Modify the auth form
      authController.getKeyController().text = 'X-Api-Key';
      authController.getValueController().text = '1234abcdNEW';
      await tester.pumpAndSettle();

      // Check the tab title has a *
      expect(find.text('auth-apikey-test*'), findsOneWidget);

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Check the tab title no longer has a *
      expect(find.text('auth-apikey-test*'), findsNothing);

      // Cleanup
      deleteFile(reqPath);
    });
  });
}
