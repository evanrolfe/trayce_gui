import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/settings.dart';

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

  group('Settings', () {
    testWidgets('editor settings', (WidgetTester tester) async {
      FlutterError.onError = ignoreOverflowErrors;

      // Create a test app with a button to show the modal
      final testApp = await deps.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) =>
                      ElevatedButton(onPressed: () => showSettingsModal(context), child: const Text('Show Modal')),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Modal should now be visible
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Click on the Editor settings
      expect(find.text('Editor'), findsOneWidget);
      await tester.tap(find.text('Editor'));
      await tester.pumpAndSettle();

      // Verify the npm command input exists and can be accessed
      expect(find.byKey(const Key('editor_nodejs_command_input')), findsOneWidget);
      final npmCommandInput = tester.widget<TextField>(find.byKey(const Key('editor_nodejs_command_input')));
      npmCommandInput.controller!.text = 'npm_test';
      await tester.pumpAndSettle();

      // Click the Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify its been saved to app storage
      final npmCommand = await deps.appStorage.getConfigValue('npmCommand');
      expect(npmCommand, 'npm_test');

      final config = deps.configRepo.get();
      expect(config.npmCommand, 'npm_test');
    });
  });
}
