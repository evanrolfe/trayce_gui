import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/widgets/code_editor/url_input.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_basic_form.dart';
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

  group('Auth Basic', () {
    testWidgets('loading a request with basic auth', (WidgetTester tester) async {
      FlutterError.onError = ignoreOverflowErrors;

      // Create a test request
      final request = Request.blank();
      request.url = 'https://example.com/users/:id/show/:fields';
      request.authType = AuthType.basic;
      request.authBasic = BasicAuth(username: 'asdf', password: 'xxx');

      final tabKey = const ValueKey('test_tab');
      final widget = deps.wrapWidget(FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set URL
      final urlInput = tester.widget<URLInput>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com/users/:id/show/:fields');
      await tester.pumpAndSettle();

      // Click on Auth tab
      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle();

      // Verify the Auth form
      final authForm = tester.widget<AuthBasicForm>(find.byType(AuthBasicForm).first);
      final authController = authForm.controller;

      expect(authController.usernameController.text, 'asdf');
      expect(authController.passwordController.text, 'xxx');
    });
  });
}
