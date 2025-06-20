import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_multi.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_single.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
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

final expectedBru8 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: form-urlencoded
}

body:form-urlencoded {
  XXXX: YYYY
}
''';

final expectedBru9 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: multipart-form
}

body:multipart-form {
  XXXX: @file(/home/trayce/x.txt) @contentType(text/plain)
}
''';

final expectedBru10 = '''meta {
  name: Test Request
  type: http
  seq: 1
}

get {
  url: https://example.com
  body: multipart-form
}

body:multipart-form {
  XXXX: @file(/home/trayce/x.txt)
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

  group('Loading a request', () {
    testWidgets('a request with body: form-urlencoded', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.formUrlEncoded,
        bodyFormUrlEncoded: FormUrlEncodedBody(
          params: [
            Param(name: 'XXXX', value: 'YYYY', type: ParamType.form, enabled: true),
            Param(name: 'ZZZZ', value: 'WWWW', type: ParamType.form, enabled: false),
          ],
        ),
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

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      expect(tester.widget<DropdownButton2<String>>(bodyTypeDropdown).value, 'Form URL Encoded');

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.stateManager;

      expect(tableManager.rows.length, 3);
      expect(tableManager.rows[0].keyController.text, 'XXXX');
      expect(tableManager.rows[0].valueController.text, 'YYYY');
      expect(tableManager.rows[0].checkboxState, true);

      expect(tableManager.rows[1].keyController.text, 'ZZZZ');
      expect(tableManager.rows[1].valueController.text, 'WWWW');
      expect(tableManager.rows[1].checkboxState, false);

      expect(tableManager.rows[2].keyController.text, '');
      expect(tableManager.rows[2].valueController.text, '');
      expect(tableManager.rows[2].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: form-multipart', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.multipartForm,
        bodyMultipartForm: MultipartFormBody(
          files: [
            MultipartFile(name: 'XXXX', value: '/home/trayce/x.txt', enabled: true),
            MultipartFile(name: 'ZZZZ', value: '/home/trayce/y.txt', enabled: false),
            MultipartFile(name: 'YYYY', value: '/home/trayce/z.txt', enabled: true, contentType: 'text/plain'),
          ],
        ),
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

      // Verify method, url
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      final urlInput = tester.widget<SingleLineCodeEditor>(find.byKey(Key('flow_editor_http_url_input')));
      expect(urlInput.controller.text, 'https://example.com');
      await tester.pumpAndSettle();

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      final bodyTypeDropdown = find.byKey(const Key('flow_editor_http_body_type_dropdown')).first;
      expect(tester.widget<DropdownButton2<String>>(bodyTypeDropdown).value, 'Multipart Form');

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.stateManager;

      expect(tableManager.rows.length, 4);
      expect(tableManager.rows[0].keyController.text, 'XXXX');
      expect(tableManager.rows[0].valueFile, '/home/trayce/x.txt');
      expect(tableManager.rows[0].contentTypeController.text, '');
      expect(tableManager.rows[0].checkboxState, true);

      expect(tableManager.rows[1].keyController.text, 'ZZZZ');
      expect(tableManager.rows[1].valueFile, '/home/trayce/y.txt');
      expect(tableManager.rows[1].contentTypeController.text, '');
      expect(tableManager.rows[1].checkboxState, false);

      expect(tableManager.rows[2].keyController.text, 'YYYY');
      expect(tableManager.rows[2].valueFile, '/home/trayce/z.txt');
      expect(tableManager.rows[2].contentTypeController.text, 'text/plain');
      expect(tableManager.rows[2].checkboxState, true);

      expect(tableManager.rows[3].keyController.text, '');
      expect(tableManager.rows[3].valueFile, isNull);
      expect(tableManager.rows[3].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: form-multipart - deleting a row', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.multipartForm,
        bodyMultipartForm: MultipartFormBody(
          files: [
            MultipartFile(name: 'XXXX', value: '/home/trayce/x.txt', enabled: true),
            MultipartFile(name: 'ZZZZ', value: '/home/trayce/y.txt', enabled: false),
            MultipartFile(name: 'YYYY', value: '/home/trayce/z.txt', enabled: true, contentType: 'text/plain'),
          ],
        ),
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

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      // Delete the middle row
      await tester.tap(find.byKey(Key('form_table_delete_row_1')));
      await tester.pumpAndSettle();

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.stateManager;

      expect(tableManager.rows.length, 3);
      expect(tableManager.rows[0].keyController.text, 'XXXX');
      expect(tableManager.rows[0].valueFile, '/home/trayce/x.txt');
      expect(tableManager.rows[0].contentTypeController.text, '');
      expect(tableManager.rows[0].checkboxState, true);

      expect(tableManager.rows[1].keyController.text, 'YYYY');
      expect(tableManager.rows[1].valueFile, '/home/trayce/z.txt');
      expect(tableManager.rows[1].contentTypeController.text, 'text/plain');
      expect(tableManager.rows[1].checkboxState, true);

      expect(tableManager.rows[2].keyController.text, '');
      expect(tableManager.rows[2].valueFile, isNull);
      expect(tableManager.rows[2].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: form-multipart - typing in a new row', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.multipartForm,
        bodyMultipartForm: MultipartFormBody(
          files: [
            MultipartFile(name: 'XXXX', value: '/home/trayce/x.txt', enabled: true),
            MultipartFile(name: 'ZZZZ', value: '/home/trayce/z.txt', enabled: true, contentType: 'text/plain'),
          ],
        ),
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

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.stateManager;

      // Enter text in the new row
      tableManager.rows[2].contentTypeController.text = 'hello';
      await tester.pumpAndSettle();

      expect(tableManager.rows.length, 4);
      expect(tableManager.rows[0].keyController.text, 'XXXX');
      expect(tableManager.rows[0].valueFile, '/home/trayce/x.txt');
      expect(tableManager.rows[0].contentTypeController.text, '');
      expect(tableManager.rows[0].checkboxState, true);

      expect(tableManager.rows[1].keyController.text, 'ZZZZ');
      expect(tableManager.rows[1].valueFile, '/home/trayce/z.txt');
      expect(tableManager.rows[1].contentTypeController.text, 'text/plain');
      expect(tableManager.rows[1].checkboxState, true);

      expect(tableManager.rows[2].keyController.text, '');
      expect(tableManager.rows[2].valueFile, isNull);
      expect(tableManager.rows[2].contentTypeController.text, 'hello');
      expect(tableManager.rows[2].checkboxState, true);

      expect(tableManager.rows[3].keyController.text, '');
      expect(tableManager.rows[3].valueFile, isNull);
      expect(tableManager.rows[3].contentTypeController.text, '');
      expect(tableManager.rows[3].checkboxState, false);

      await tester.pumpAndSettle();
    });

    testWidgets('a request with body: form-multipart - modifying the key of a row', (WidgetTester tester) async {
      // Create a test request
      final request = Request(
        name: 'Test Request',
        type: 'http',
        seq: 1,
        method: 'get',
        url: 'https://example.com',
        bodyType: BodyType.multipartForm,
        bodyMultipartForm: MultipartFormBody(
          files: [
            MultipartFile(name: 'XXXX', value: '/home/trayce/x.txt', enabled: true),
            MultipartFile(name: 'ZZZZ', value: '/home/trayce/z.txt', enabled: true, contentType: 'text/plain'),
          ],
        ),
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

      // Verify request body type
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      // Verify request body
      final formTable = tester.widget<FormTable>(find.byType(FormTable));
      final tableManager = formTable.stateManager;

      EventEditorNodeModified? eventReceived;
      eventBus.on<EventEditorNodeModified>().listen((event) {
        eventReceived = event;
      });

      // Enter text in the new row
      tableManager.rows[0].contentTypeController.text = 'changed';
      await tester.pumpAndSettle();

      expect(eventReceived, isNotNull);
      expect(eventReceived!.isDifferent, true);
      expect(eventReceived!.tabKey, tabKey);
    });
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

    testWidgets('setting form-urlencoded body', (WidgetTester tester) async {
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
      await tester.tap(find.text('Form URL Encoded'));
      await tester.pumpAndSettle();

      // Change the form url encoded params
      final headersTable = tester.widget<FormTable>(find.byType(FormTable));
      final headersManager = headersTable.stateManager;
      headersManager.rows[0].keyController.text = 'XXXX';
      headersManager.rows[0].valueController.text = 'YYYY';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.formUrlEncoded);

      final body = request.getBody() as FormUrlEncodedBody;
      expect(body.params.length, 1);
      expect(body.params[0].name, 'XXXX');
      expect(body.params[0].value, 'YYYY');
      expect(body.params[0].enabled, true);
      expect(request.getBody(), request.bodyFormUrlEncoded);
      expect(request.toBru(), expectedBru8);
    });

    testWidgets('setting form-multipart body', (WidgetTester tester) async {
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
      await tester.tap(find.text('Multipart Form'));
      await tester.pumpAndSettle();

      // Change the form url encoded params
      final headersTable = tester.widget<FormTable>(find.byType(FormTable));
      final headersManager = headersTable.stateManager;
      headersManager.rows[0].keyController.text = 'XXXX';
      headersManager.rows[0].valueFile = '/home/trayce/x.txt';
      headersManager.rows[0].contentTypeController.text = 'text/plain';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.multipartForm);

      final body = request.getBody() as MultipartFormBody;
      expect(body.files.length, 1);
      expect(body.files[0].name, 'XXXX');
      expect(body.files[0].value, '/home/trayce/x.txt');
      expect(body.files[0].enabled, true);
      expect(body.files[0].contentType, 'text/plain');
      expect(request.getBody(), request.bodyMultipartForm);
      expect(request.toBru(), expectedBru9);
    });

    testWidgets('setting form-multipart body without content type', (WidgetTester tester) async {
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
      await tester.tap(find.text('Multipart Form'));
      await tester.pumpAndSettle();

      // Change the form url encoded params
      final headersTable = tester.widget<FormTable>(find.byType(FormTable));
      final headersManager = headersTable.stateManager;
      headersManager.rows[0].keyController.text = 'XXXX';
      headersManager.rows[0].valueFile = '/home/trayce/x.txt';
      headersManager.rows[0].contentTypeController.text = '';
      await tester.pumpAndSettle();

      // Save the request
      await tester.tap(find.byKey(Key('flow_editor_http_url_input')));
      await tester.pumpAndSettle();
      await pressCtrlS(tester);
      await tester.pumpAndSettle();

      expect(request.bodyType, BodyType.multipartForm);

      final body = request.getBody() as MultipartFormBody;
      expect(body.files.length, 1);
      expect(body.files[0].name, 'XXXX');
      expect(body.files[0].value, '/home/trayce/x.txt');
      expect(body.files[0].enabled, true);
      expect(body.files[0].contentType, isNull);
      expect(request.getBody(), request.bodyMultipartForm);
      expect(request.toBru(), expectedBru10);
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
