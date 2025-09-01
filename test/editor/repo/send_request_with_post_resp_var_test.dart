import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
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
import 'send_request_test.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';

class MockEventBus extends Mock implements EventBus {}

const collection1Path = 'test/support/collection1';

class HttpTestServer {
  late ShelfTestServer server;
  shelf.Request? sentRequest;
  String? sentRequestBody;
  List<int>? sentRequestBytes;
  List<List<int>>? sentFiles;
  Map<String, String>? sentHeaders;

  HttpTestServer(this.server);

  static Future<HttpTestServer> create() async {
    final server = await ShelfTestServer.create();
    return HttpTestServer(server);
  }

  Uri url() => server.url;

  Future<void> close() async {
    await server.close(force: true);
  }

  void reset() {
    sentRequest = null;
    sentRequestBody = null;
    sentRequestBytes = null;
    sentFiles = null;
    sentHeaders = null;
  }

  newHandler(String method, String path) {
    sentRequest = null;
    sentRequestBody = null;
    sentRequestBytes = null;

    server.handler.expect(method, path, (request) async {
      sentRequest = request;
      sentRequestBody = await request.readAsString();
      sentHeaders = request.headers;

      return shelf.Response.ok(jsonResponse, headers: {"content-type": "application/json"});
    });
  }

  newFileHandler(String method, String path) {
    sentRequest = null;
    sentRequestBody = null;
    sentRequestBytes = null;

    server.handler.expect(method, path, (request) async {
      sentRequest = request;
      sentFiles = await request.read().toList();
      sentHeaders = request.headers;

      return shelf.Response.ok(jsonResponse, headers: {"content-type": "application/json"});
    });
  }
}

late HttpTestServer mockServer;

void main() {
  late MockAppStorage mockAppStorage;
  late MockEventBus mockEventBus;
  late FakeAppStorage fakeAppStorage;
  late CollectionRepo collectionRepo;
  late EnvironmentRepo environmentRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late ExplorerService explorerService;
  late RuntimeVarsRepo runtimeVarsRepo;
  final collection = Collection(
    file: File('test.collection'),
    dir: Directory('test.collection'),
    type: 'http',
    environments: [],
    headers: [],
    query: [],
    authType: AuthType.none,
    requestVars: [],
    responseVars: [],
  );
  final collectionNode = ExplorerNode(name: 'Test Collection', type: NodeType.collection, collection: collection);

  setUpAll(() async {
    mockEventBus = MockEventBus();
    mockAppStorage = MockAppStorage();
    fakeAppStorage = FakeAppStorage();
    collectionRepo = CollectionRepo(fakeAppStorage);
    environmentRepo = EnvironmentRepo(fakeAppStorage);
    runtimeVarsRepo = RuntimeVarsRepo(eventBus: mockEventBus);
    folderRepo = FolderRepo();
    requestRepo = RequestRepo();

    explorerService = ExplorerService(
      eventBus: mockEventBus,
      collectionRepo: collectionRepo,
      folderRepo: folderRepo,
      requestRepo: requestRepo,
    );

    mockServer = await HttpTestServer.create();
    final config = Config(
      isTest: false,
      trayceApiUrl: '',
      appSupportDir: Directory.current.path,
      appDocsDir: Directory.current.path,
    );
    setupNodeJs(config);
  });

  tearDownAll(() async {
    await mockServer.close();
  });

  final config = Config(
    isTest: true,
    trayceApiUrl: 'http://localhost:8080',
    appSupportDir: Directory.current.path,
    appDocsDir: Directory.current.path,
  );

  test('sending a request with a post-response script using the response query', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.none,
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      requestVars: [],
      responseVars: [
        Variable(name: 'A_var', value: 'res("message")', enabled: true),
        Variable(name: 'B_var', value: 'res.body.message', enabled: true),
      ],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: runtimeVarsRepo,
          environmentRepo: environmentRepo,
          globalEnvironmentRepo: GlobalEnvironmentRepo(mockAppStorage),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    mockServer.reset();

    print("============================>\n ${result.output}");

    final runtimeVars = runtimeVarsRepo.toMapList();
    expect(runtimeVars.length, 2);
    expect(runtimeVars[0]['name'], 'A_var');
    expect(runtimeVars[0]['value'], 'Hello, World!');
    expect(runtimeVars[1]['name'], 'B_var');
    expect(runtimeVars[1]['value'], 'Hello, World!');
  });
}
