import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/editor.dart';

import '../../../support/helpers.dart';
import '../../../support/widget_helpers.dart';

void main() {
  late WidgetDependencies deps;
  late WidgetDependencies deps2;
  late String filePath;
  late String originalContent;

  setUpAll(() async {
    deps = await setupTestDependencies();
    deps2 = await setupTestDependencies();

    filePath = 'test/support/collection1/myfolder/folder.bru';
    originalContent = loadFile(filePath);
  });

  tearDownAll(() async {
    await deps.close();
    await deps2.close();

    // Restore original folder
    saveFile(filePath, originalContent);
  });

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

  group('Editor Folder Settings', () {
    testWidgets('saving a script on a folder', (WidgetTester tester) async {
      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');

      await initWidget(tester, deps);
      await tester.pumpAndSettle();

      // Right-click on myfolder
      final myFolder = find.text('myfolder');
      expect(myFolder, findsOneWidget);
      await tester.tapAt(tester.getCenter(myFolder), buttons: 2);
      await tester.pumpAndSettle();

      // Click on Folder Settings
      final folderSettings = find.text('Settings');
      expect(folderSettings, findsOneWidget);
      await tester.tap(folderSettings);
      await tester.pumpAndSettle();

      // Click on Script tab
      final scriptTab = find.text('Script').last;
      expect(scriptTab, findsOneWidget);
      await tester.tap(scriptTab);
      await tester.pumpAndSettle();

      // Change the pre-request script
      final preRequestEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      preRequestEditor.controller.text = 'console.log("Hello, World! (pre)");';
      await tester.pumpAndSettle();

      // Press save
      final saveBtn = find.byKey(const Key('save_btn'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify the folder has the auth type
      final folderContent = loadFile(filePath);
      expect(
        folderContent,
        contains('''script:pre-request {
  console.log("Hello, World! (pre)");
}'''),
      );
    });

    // NOTE: This test is dependent on the test case before it running!
    testWidgets('loading a script on a folder', (WidgetTester tester) async {
      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');

      await initWidget(tester, deps2);
      await tester.pumpAndSettle();

      // Right-click on myfolder
      final myFolder = find.text('myfolder');
      expect(myFolder, findsOneWidget);
      await tester.tapAt(tester.getCenter(myFolder), buttons: 2);
      await tester.pumpAndSettle();

      // Click on Folder Settings
      final folderSettings = find.text('Settings');
      expect(folderSettings, findsOneWidget);
      await tester.tap(folderSettings);
      await tester.pumpAndSettle();

      // Click on Script tab
      final scriptTab = find.text('Script').last;
      expect(scriptTab, findsOneWidget);
      await tester.tap(scriptTab);
      await tester.pumpAndSettle();

      // Verify the pre-request script
      final preRequestEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      expect(preRequestEditor.controller.text, 'console.log("Hello, World! (pre)");');
    });
  });
}
