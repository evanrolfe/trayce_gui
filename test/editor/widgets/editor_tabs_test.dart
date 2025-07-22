import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/editor.dart';
import 'package:trayce/editor/widgets/editor_tabs.dart';

import '../../support/helpers.dart';
import '../../support/widget_helpers.dart';

void main() {
  // TODO: Find a better way of doing this:
  late WidgetDependencies deps;
  late WidgetDependencies deps2;
  late WidgetDependencies deps3;
  late WidgetDependencies deps4;
  late WidgetDependencies deps5;
  late WidgetDependencies deps6;
  late WidgetDependencies deps7;
  late WidgetDependencies deps8;
  late WidgetDependencies deps9;
  late WidgetDependencies deps10;
  late WidgetDependencies deps11;
  late WidgetDependencies deps12;
  late WidgetDependencies deps13;
  setUpAll(() async {
    deps = await setupTestDependencies();
    deps2 = await setupTestDependencies();
    deps3 = await setupTestDependencies();
    deps4 = await setupTestDependencies();
    deps5 = await setupTestDependencies();
    deps6 = await setupTestDependencies();
    deps7 = await setupTestDependencies();
    deps8 = await setupTestDependencies();
    deps9 = await setupTestDependencies();
    deps10 = await setupTestDependencies();
    deps11 = await setupTestDependencies();
    deps12 = await setupTestDependencies();
    deps13 = await setupTestDependencies();
  });

  tearDownAll(() async {
    await deps.close();
    await deps2.close();
    await deps3.close();
    await deps4.close();
    await deps5.close();
    await deps6.close();
    await deps7.close();
    await deps8.close();
    await deps9.close();
    await deps10.close();
    await deps11.close();
    await deps12.close();
    await deps13.close();
  });

  // Sets up the editor with two tabs open (one and two requests)
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

    // Find and click hello folder
    final helloBtn = find.text('myfolder');
    expect(helloBtn, findsOneWidget);
    await tester.tap(helloBtn);
    await tester.pumpAndSettle();

    // Find and double-click one request
    final oneReqBtn = find.text('one');
    expect(oneReqBtn, findsOneWidget);
    // For some reason this only needs to be single tapped
    await tester.tap(oneReqBtn);
    // await tester.tap(oneReqBtn);
    await tester.pumpAndSettle();

    // Find and double-click two request
    final twoReqBtn = find.text('two');
    expect(twoReqBtn, findsOneWidget);
    await tester.tap(twoReqBtn);
    await tester.tap(twoReqBtn);
    await tester.pumpAndSettle();

    final editorTabsState = tester.state(find.byType(EditorTabs)) as dynamic;

    final currentTabs = editorTabsState.currentTabs();

    expect(currentTabs.length, 2);
    expect(currentTabs[0].getDisplayName(), 'one');
    expect(currentTabs[1].getDisplayName(), 'two');

    return (widget, editorTabsState);
  }

  group('Editor Tabs', () {
    testWidgets('opening two tabs and clicking on each one', (WidgetTester tester) async {
      when(() => deps.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps);
      final currentTabs = editorTabsState.currentTabs();

      // Click on the first tab and verify the URL
      await tester.tap(find.byKey(currentTabs[0].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'http://www.github.com/one');

      // Click on the second tab and verify the URL
      await tester.tap(find.byKey(currentTabs[1].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, 'http://www.github.com/two');
    });

    testWidgets('dragging the 1st tab to the position of the 2nd tab', (WidgetTester tester) async {
      when(() => deps2.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps2);

      await tester.drag(find.byKey(editorTabsState.currentTabs()[0].key), Offset(260, 0));
      await tester.pumpAndSettle();

      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 2);
      expect(currentTabs2[0].getDisplayName(), 'two');
      expect(currentTabs2[1].getDisplayName(), 'one');

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();
    });

    testWidgets('dragging the 2nd tab to the position of the 1st tab', (WidgetTester tester) async {
      when(() => deps3.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps3);

      await tester.drag(find.byKey(editorTabsState.currentTabs()[1].key), Offset(-260, 0));
      await tester.pumpAndSettle();

      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 2);
      expect(currentTabs2[0].getDisplayName(), 'two');
      expect(currentTabs2[1].getDisplayName(), 'one');

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();
    });

    testWidgets('dragging the 1st tab past the + tab', (WidgetTester tester) async {
      when(() => deps7.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps7);

      await tester.drag(find.byKey(editorTabsState.currentTabs()[0].key), Offset(350, 0));
      await tester.pumpAndSettle();

      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 2);
      expect(currentTabs2[0].getDisplayName(), 'one');
      expect(currentTabs2[1].getDisplayName(), 'two');

      // Verify the URL input exists and can be accessed
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      urlInput.controller.text = 'https://example.com';
      await tester.pumpAndSettle();
    });

    testWidgets('opening two tabs and modifying one of them', (WidgetTester tester) async {
      when(() => deps4.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps4);

      final currentTabs = editorTabsState.currentTabs();

      // Click on the first tab and verify the URL
      await tester.tap(find.byKey(currentTabs[0].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'http://www.github.com/one');

      // Click on the second tab and verify the URL
      await tester.tap(find.byKey(currentTabs[1].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, 'http://www.github.com/two');

      urlInput2.controller.text = 'http://www.github.com/two/changed';
      await tester.pumpAndSettle();

      // Verify the tab title has * at the end
      expect(find.text('two*'), findsOneWidget);

      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 2);
      expect(currentTabs2[0].getDisplayName(), 'one');
      expect(currentTabs2[1].getDisplayName(), 'two*');

      // Now change it back to the original
      urlInput2.controller.text = 'http://www.github.com/two';
      await tester.pumpAndSettle();

      // Verify the tab title has no * at the end
      expect(find.text('two'), findsNWidgets(2));

      final currentTabs3 = editorTabsState.currentTabs();
      expect(currentTabs3.length, 2);
      expect(currentTabs3[0].getDisplayName(), 'one');
      expect(currentTabs3[1].getDisplayName(), 'two');
    });

    testWidgets('opening two tabs and modifying one of them and dragging it', (WidgetTester tester) async {
      when(() => deps5.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps5);

      final currentTabs = editorTabsState.currentTabs();

      // Click on the first tab and verify the URL
      await tester.tap(find.byKey(currentTabs[0].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'http://www.github.com/one');

      // Click on the second tab and verify the URL
      await tester.tap(find.byKey(currentTabs[1].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, 'http://www.github.com/two');

      urlInput2.controller.text = 'http://www.github.com/two/changed';
      await tester.pumpAndSettle();

      // Verify the tab title has * at the end
      expect(find.text('two*'), findsOneWidget);

      // Drag the second tab to the position of the first tab
      await tester.drag(find.byKey(editorTabsState.currentTabs()[1].key), Offset(-300, 0));
      await tester.pumpAndSettle();

      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 2);
      expect(currentTabs2[0].getDisplayName(), 'two*');
      expect(currentTabs2[1].getDisplayName(), 'one');

      // Verify the URL of the modified request is still modified
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput3 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput3.controller.text, 'http://www.github.com/two/changed');
    });

    testWidgets('creating a new request using the + tab button', (WidgetTester tester) async {
      when(() => deps6.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      await initWidget(tester, deps6);

      // Click on the + tab button
      final plusTabBtn = find.byKey(const Key('editor_tabs_plus_tab'));
      expect(plusTabBtn, findsOneWidget);
      await tester.tap(plusTabBtn);
      await tester.pumpAndSettle();

      // Enter a URL
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, '');

      urlInput2.controller.text = 'http://www.trayce.dev/new';
      await tester.pumpAndSettle();

      // Verify the tab title has * at the end
      expect(find.text('Untitled-0*'), findsOneWidget);
    });

    testWidgets('creating a new request and saving it', (WidgetTester tester) async {
      when(() => deps8.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      when(() => deps8.filePicker.saveBruFile(any())).thenAnswer((_) async => 'test/support/collection1/hello.bru');
      final (_, editorTabsState) = await initWidget(tester, deps8);

      // Click on the + tab button
      final plusTabBtn = find.byKey(const Key('editor_tabs_plus_tab'));
      expect(plusTabBtn, findsOneWidget);
      await tester.tap(plusTabBtn);
      await tester.pumpAndSettle();

      // Enter a URL
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, '');

      urlInput2.controller.text = 'http://www.trayce.dev/new';
      await tester.pumpAndSettle();

      // Verify the tab title has * at the end
      expect(find.text('Untitled-0*'), findsOneWidget);

      await pressCtrlS(tester);

      // Verify the tab title has been updated
      expect(find.text('hello'), findsNWidgets(3));
      final currentTabs3 = editorTabsState.currentTabs();
      expect(currentTabs3.length, 3);
      expect(currentTabs3[0].getDisplayName(), 'one');
      expect(currentTabs3[1].getDisplayName(), 'two');
      expect(currentTabs3[2].getDisplayName(), 'hello');

      // Verify the request is saved
      final content = loadFile('test/support/collection1/hello.bru');
      expect(content, contains('http://www.trayce.dev/new'));

      // Delete the created file
      deleteFileSync('test/support/collection1/hello.bru');
    });

    testWidgets('modifying an existing request and saving it', (WidgetTester tester) async {
      when(() => deps9.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final filePath = 'test/support/collection1/myfolder/two.bru';
      final originalContent = loadFile(filePath);

      final (_, editorTabsState) = await initWidget(tester, deps9);

      // Enter a URL
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, 'http://www.github.com/two');

      urlInput2.controller.text = 'http://www.github.com/two/changed';
      await tester.pumpAndSettle();

      // Verify the tab title has * at the end
      expect(find.text('two*'), findsOneWidget);

      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      // Verify the tab title has been updated
      final currentTabs3 = editorTabsState.currentTabs();
      expect(currentTabs3.length, 2);
      expect(currentTabs3[0].getDisplayName(), 'one');
      expect(currentTabs3[1].getDisplayName(), 'two');

      // Verify the request is saved
      final content = loadFile(filePath);
      expect(content, contains('http://www.github.com/two/changed'));

      // Restore the original request file
      saveFile(filePath, originalContent);
    });

    testWidgets('renaming an existing request', (WidgetTester tester) async {
      when(() => deps10.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final filePath = 'test/support/collection1/myfolder/two.bru';
      final newFilePath = 'test/support/collection1/myfolder/newname.bru';
      final originalContent = loadFile(filePath);

      final (_, editorTabsState) = await initWidget(tester, deps10);

      // Right-click on two.bru request
      final twoReq = find.text('two').first;
      await tester.tapAt(tester.getCenter(twoReq), buttons: 2);
      await tester.pumpAndSettle();

      // Click open on context menu
      final openItem = find.text('Rename');
      await tester.tap(openItem);
      await tester.pumpAndSettle();

      // Enter a new name
      final renameInput = find.byKey(const Key('explorer_rename_input'));
      expect(renameInput, findsOneWidget);

      await tester.enterText(renameInput, 'newname');
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify the tab title has been updated
      final currentTabs = editorTabsState.currentTabs();
      expect(currentTabs.length, 2);
      expect(currentTabs[0].getDisplayName(), 'one');
      expect(currentTabs[1].getDisplayName(), 'newname');

      // Verify the file has been renamed
      final newFileContent = loadFile(newFilePath);
      expect(newFileContent, originalContent);

      // Restore the original request file
      saveFile(filePath, originalContent);
      deleteFileSync(newFilePath);
    });

    // I've had trouble getting this test case to work I think because it requires the full path to be return from saveBruFile()
    // In order for ExplorerService.findNodeByPath() to work.
    //
    // testWidgets('renaming a new request which was just saved', (WidgetTester tester) async {
    //   when(() => deps11.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
    //   when(
    //     () => deps11.filePicker.saveBruFile(any()),
    //   ).thenAnswer((_) async => '/home/evan/Code/trayce/gui/test/support/collection1/testreq.bru');
    //   final (_, editorTabsState) = await initWidget(tester, deps11);

    //   // Click on the + tab button
    //   final plusTabBtn = find.byKey(const Key('editor_tabs_plus_tab'));
    //   expect(plusTabBtn, findsOneWidget);
    //   await tester.tap(plusTabBtn);
    //   await tester.pumpAndSettle();

    //   // Enter a URL
    //   expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
    //   final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
    //   expect(urlInput2.controller.text, '');

    //   urlInput2.controller.text = 'http://www.trayce.dev/new';
    //   await tester.pumpAndSettle();

    //   // Verify the tab title has * at the end
    //   expect(find.text('Untitled-0*'), findsOneWidget);

    //   await pressCtrlS(tester);

    //   // Verify the tab title has been updated
    //   expect(find.text('testreq'), findsNWidgets(2));
    //   final currentTabs = editorTabsState.currentTabs();
    //   expect(currentTabs.length, 3);
    //   expect(currentTabs[0].getDisplayName(), 'one');
    //   expect(currentTabs[1].getDisplayName(), 'two');
    //   expect(currentTabs[2].getDisplayName(), 'testreq');

    //   // Verify the request is saved
    //   final content = loadFile('test/support/collection1/testreq.bru');
    //   expect(content, contains('http://www.trayce.dev/new'));

    //   // Right-click on testreq.bru request
    //   final testreqReq = find.text('testreq').first;
    //   await tester.tapAt(tester.getCenter(testreqReq), buttons: 2);
    //   await tester.pumpAndSettle();

    //   // Click open on context menu
    //   final openItem = find.text('Rename');
    //   await tester.tap(openItem);
    //   await tester.pumpAndSettle();

    //   // Enter a new name
    //   final renameInput = find.byKey(const Key('explorer_rename_input'));
    //   expect(renameInput, findsOneWidget);

    //   await tester.enterText(renameInput, 'newname');
    //   await tester.pumpAndSettle();

    //   await tester.testTextInput.receiveAction(TextInputAction.done);
    //   await tester.pumpAndSettle();

    //   // Verify a file was saved
    //   // final newFileContent = loadFile('test/support/collection1/newname.bru');
    //   // expect(newFileContent, isNotEmpty);

    //   // Verify the tab title has been updated
    //   // expect(find.text('newname'), findsNWidgets(2));
    //   final currentTabs2 = editorTabsState.currentTabs();
    //   expect(currentTabs2.length, 3);
    //   expect(currentTabs2[0].getDisplayName(), 'one');
    //   expect(currentTabs2[1].getDisplayName(), 'two');
    //   expect(currentTabs2[2].getDisplayName(), 'newname');

    //   // Delete the created file
    //   deleteFileSync('test/support/collection1/newname.bru');
    // });

    testWidgets('closing request two', (WidgetTester tester) async {
      when(() => deps12.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps12);

      // Verify the URl
      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput2 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput2.controller.text, 'http://www.github.com/two');

      // Verify the tabs
      final currentTabs = editorTabsState.currentTabs();
      expect(currentTabs.length, 2);
      expect(currentTabs[0].getDisplayName(), 'one');
      expect(currentTabs[1].getDisplayName(), 'two');

      await pressCtrlW(tester);
      await tester.pumpAndSettle();

      // Verify the tabs
      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 1);
      expect(currentTabs2[0].getDisplayName(), 'one');

      // Verify the first tab is currently open
      final urlInput3 = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput3.controller.text, 'http://www.github.com/one');
    });

    testWidgets('opening multiple collections', (WidgetTester tester) async {
      when(() => deps13.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection1');
      final (_, editorTabsState) = await initWidget(tester, deps13);

      final currentTabs = editorTabsState.currentTabs();

      // Click on the first tab and verify the URL
      await tester.tap(find.byKey(currentTabs[0].key));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('flow_editor_http_url_input')), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'http://www.github.com/one');

      // Find and click the IconButton with the key 'collection_btn'
      final openCollectionBtn = find.byKey(const Key('collection_btn'));
      await tester.tap(openCollectionBtn);
      await tester.pumpAndSettle();

      // Find and click the PopupMenuItem with the text "Open Collection"
      when(() => deps13.filePicker.getCollectionPath()).thenAnswer((_) async => './test/support/collection2');
      final openCollectionMenuItem = find.text('Open Collection');
      await tester.tap(openCollectionMenuItem);
      await tester.pumpAndSettle();

      expect(find.text('collection2'), findsOneWidget);

      // Find and double-click a request
      final reqBtn = find.text('test-request');
      expect(reqBtn, findsOneWidget);
      await tester.tap(reqBtn);
      await tester.tap(reqBtn);
      await tester.pumpAndSettle();

      // Verify the tabs
      final currentTabs2 = editorTabsState.currentTabs();
      expect(currentTabs2.length, 1);
      expect(currentTabs2[0].getDisplayName(), 'test-request');

      // Now click back to a request from collection1
      final reqBtn2 = find.text('my-request');
      expect(reqBtn2, findsOneWidget);
      await tester.tap(reqBtn2);
      await tester.tap(reqBtn2);
      await tester.pumpAndSettle();

      // Verify the tabs have switched back to collection1
      final currentTabs3 = editorTabsState.currentTabs();
      expect(currentTabs3.length, 3);
      expect(currentTabs3[0].getDisplayName(), 'one');
      expect(currentTabs3[1].getDisplayName(), 'two');
      expect(currentTabs3[2].getDisplayName(), 'my-request');
    });
  });
}
