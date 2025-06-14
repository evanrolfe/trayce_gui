import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/flow_editor_http/flow_editor_http.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/repo/flow_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';

final expectedBru1 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: text
}

body:text {
  ivechanged!
}
''';

final expectedBru2 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: text
}
''';

final expectedBru3 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: json
}

body:json {
  {"hello": "world"}
}
''';

final expectedBru4 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: json
}
''';

final expectedBru5 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: xml
}

body:xml {
  <html></html>
}
''';

final expectedBru6 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: xml
}
''';

final expectedBru7 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
}

body:text {
  helloworld
}
''';

const jsonResponse = '{"message":"Hello, World!","status":200}';
const expectedFormattedJson = '''{
  "message": "Hello, World!",
  "status": 200
}''';

// Global variables for dependencies
late Database db;
late EventBus eventBus;
late FlowRepo flowRepo;
late ProtoDefRepo protoDefRepo;
late ContainersRepo containersRepo;
late ExplorerRepo explorerRepo;
late Config config;

/// Sets up all required dependencies for tests
Future<void> setupTestDependencies() async {
  db = await connectDB();
  eventBus = EventBus();
  flowRepo = FlowRepo(db: db, eventBus: eventBus);
  protoDefRepo = ProtoDefRepo(db: db);
  containersRepo = ContainersRepo(eventBus: eventBus);
  explorerRepo = ExplorerRepo(eventBus: eventBus);
  config = Config.fromArgs([]);
}

/// Creates a widget with all required providers
Widget createTestWidget({required Widget child}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
      RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
      RepositoryProvider<EventBus>(create: (context) => eventBus),
      RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
      RepositoryProvider<ExplorerRepo>(create: (context) => explorerRepo),
      RepositoryProvider<Config>(create: (context) => config),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Modifying the request body', () {
    testWidgets('setting text body', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.none,
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = createTestWidget(child: FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Set the body to a text body
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      await tester.tap(bodyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      // Change the body text
      final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      bodyEditor.controller.text = 'ivechanged!';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.text);
      expect(request.bodyText.toString(), 'ivechanged!');
      expect(request.getBody(), request.bodyText);
      expect(request.toBru(), expectedBru1);

      // Change the body text to empty
      bodyEditor.controller.text = '';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.text);
      expect(request.bodyText.toString(), '');
      expect(request.getBody(), request.bodyText);
      expect(request.toBru(), expectedBru2);
    });

    testWidgets('setting json body', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.none,
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = createTestWidget(child: FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set the body to a text body
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      await tester.tap(bodyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();

      // Change the body text
      final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      bodyEditor.controller.text = '{"hello": "world"}';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.json);
      expect(request.bodyJson.toString(), '{"hello": "world"}');
      expect(request.getBody(), request.bodyJson);
      expect(request.toBru(), expectedBru3);

      // Change the body text to empty
      bodyEditor.controller.text = '';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.json);
      expect(request.bodyJson.toString(), '');
      expect(request.getBody(), request.bodyJson);
      expect(request.toBru(), expectedBru4);
    });

    testWidgets('setting xml body', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.none,
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = createTestWidget(child: FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Set the body to a text body
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      await tester.tap(bodyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('XML'));
      await tester.pumpAndSettle();

      // Change the body text
      final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      bodyEditor.controller.text = '<html></html>';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.xml);
      expect(request.bodyXml.toString(), '<html></html>');
      expect(request.getBody(), request.bodyXml);
      expect(request.toBru(), expectedBru5);

      // Change the body text to empty
      bodyEditor.controller.text = '';
      await tester.pumpAndSettle();

      // Save the request
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.xml);
      expect(request.bodyXml.toString(), '');
      expect(request.getBody(), request.bodyXml);
      expect(request.toBru(), expectedBru6);
    });

    testWidgets('setting text, then xml, then no body', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.text,
        bodyText: TextBody(content: 'helloworld'),
        params: [],
        headers: [],
        requestVars: [],
        responseVars: [],
        assertions: [],
      );

      final tabKey = const ValueKey('test_tab');
      final widget = createTestWidget(child: FlowEditorHttp(request: request, tabKey: tabKey));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);

      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Set the body to a text body
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      await tester.tap(bodyTypeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Body'));
      await tester.pumpAndSettle();

      // Change the body text
      // final bodyEditor = tester.widget<MultiLineCodeEditor>(find.byType(MultiLineCodeEditor).first);
      // bodyEditor.controller.text = '<html></html>';
      // await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.none);
      expect(request.getBody(), isNull);
      expect(request.toBru(), expectedBru7);
    });
  });
}

Future<void> pressCtrlS(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}
