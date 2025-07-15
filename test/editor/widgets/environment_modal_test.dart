import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/environments_modal.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';

import '../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;

  setUpAll(() async {
    deps = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
  });

  group('Environment Modal', () {
    testWidgets('creating a new environment and saving some vars', (WidgetTester tester) async {
      // Create a collection with no environments
      final collection = Collection(
        type: 'collection',
        environments: [], // Empty environments array
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
      );
      collection.dir = Directory('test/support/collection2');

      // Create a test app with a button to show the modal
      final testApp = await deps.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showEnvironmentsModal(context, collection),
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
      expect(find.text('Environments'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Should show "No environments found" message
      expect(find.text('No environments found.'), findsOneWidget);
      expect(find.text('New Environment'), findsOneWidget);

      // Click the "New Environment" button
      await tester.tap(find.text('New Environment'));
      await tester.pumpAndSettle();

      // Check that the environment file was created
      final envFile = File('test/support/collection2/environments/untitled.bru');
      expect(envFile.existsSync(), isTrue);

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
      tableManager.rows()[1].checkboxStateSecret = true; // Make it a secret variable
      await tester.pumpAndSettle();

      // Save the environment
      final saveButton = find.byKey(const ValueKey('save_btn'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check that the file contains the expected content with both variables
      final fileContent = envFile.readAsStringSync();
      expect(fileContent, contains('API_URL'));
      expect(fileContent, contains('https://api.example.com'));
      expect(fileContent, contains('API_KEY'));
      expect(fileContent, contains('vars:secret'));

      // Clean up - delete the created file
      envFile.deleteSync();
    });

    testWidgets('modal shows an environment with no vars', (WidgetTester tester) async {
      // Create a temporary file for the environment
      final tempFile = File('test/support/collection1/environments/new.bru');

      final environment = Environment(vars: [], file: tempFile);

      final collection = Collection(
        type: 'collection',
        environments: [environment], // Add at least one environment
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
      );

      // Create a test app with a button to show the modal
      final testApp = await deps.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showEnvironmentsModal(context, collection),
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
      expect(find.text('Environments'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Verify vars
      final formTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 1);
    });

    testWidgets('modal shows an environment with vars', (WidgetTester tester) async {
      // Create a temporary file for the environment
      final tempFile = File('test/support/collection1/environments/new.bru');

      final environment = Environment(
        vars: [
          Variable(name: 'API_URL', value: 'https://api.example.com', secret: false, enabled: true),
          Variable(name: 'API_KEY', value: 'secret123', secret: true, enabled: true),
        ],
        file: tempFile,
      );

      final collection = Collection(
        type: 'collection',
        environments: [environment], // Add at least one environment
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
      );

      // Create a test app with a button to show the modal
      final testApp = await deps.wrapWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => showEnvironmentsModal(context, collection),
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
      expect(find.text('Environments'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Verify vars
      final formTable = tester.widget<FormTable>(find.byType(FormTable).last);
      final tableManager = formTable.controller;

      expect(tableManager.rows().length, 3);

      expect(tableManager.rows()[0].keyController.text, 'API_URL');
      expect(tableManager.rows()[0].valueController.text, 'https://api.example.com');
      expect(tableManager.rows()[0].checkboxStateSecret, isFalse);
      expect(tableManager.rows()[0].checkboxState, isTrue);

      expect(tableManager.rows()[1].keyController.text, 'API_KEY');
      expect(tableManager.rows()[1].valueController.text, 'secret123');
      expect(tableManager.rows()[1].checkboxStateSecret, isTrue);
      expect(tableManager.rows()[1].checkboxState, isTrue);

      expect(tableManager.rows()[2].keyController.text, '');
      expect(tableManager.rows()[2].valueController.text, '');
      expect(tableManager.rows()[2].checkboxStateSecret, isFalse);
      expect(tableManager.rows()[2].checkboxState, isFalse);
    });
  });
}
