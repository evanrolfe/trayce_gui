import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/editor.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_bearer_form.dart';

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

  group('Editor HTTP Auth Bearer', () {
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

    testWidgets('new request with bearer auth and save', (WidgetTester tester) async {
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
      await tester.tap(find.text('Bearer Token'));
      await tester.pumpAndSettle();

      // Verify the Auth form
      final authForm = tester.widget<AuthBearerForm>(find.byType(AuthBearerForm).first);
      final authController = authForm.controller;

      authController.getTokenController().text = 'asdf';

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the request is saved
      final path = './test/support/collection1/hello.bru';
      final contents = loadFile(path);
      expect(contents, contains('https://example.com/'));

      expect(
        contents,
        contains('''auth:bearer {
  token: asdf
}'''),
      );
      // Cleanup the files
      deleteFile(path);
    });

    testWidgets('open a request with bearer auth, modify it, and save', (WidgetTester tester) async {
      // Create the request
      final reqPath = './test/support/collection1/auth-bearer-test.bru';
      saveFile(reqPath, '''meta {
  name: auth-bearer-test
  type: http
  seq: 0
}

get {
  url: https://trayce.dev
  auth: bearer
}

auth:bearer {
  token: helloworld
}''');

      // Open collection
      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');

      await initWidget(tester, deps2);
      await tester.pumpAndSettle();

      // Click on my-request.bru request
      final myReq = find.text('auth-bearer-test').first;
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
      expect(find.text('Bearer Token'), findsOneWidget);

      // Verify the Auth form
      final authForm = tester.widget<AuthBearerForm>(find.byType(AuthBearerForm).first);
      final authController = authForm.controller;

      // authController.usernameController.text = 'admin';
      expect(authController.getTokenController().text, 'helloworld');
      await tester.pumpAndSettle();

      // Modify the auth form
      authController.getTokenController().text = 'helloworldx';
      await tester.pumpAndSettle();

      // Check the tab title has a *
      expect(find.text('auth-bearer-test*'), findsOneWidget);

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Check the tab title no longer has a *
      expect(find.text('auth-bearer-test*'), findsNothing);

      // Cleanup
      deleteFile(reqPath);
    });
  });
}
