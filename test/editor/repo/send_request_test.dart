import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';

class MockEventBus extends Mock implements EventBus {}

class MockAppStorage extends Mock implements AppStorageI {}

const collection1Path = 'test/support/collection1';
void main() {
  late MockEventBus mockEventBus;
  late MockAppStorage mockAppStorage;
  late CollectionRepo collectionRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late Config config;
  final emptySecretVars = Map<String, String>.from({});

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
    mockAppStorage = MockAppStorage();
    collectionRepo = CollectionRepo(mockAppStorage);
    folderRepo = FolderRepo();
    requestRepo = RequestRepo();
    config = Config(isTest: true, trayceApiUrl: 'http://localhost:8080', appSupportDir: './nodejs', appDocsDir: '.');
  });

  group('SendRequest()', () {
    test('sends a request using the node hierarchy headers', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

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

      final reqThree = event.nodes[0].children[1].children[2];
      expect(reqThree.name, 'three.bru');

      final hierarchy = explorerService.getNodeHierarchy(reqThree);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'three.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: reqThree.request!,
        node: reqThree,
        collectionNode: event.nodes[0],
        explorerService: explorerService,
        runtimeVarsRepo: RuntimeVarsRepo(),
        config: config,
        httpClient: HttpClient(),
      ).getFinalRequest(reqThree);

      // Verify the URL
      expect(finalReq.url, 'www.synack.com/three/users/show/123');

      // Verify headers
      expect(finalReq.headers.length, 5);
      expect(finalReq.headers[0].name, 'D');
      expect(finalReq.headers[0].value, "set from collection");
      expect(finalReq.headers[1].name, 'changed-by-test');
      expect(finalReq.headers[1].value, "changed-by-test");
      expect(finalReq.headers[2].name, 'C');
      expect(finalReq.headers[2].value, 'set from folder');
      expect(finalReq.headers[3].name, 'A');
      expect(finalReq.headers[3].value, 'set from request');

      // print('finalReq.requestVars:');
      // for (final reqvar in finalReq.requestVars) {
      //   print('  ${reqvar.name}: ${reqvar.value}');
      // }

      // Verify variables
      expect(finalReq.requestVars.length, 6);
      expect(finalReq.requestVars[0].name, 'my_key');
      expect(finalReq.requestVars[0].value, '1234abcd');
      expect(finalReq.requestVars[1].name, 'my_password');
      expect(finalReq.requestVars[1].value, isNull);
      expect(finalReq.requestVars[2].name, 'C_var');
      expect(finalReq.requestVars[2].value, 'set from collection');
      expect(finalReq.requestVars[3].name, 'process.env.key');
      expect(finalReq.requestVars[3].value, 'password1');
      expect(finalReq.requestVars[4].name, 'B_var');
      expect(finalReq.requestVars[4].value, 'set from folder');
      expect(finalReq.requestVars[5].name, 'A_var');
      expect(finalReq.requestVars[5].value, 'set from request');

      // Verify auth
      expect(finalReq.authType, AuthType.bearer);
      // final auth = finalReq.getAuth() as BearerAuth;
      // expect(auth.token, 'helloworld');
    });

    test('sends a request using the request auth', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

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

      final reqFour = event.nodes[0].children[1].children[3];
      expect(reqFour.name, 'four.bru');

      final hierarchy = explorerService.getNodeHierarchy(reqFour);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'four.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: reqFour.request!,
        node: reqFour,
        collectionNode: event.nodes[0],
        explorerService: explorerService,
        runtimeVarsRepo: RuntimeVarsRepo(),
        config: config,
        httpClient: HttpClient(),
      ).getFinalRequest(reqFour);

      // Verify auth
      expect(finalReq.authType, AuthType.basic);
      final auth = finalReq.getAuth() as BasicAuth;
      expect(auth.username, 'hello');
      expect(auth.password, 'world');
    });

    test('sends a request using the collection auth', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

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

      final reqFour = event.nodes[0].children[0].children[0];
      expect(reqFour.name, 'hello.bru');

      final hierarchy = explorerService.getNodeHierarchy(reqFour);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'hello.bru');
      expect(hierarchy[1].name, 'hello');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: reqFour.request!,
        node: reqFour,
        collectionNode: event.nodes[0],
        explorerService: explorerService,
        runtimeVarsRepo: RuntimeVarsRepo(),
        config: config,
        httpClient: HttpClient(),
      ).getFinalRequest(reqFour);

      // Verify auth
      expect(finalReq.authType, AuthType.basic);
      final auth = finalReq.getAuth() as BasicAuth;
      expect(auth.username, 'asdf');
      expect(auth.password, 'asdf');
    });
  });
}
