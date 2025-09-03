import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/editor.dart';

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

  group('Editor Runtime Vars Modal', () {
    testWidgets('view runtime vars', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      deps.runtimeVarsRepo.setVar('API_URL', 'https://api.example.com');
      deps.runtimeVarsRepo.setVar('API_KEY', 'secret123');

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
      final dropdownBtn = find.byKey(const Key('editor_tabs_runtime_vars_button'));
      await tester.tap(dropdownBtn);
      await tester.pumpAndSettle();

      expect(find.text('Runtime Variables'), findsOneWidget);

      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);
      expect(tableManager.rows()[0].keyController.text, 'API_URL');
      expect(tableManager.rows()[0].valueController.text, 'https://api.example.com');
      expect(tableManager.rows()[1].keyController.text, 'API_KEY');
      expect(tableManager.rows()[1].valueController.text, 'secret123');
    });

    testWidgets('save new runtime vars', (WidgetTester tester) async {
      // Init widget
      FlutterError.onError = ignoreOverflowErrors;

      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final widget = deps2.wrapWidget(SizedBox(width: 1600, height: 800, child: Editor()));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open collection1
      final openCollectionBtn = find.byKey(const Key('editor_tabs_open_collection_button'));
      expect(openCollectionBtn, findsOneWidget);
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();
      expect(find.text('collection1'), findsOneWidget);

      // Find and click the global envs dropdown button
      final dropdownBtn = find.byKey(const Key('editor_tabs_runtime_vars_button'));
      await tester.tap(dropdownBtn);
      await tester.pumpAndSettle();

      expect(find.text('Runtime Variables'), findsOneWidget);

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

      // Verify the runtime vars are saved
      expect(deps2.runtimeVarsRepo.vars.length, 2);
      expect(deps2.runtimeVarsRepo.vars[0].name, 'API_URL');
      expect(deps2.runtimeVarsRepo.vars[0].value, 'https://api.example.com');
      expect(deps2.runtimeVarsRepo.vars[1].name, 'API_KEY');
      expect(deps2.runtimeVarsRepo.vars[1].value, 'secret123');
    });
  });
}
