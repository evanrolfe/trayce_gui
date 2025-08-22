import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/editor.dart';

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

  group('Editor Global Env', () {
    testWidgets('open collection, create a new global env, select a global env', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final widget = deps.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open collection1
      final openCollectionBtn = find.byKey(const Key('editor_tabs_open_collection_button'));
      expect(openCollectionBtn, findsOneWidget);
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();
      expect(find.text('collection1'), findsOneWidget);

      // Find and click the global envs dropdown button
      final dropdownBtn = find.byKey(const Key('editor_tabs_global_envs_button'));
      await tester.tap(dropdownBtn);
      await tester.pumpAndSettle();

      // Find and click "New Global Environment"
      final newGlobalEnvBtn = find.text('Configure');
      expect(newGlobalEnvBtn, findsOneWidget);
      await tester.tap(newGlobalEnvBtn);
      await tester.pumpAndSettle();

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

      // Click the dropdown button again
      await tester.tap(dropdownBtn);
      await tester.pumpAndSettle();

      // Should show the new environment in the dropdown
      expect(find.text('Untitled'), findsOneWidget);

      // Click the new environment
      await tester.tap(find.text('Untitled'));
      await tester.pumpAndSettle();

      // Verify the global env is selected
      final selectedEnv = deps.globalEnvironmentRepo.getSelectedEnv();
      expect(selectedEnv?.name, 'Untitled');
      expect(selectedEnv?.vars.length, 2);
      expect(selectedEnv?.vars[0].name, 'API_URL');
      expect(selectedEnv?.vars[0].value, 'https://api.example.com');
      expect(selectedEnv?.vars[1].name, 'API_KEY');
      expect(selectedEnv?.vars[1].value, 'secret123');
    });
  });
}
