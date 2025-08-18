import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/script.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/setup_nodejs.dart';

import '../../support/fake_app_storage.dart';
import 'send_request_with_script_test.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';

class MockEventBus extends Mock implements EventBus {}

const collection1Path = 'test/support/collection1';

late HttpTestServer mockServer;

void main() {
  return;
  late MockEventBus mockEventBus;
  late FakeAppStorage fakeAppStorage;
  late CollectionRepo collectionRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;

  final config = Config(
    isTest: false,
    trayceApiUrl: '',
    appSupportDir: Directory.current.path,
    appDocsDir: Directory.current.path,
  );

  setUpAll(() async {
    // TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
    fakeAppStorage = await FakeAppStorage.getInstance();
    collectionRepo = CollectionRepo(fakeAppStorage);
    folderRepo = FolderRepo();
    requestRepo = RequestRepo();

    mockServer = await HttpTestServer.create();

    setupNodeJs(config);
  });

  tearDownAll(() async {
    await mockServer.close();
  });

  test('sending a request with a pre-request that calls bru.sendRequest()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured[0] as EventDisplayExplorerItems;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';
    final jsScript = '''await bru.sendRequest({
  method: 'GET',
  url: 'https://trayce.dev',
  headers: {
    'Content-Type': 'application/json',
  },
  data: { key: 'value' },
}, function (err, res) {
  if (err) {
    console.error('Error:', err);
    return;
  }
  console.log('Response:', res.status);
});''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          explorerService: explorerService,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 1);
    expect(result.output[0], 'Response: 200');
  });

  test('sending a request with a pre-request that calls bru.runRequest()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured[0] as EventDisplayExplorerItems;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.runRequest('hello/hello.bru');''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          explorerService: explorerService,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 1);
    expect(result.output[0], 'Response: 200');
  });
}
