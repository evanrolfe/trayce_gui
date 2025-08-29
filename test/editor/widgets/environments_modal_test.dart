import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/environment.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/widgets/common/environments_modal.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';

import '../../support/helpers.dart';
import '../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;
  late WidgetDependencies deps2;
  late WidgetDependencies deps3;
  late WidgetDependencies deps4;
  late WidgetDependencies deps5;
  late WidgetDependencies deps6;
  late WidgetDependencies deps7;

  setUpAll(() async {
    deps = await setupTestDependencies();
    deps2 = await setupTestDependencies();
    deps3 = await setupTestDependencies();
    deps4 = await setupTestDependencies();
    deps5 = await setupTestDependencies();
    deps6 = await setupTestDependencies();
    deps7 = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
    await deps2.close();
    await deps3.close();
    await deps4.close();
    await deps5.close();
    await deps6.close();
    await deps7.close();
  });

  group('Environment Modal', () {
    testWidgets('creating a new environment and saving some vars', (WidgetTester tester) async {
      // Create a collection with no environments
      final collection = Collection(
        file: File('test/support/collection2/collection.bru'),
        dir: Directory('test/support/collection2'),
        type: 'collection',
        authType: AuthType.none,
        environments: [], // Empty environments array
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
        file: File('test/support/collection1/collection.bru'),
        dir: Directory('test/support/collection1'),
        type: 'collection',
        authType: AuthType.none,
        environments: [environment], // Add at least one environment
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
      );

      // Create a test app with a button to show the modal
      final testApp = await deps2.wrapWidget(
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

    testWidgets('modal shows an environment with secret vars but nothing in AppStorage', (WidgetTester tester) async {
      final folderPath = 'test/support/collection1';
      final newFolderPath = '$folderPath-test';

      // NOTE: The async file operations seem to hang in widget tests for some reason
      copyFolderSync(folderPath, newFolderPath);

      final collection = deps3.collectionRepo.load(Directory(newFolderPath));
      // final environment = collection.environments.first;

      // Create a test app with a button to show the modal
      final testApp = await deps3.wrapWidget(
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

      expect(tableManager.rows()[0].keyController.text, 'my_key');
      expect(tableManager.rows()[0].valueController.text, '1234abcd');
      expect(tableManager.rows()[0].checkboxStateSecret, isFalse);
      expect(tableManager.rows()[0].checkboxState, isTrue);

      expect(tableManager.rows()[1].keyController.text, 'my_password');
      expect(tableManager.rows()[1].valueController.text, '');
      expect(tableManager.rows()[1].checkboxStateSecret, isTrue);
      expect(tableManager.rows()[1].checkboxState, isTrue);

      expect(tableManager.rows()[2].keyController.text, '');
      expect(tableManager.rows()[2].valueController.text, '');
      expect(tableManager.rows()[2].checkboxStateSecret, isFalse);

      deleteFolderSync(newFolderPath);
    });

    testWidgets('modal shows an environment with secret vars', (WidgetTester tester) async {
      final folderPath = 'test/support/collection1';
      final newFolderPath = '$folderPath-test';

      // NOTE: The async file operations seem to hang in widget tests for some reason
      copyFolderSync(folderPath, newFolderPath);

      deps4.appStorage.saveSecretVars(newFolderPath, 'dev', {'my_password': 'itsasecret'});

      final collection = deps4.collectionRepo.load(Directory(newFolderPath));
      final environment = collection.environments.first;
      expect(environment.fileName(), 'dev');

      // Create a test app with a button to show the modal
      final testApp = await deps4.wrapWidget(
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

      expect(tableManager.rows()[0].keyController.text, 'my_key');
      expect(tableManager.rows()[0].valueController.text, '1234abcd');
      expect(tableManager.rows()[0].checkboxStateSecret, isFalse);
      expect(tableManager.rows()[0].checkboxState, isTrue);

      expect(tableManager.rows()[1].keyController.text, 'my_password');
      expect(tableManager.rows()[1].valueController.text, 'itsasecret');
      expect(tableManager.rows()[1].checkboxStateSecret, isTrue);
      expect(tableManager.rows()[1].checkboxState, isTrue);

      expect(tableManager.rows()[2].keyController.text, '');
      expect(tableManager.rows()[2].valueController.text, '');
      expect(tableManager.rows()[2].checkboxStateSecret, isFalse);

      deleteFolderSync(newFolderPath);
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
        file: File('test/support/collection1/collection.bru'),
        dir: Directory('test/support/collection1'),
        type: 'collection',
        authType: AuthType.none,
        environments: [environment], // Add at least one environment
        headers: [],
        query: [],
        requestVars: [],
        responseVars: [],
      );

      // Create a test app with a button to show the modal
      final testApp = await deps5.wrapWidget(
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

    // testWidgets('renaming an environment', (WidgetTester tester) async {
    //   final folderPath = 'test/support/collection1';
    //   final newFolderPath = '$folderPath-test';

    //   // NOTE: The async file operations seem to hang in widget tests for some reason
    //   copyFolderSync(folderPath, newFolderPath);

    //   final collection = deps.collectionRepo.load(Directory(newFolderPath));
    //   final environment = collection.environments.first;

    //   // Create a test app with a button to show the modal
    //   final testApp = await deps.wrapWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: Builder(
    //           builder:
    //               (context) => ElevatedButton(
    //                 onPressed: () => showEnvironmentsModal(context, collection),
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
    //   expect(find.text('Environments'), findsOneWidget);
    //   expect(find.byType(Dialog), findsOneWidget);

    //   // Click the edit icon to enable renaming
    //   await tester.tap(find.byIcon(Icons.edit));
    //   await tester.pumpAndSettle();

    //   // Verify the value of the environments_modal_name_input
    //   final nameInput = find.byKey(const Key('environments_modal_name_input'));
    //   expect(nameInput, findsOneWidget);
    //   final textField = tester.widget<TextField>(nameInput);
    //   expect(textField.controller?.text, environment.fileName());

    //   // Change the value
    //   await tester.enterText(nameInput, 'renamed_env');
    //   await tester.pumpAndSettle();

    //   // Press Enter to submit
    //   // THIS FAILS TO TRIGGER THE onSubmitted callback
    //   await pressEnter(tester);
    //   await tester.pumpAndSettle();

    //   final envFile = File('$newFolderPath/environments/renamed_env.bru');
    //   expect(envFile.existsSync(), isFalse);

    //   deleteFolderSync(newFolderPath);
    // });

    testWidgets('adding an environment when some already exist', (WidgetTester tester) async {
      final folderPath = 'test/support/collection1';
      final newFolderPath = '$folderPath-test';

      // NOTE: The async file operations seem to hang in widget tests for some reason
      copyFolderSync(folderPath, newFolderPath);

      final collection = deps6.collectionRepo.load(Directory(newFolderPath));

      // Create a test app with a button to show the modal
      final testApp = await deps6.wrapWidget(
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

      // Click the new environment button
      await tester.tap(find.byKey(const Key('environments_modal_new_btn')));
      await tester.pumpAndSettle();

      final envFile = File('$newFolderPath/environments/untitled.bru');
      expect(envFile.existsSync(), isTrue);

      // Click it again
      await tester.tap(find.byKey(const Key('environments_modal_new_btn')));
      await tester.pumpAndSettle();

      final envFile2 = File('$newFolderPath/environments/untitled2.bru');
      expect(envFile2.existsSync(), isTrue);

      deleteFolderSync(newFolderPath);
    });

    testWidgets('saving a secret var', (WidgetTester tester) async {
      final folderPath = 'test/support/collection1';
      final newFolderPath = '$folderPath-test';

      // NOTE: The async file operations seem to hang in widget tests for some reason
      copyFolderSync(folderPath, newFolderPath);

      final collection = deps7.collectionRepo.load(Directory(newFolderPath));
      final environment = collection.environments.first;
      expect(environment.fileName(), 'dev');

      // Create a test app with a button to show the modal
      final testApp = await deps7.wrapWidget(
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

      expect(tableManager.rows()[0].keyController.text, 'my_key');
      expect(tableManager.rows()[1].keyController.text, 'my_password');
      tableManager.rows()[1].valueController.text = 'set_from_test!';

      await tester.tap(find.byKey(const ValueKey('save_btn')));
      await tester.pumpAndSettle();

      final secrets = await deps7.appStorage.getSecretVars(newFolderPath, 'dev');
      expect(secrets['my_password'], 'set_from_test!');

      deleteFolderSync(newFolderPath);
    });
  });
}
