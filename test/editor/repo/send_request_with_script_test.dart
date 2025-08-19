import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/collection.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/script.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/setup_nodejs.dart';

import '../../support/fake_app_storage.dart';

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
  late MockEventBus mockEventBus;
  late FakeAppStorage fakeAppStorage;
  late CollectionRepo collectionRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late ExplorerService explorerService;

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
    fakeAppStorage = await FakeAppStorage.getInstance();
    collectionRepo = CollectionRepo(fakeAppStorage);
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

  test('sending a request with a pre-request script using the request object getters', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''
    console.log(req.getUrl());
    console.log(req.getMethod());
    console.log(req.getHeaders());
    console.log(req.getHeader("X-Trayce-Token"));
    console.log(req.getBody()['hello']);
    console.log(req.getName());
    console.log(req.getAuthMode());
    console.log(req.getTimeout());
    console.log(req.getExecutionMode());
    console.log(req.getExecutionPlatform());
    ''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(req: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: node,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    expect(mockServer.sentRequest!.url.query, 'hello=world&x-trayce-token=abcd1234');
    mockServer.reset();

    expect(result.output.length, 10);
    expect(result.output[0], contains('http://localhost:'));
    expect(result.output[0], contains('{{A_var}}?hello=world'));
    expect(result.output[1], contains('POST'));
    expect(result.output[2], contains("{ 'X-Trayce-Token': 'abcd1234', 'content-type': 'application/json' }"));
    expect(result.output[3], contains('abcd1234'));
    expect(result.output[4], contains('world'));
    expect(result.output[5], contains('Test Request'));
    expect(result.output[6], contains('apikey'));
    expect(result.output[7], contains('10000'));
    expect(result.output[8], contains('standalone'));
    expect(result.output[9], contains('app'));
  });

  test('sending a request with a pre-request script using the request object setters', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''
    req.setUrl('$url&added_by_script=true');
    req.setMethod('post');
    req.setTimeout(1234);
    req.setHeaders({'X-Trayce-Token': 'from-the-script'});
    req.setHeader("accept", "application/json");
    req.setBody({hey: 'howareyou'});
    ''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(req: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
    expect(mockServer.sentRequest!.url.query, 'hello=world&added_by_script=true&x-trayce-token=abcd1234');

    expect(mockServer.sentRequest!.headers['x-trayce-token'], 'from-the-script');
    expect(mockServer.sentRequest!.headers['accept'], 'application/json');
    expect(mockServer.sentRequestBody, '{"hey":"howareyou"}');
    mockServer.reset();
  });

  // Ensure json serialization and deserialization works as expected
  test('sending a request with a pre-request script and a json body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = 'console.log("ok")';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(req: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, '{"hello":"world"}');
    mockServer.reset();
  });

  test('sending a request with a pre-request script that modifies a text body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''
    req.setBody("modified by script");
    ''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.text,
      bodyText: TextBody(content: 'helloworld'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true)],
      script: Script(req: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, 'modified by script');
    mockServer.reset();
  });

  test('sending a request with a post-response script using the response object getters', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''
    console.log(res.getStatus());
    console.log(res.getStatusText());
    console.log(res.getUrl());
    console.log(res.getHeader('content-type'));
    console.log(res.getBody({raw: true}));
    console.log(res.getSize().body);
    console.log(res.getSize().headers);
    console.log(res.getSize().total);
    console.log(res.getResponseTime());
    console.log(res('message'));
    ''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(res: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    mockServer.reset();

    print(result.output);
    expect(result.output.length, 10);
    expect(result.output[0], '200');
    expect(result.output[1], 'OK');
    expect(result.output[2], contains('http://localhost:'));
    expect(result.output[2], contains('/test_endpoint?hello=world&x-trayce-token=abcd1234'));
    expect(result.output[3], 'application/json');
    expect(result.output[4], '{"message":"Hello, World!","status":200}');
    expect(result.output[5], '40');
    expect(result.output[6], '223');
    expect(result.output[7], '263');
    expect(result.output[8], isNotEmpty);
  });

  test('sending a request with a post-response script using the response query', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''
    console.log(res('message'));
    ''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(res: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    mockServer.reset();

    print(result.output);
    expect(result.output.length, 1);
    expect(result.output[0], 'Hello, World!');
  });

  test('sending a request with a post-response script calling res.setBody()', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}{{A_var}}?hello=world';

    final jsScript = '''res.setBody('{"new": "value-from-script"}');''';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello":"world"}'),
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [
        Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true),
        Header(name: 'content-type', value: 'application/json', enabled: true),
      ],
      script: Script(res: jsScript),
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final node = ExplorerNode.newRequest('test-req', request);

    final result =
        await SendRequest(
          request: request,
          node: node,
          collectionNode: collectionNode,
          explorerService: explorerService,
          runtimeVarsRepo: RuntimeVarsRepo(),
          config: config,
          httpClient: HttpClient(),
        ).send();
    final response = result.response;

    expect(response.statusCode, 200);
    mockServer.reset();

    print(result.output);
    expect(result.output.length, 0);
    expect(result.response.body, '{"new": "value-from-script"}');
  });
}
