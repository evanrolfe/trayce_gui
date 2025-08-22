import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/script.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/environment_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/global_environment_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/setup_nodejs.dart';

import '../../support/fake_app_storage.dart';
import '../../support/helpers.dart';
import 'send_request_test.dart';
import 'send_request_with_script_test.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';

class MockEventBus extends Mock implements EventBus {}

const collection1Path = 'test/support/collection1';

late HttpTestServer mockServer;

void main() {
  late MockEventBus mockEventBus;
  late MockAppStorage mockAppStorage;
  late FakeAppStorage fakeAppStorage;
  late CollectionRepo collectionRepo;
  late EnvironmentRepo environmentRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late GlobalEnvironmentRepo globalEnvironmentRepo;

  final config = Config(
    isTest: false,
    trayceApiUrl: '',
    appSupportDir: Directory.current.path,
    appDocsDir: Directory.current.path,
  );

  setUpAll(() async {
    // TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
    mockAppStorage = MockAppStorage();
    fakeAppStorage = await FakeAppStorage.getInstance();
    collectionRepo = CollectionRepo(fakeAppStorage);
    environmentRepo = EnvironmentRepo(fakeAppStorage);
    folderRepo = FolderRepo();
    requestRepo = RequestRepo();
    globalEnvironmentRepo = GlobalEnvironmentRepo(mockAppStorage);

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
    final event = captured.whereType<EventDisplayExplorerItems>().first;

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
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(eventBus: mockEventBus),
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
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
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''let resp = await bru.runRequest('hello/hello.bru'); console.log("Response:", resp.status);''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(eventBus: mockEventBus),
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
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

  test('sending a request with a post-response script that calls bru.getVar()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''console.log(bru.getVar('test_var'));''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 1);
    expect(result.output[0], 'test_value');
  });

  test('sending a request with a post-response script that calls bru.getRequestVar() etc.', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript =
        '''console.log(bru.getRequestVar('A')); console.log(bru.getCollectionVar('A_var')); console.log(bru.getEnvVar('my_key'));''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 3);
    expect(result.output[0], 'set-in-request');
    expect(result.output[1], 'set from collection');
    expect(result.output[2], '1234abcd');
  });

  test('sending a request with a pre-request script that calls bru.setVar()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.setVar('test_var2', 'test_value2'); console.log(bru.getVar('test_var2'));''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 1);
    expect(result.output[0], 'test_value2');

    expect(runtimeVarsRepo.getVar('test_var2')?.value, 'test_value2');
  });

  test('sending a request with a post-response script that calls bru.setVar()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.setVar('test_var2', 'test_value2'); console.log(bru.getVar('test_var2'));''';
    final request = node.request!;
    request.url = url;
    request.script = Script(res: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 1);
    expect(result.output[0], 'test_value2');

    expect(runtimeVarsRepo.getVar('test_var2')?.value, 'test_value2');
  });

  test('sending a request with a post-response script that calls bru.deleteVar()', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.deleteVar('test_var');''';
    final request = node.request!;
    request.url = url;
    request.script = Script(res: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    expect(result.output.length, 0);
    expect(runtimeVarsRepo.getVar('test_var'), isNull);
  });

  test('sending a request with a pre-request script that calls bru.setEnvVar()', () async {
    final originalEnv = loadFile('test/support/collection1/environments/dev.bru');

    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.setEnvVar('test_var3', 'test_value3');''';
    final request = node.request!;
    request.url = url;
    request.script = Script(req: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    print(result.output);
    expect(result.output.length, 0);

    final envContents = loadFile('test/support/collection1/environments/dev.bru');
    expect(
      envContents,
      contains('''vars {
  my_key: 1234abcd
  test_var3: test_value3
}'''),
    );

    expect(
      envContents,
      contains('''vars:secret [
  my_password
]'''),
    );

    saveFile('test/support/collection1/environments/dev.bru', originalEnv);
  });

  test('sending a request with a post-response script that calls bru.setEnvVar()', () async {
    final originalEnv = loadFile('test/support/collection1/environments/dev.bru');

    mockServer.newHandler('GET', '/test_endpoint');

    // Open the collection and load the request
    final runtimeVarsRepo = RuntimeVarsRepo(
      vars: [Variable(name: 'test_var', value: 'test_value', enabled: true)],
      eventBus: mockEventBus,
    );
    final explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );
    explorerService.openCollection(collection1Path);

    final captured = verify(() => mockEventBus.fire(captureAny())).captured;
    final event = captured.whereType<EventDisplayExplorerItems>().first;

    final collection = explorerService.getOpenCollections()[0];
    collection.setCurrentEnvironment(collection.environments[0].fileName());

    final node = event.nodes[0].children[2];
    expect(node.name, 'my-request.bru');

    // Set the URL and script on the request
    final url = '${mockServer.url().toString()}/test_endpoint';

    final jsScript = '''bru.setEnvVar('test_var3', 'test_value3');''';
    final request = node.request!;
    request.url = url;
    request.script = Script(res: jsScript);

    // Send the request with the node hierarchy
    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: event.nodes[0],
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: globalEnvironmentRepo,
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    // Verify the response
    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    mockServer.reset();

    print(result.output);
    expect(result.output.length, 0);

    final envContents = loadFile('test/support/collection1/environments/dev.bru');
    expect(
      envContents,
      contains('''vars {
  my_key: 1234abcd
  test_var3: test_value3
}'''),
    );

    expect(
      envContents,
      contains('''vars:secret [
  my_password
]'''),
    );

    saveFile('test/support/collection1/environments/dev.bru', originalEnv);
  });
}
