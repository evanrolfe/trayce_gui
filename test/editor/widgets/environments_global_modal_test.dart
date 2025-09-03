import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/common/environments_global_modal.dart';
import 'package:trayce/editor/models/global_environment.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';

import '../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;
  late WidgetDependencies deps2;
  late WidgetDependencies deps3;
  late WidgetDependencies deps4;
  setUpAll(() async {
    deps = await setupTestDependencies();
    deps2 = await setupTestDependencies();
    deps3 = await setupTestDependencies();
    deps4 = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
    await deps2.close();
    await deps3.close();
    await deps4.close();
  });

  group('Environment Modal', () {
    testWidgets('creating a new environment and saving some vars', (WidgetTester tester) async {
      await deps.appStorage.deleteGlobalEnvVars();

      // Create a test app with a button to show the modal
      final testApp = deps.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showGlobalEnvironmentsModal(context),
                    child: const Text('Show Modal'),
                  ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show "No environments found" message
      expect(find.text('No global environments found.'), findsOneWidget);
      expect(find.text('New Environment'), findsOneWidget);

      // Click the "New Environment" button
      await tester.tap(find.text('New Environment'));
      await tester.pumpAndSettle();

      // Now we should see the environment tab and form table
      // Get the form table and add variables directly
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      // Add a regular variable
      expect(tableManager.rows().length, 1);
      tableManager.rows()[0].keyController.text = 'API_URL';
      tableManager.rows()[0].valueController.text = 'https://api.example.com';
      await tester.pumpAndSettle();

      // Add a second variable (this will automatically create a new row)
      tableManager.rows()[1].keyController.text = 'API_KEY';
      tableManager.rows()[1].valueController.text = 'secret123';
      await tester.pumpAndSettle();

      // Save the environment
      final saveButton = find.byKey(const ValueKey('save_btn'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final envs = deps.globalEnvironmentRepo.getAll();
      expect(envs.length, 1);
      expect(envs[0].name, 'Untitled');
      expect(envs[0].vars.length, 2);
      expect(envs[0].vars[0].name, 'API_URL');
      expect(envs[0].vars[0].value, 'https://api.example.com');
      expect(envs[0].vars[1].name, 'API_KEY');
      expect(envs[0].vars[1].value, 'secret123');
    });

    testWidgets('modal shows an environment with no vars', (WidgetTester tester) async {
      // Create a global environment
      // await deps2.appStorage.deleteGlobalEnvVars();
      await deps2.globalEnvironmentRepo.save([GlobalEnvironment(name: 'test', vars: [])]);

      // Create a test app with a button to show the modal
      final testApp = deps2.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showGlobalEnvironmentsModal(context),
                    child: const Text('Show Modal'),
                  ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Modal should now be visible
      expect(find.text('Global Environments'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Verify vars
      final formTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 1);
    });

    testWidgets('modal shows an environment with vars', (WidgetTester tester) async {
      // Create a global environment
      await deps3.globalEnvironmentRepo.save([
        GlobalEnvironment(
          name: 'test',
          vars: [
            Variable(name: 'API_URL', value: 'https://api.example.com', enabled: true),
            Variable(name: 'API_KEY', value: 'secret123', enabled: true),
          ],
        ),
      ]);

      // Create a test app with a button to show the modal
      final testApp = deps3.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showGlobalEnvironmentsModal(context),
                    child: const Text('Show Modal'),
                  ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Modal should now be visible
      expect(find.text('Global Environments'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Verify vars
      final formTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);
    });

    // testWidgets('renaming an environment', (WidgetTester tester) async {
    //   // Create a global environment
    //   await deps4.globalEnvironmentRepo.save([
    //     GlobalEnvironment(
    //       name: 'test',
    //       vars: [
    //         Variable(name: 'API_URL', value: 'https://api.example.com', enabled: true),
    //         Variable(name: 'API_KEY', value: 'secret123', enabled: true),
    //       ],
    //     ),
    //   ]);

    //   // Create a test app with a button to show the modal
    //   final testApp = deps4.wrapWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: Builder(
    //           builder:
    //               (context) => ElevatedButton(
    //                 onPressed: () => showGlobalEnvironmentsModal(context),
    //                 child: const Text('Show Modal'),
    //               ),
    //         ),
    //       ),
    //     ),
    //   );

    //   await tester.pumpWidget(testApp);
    //   await tester.pumpAndSettle();

    //   // Tap button to show modal
    //   await tester.tap(find.text('Show Modal'));
    //   await tester.pumpAndSettle(const Duration(seconds: 1));

    //   // Modal should now be visible
    //   expect(find.text('Global Environments'), findsOneWidget);
    //   expect(find.byType(Dialog), findsOneWidget);

    //   // Click the edit icon to enable renaming
    //   await tester.tap(find.byIcon(Icons.edit));
    //   await tester.pumpAndSettle();

    //   // Verify the value of the environments_modal_name_input
    //   final nameInput = find.byKey(const Key('global_envs_modal_name_input'));
    //   expect(nameInput, findsOneWidget);
    //   final textField = tester.widget<TextField>(nameInput);
    //   expect(textField.controller?.text, 'test');

    //   // Change the value
    //   await tester.enterText(nameInput, 'renamed_env');
    //   await tester.pumpAndSettle();
    //   expect(textField.controller?.text, 'renamed_env');

    //   // Press Enter to submit
    //   // THIS FAILS TO TRIGGER THE onSubmitted callback
    //   await pressEnter(tester);
    //   await tester.pumpAndSettle();

    //   expect(deps4.globalEnvironmentRepo.getAll().length, 1);
    //   expect(deps4.globalEnvironmentRepo.getAll()[0].name, 'renamed_env');
    // });
  });
}
