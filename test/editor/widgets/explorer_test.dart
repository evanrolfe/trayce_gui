import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  group('Explorer', () {
    testWidgets('copying a request to another folder multiple times', (WidgetTester tester) async {
      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');

      final newFilePath1 = 'test/support/collection1/myfolder/my-request.bru';
      final newFilePath2 = 'test/support/collection1/myfolder/my-request copy.bru';
      final newFilePath3 = 'test/support/collection1/myfolder/my-request copy2.bru';

      await initWidget(tester, deps);
      await tester.pumpAndSettle();

      // Click on my-request.bru request
      final myReq = find.text('my-request').first;
      expect(myReq, findsOneWidget);
      await tester.tapAt(tester.getCenter(myReq));
      await tester.pumpAndSettle();

      // Copy the request
      await pressCtrlC(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Click on myfolder
      final myFolder = find.text('myfolder');
      expect(myFolder, findsOneWidget);
      await tester.tapAt(tester.getCenter(myFolder));
      await tester.pumpAndSettle();

      // Paste the request 3 times
      await pressCtrlV(tester);
      await tester.pumpAndSettle();
      await pressCtrlV(tester);
      await tester.pumpAndSettle();
      await pressCtrlV(tester);
      await tester.pumpAndSettle();

      // Verify the file has been copied 1
      final newFileContent = loadFile(newFilePath1);
      expect(newFileContent, contains('url: https://trayce.dev'));
      expect(newFileContent, contains('seq: 5'));
      // Verify the file has been copied 1
      final newFileContent2 = loadFile(newFilePath2);
      expect(newFileContent2, contains('url: https://trayce.dev'));
      expect(newFileContent2, contains('seq: 6'));
      // Verify the file has been copied 1
      final newFileContent3 = loadFile(newFilePath3);
      expect(newFileContent3, contains('url: https://trayce.dev'));
      expect(newFileContent3, contains('seq: 7'));

      // Restore the original request file
      deleteFileSync(newFilePath1);
      deleteFileSync(newFilePath2);
      deleteFileSync(newFilePath3);
    });
  });
}
