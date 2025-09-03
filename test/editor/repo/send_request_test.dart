import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/global_environment.dart';
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

import '../../support/fake_app_storage.dart';

class MockEventBus extends Mock implements EventBus {}

class MockAppStorage extends Mock implements AppStorageI {}

const collection1Path = 'test/support/collection1';
void main() {
  late MockEventBus mockEventBus;
  late AppStorageI mockAppStorage;
  late CollectionRepo collectionRepo;
  late EnvironmentRepo environmentRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late Config config;

  mockEventBus = MockEventBus();
  mockAppStorage = FakeAppStorage();
  collectionRepo = CollectionRepo(mockAppStorage);
  environmentRepo = EnvironmentRepo(mockAppStorage);
  folderRepo = FolderRepo();
  requestRepo = RequestRepo();
  config = Config(isTest: true, trayceApiUrl: 'http://localhost:8080', appSupportDir: './nodejs', appDocsDir: '.');

  group('SendRequest()', () {
    test('sends a request using the node hierarchy headers', () async {
      final runtimeVarsRepo = RuntimeVarsRepo(eventBus: mockEventBus);
      runtimeVarsRepo.setVar('my_key2', 'RUNTIME');

      final globalEnvRepo = GlobalEnvironmentRepo(mockAppStorage);
      await globalEnvRepo.save([
        GlobalEnvironment(name: 'global', vars: [Variable(name: 'global_var', value: 'GLOBAL', enabled: true)]),
      ]);
      globalEnvRepo.setSelectedEnvName('global');

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
      collection.setCurrentEnvironment('dev');

      final reqThree = event.nodes[0].children[1].children[2];
      expect(reqThree.name, 'three.bru');
      expect(reqThree, isA<RequestNode>());

      final hierarchy = explorerService.getNodeHierarchy(reqThree);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'three.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: (reqThree as RequestNode).request,
        node: reqThree,
        collectionNode: event.nodes[0] as CollectionNode,
        explorerService: explorerService,
        runtimeVarsRepo: runtimeVarsRepo,
        environmentRepo: environmentRepo,
        globalEnvironmentRepo: globalEnvRepo,
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

      print('finalReq.requestVars:');
      for (final reqvar in finalReq.requestVars) {
        print('  ${reqvar.name}: ${reqvar.value}');
      }

      // Verify variables
      expect(finalReq.requestVars.length, 8);
      // Global environment vars:
      expect(finalReq.requestVars[0].name, 'global_var');
      expect(finalReq.requestVars[0].value, 'GLOBAL');
      // Collection vars:
      expect(finalReq.requestVars[1].name, 'C_var');
      expect(finalReq.requestVars[1].value, 'set from collection');
      // Environment vars:
      expect(finalReq.requestVars[2].name, 'process.env.key');
      expect(finalReq.requestVars[2].value, 'password1');
      expect(finalReq.requestVars[3].name, 'my_key');
      expect(finalReq.requestVars[3].value, '1234abcd');
      expect(finalReq.requestVars[4].name, 'my_password');
      expect(finalReq.requestVars[4].value, isNull);
      // Folder vars:
      expect(finalReq.requestVars[5].name, 'B_var');
      expect(finalReq.requestVars[5].value, 'set from folder');
      // Request vars:
      expect(finalReq.requestVars[6].name, 'A_var');
      expect(finalReq.requestVars[6].value, 'set from request');
      // Runtime vars:
      expect(finalReq.requestVars[7].name, 'my_key2');
      expect(finalReq.requestVars[7].value, 'RUNTIME');

      // Verify auth
      expect(finalReq.authType, AuthType.bearer);
      // final auth = finalReq.getAuth() as BearerAuth;
      // expect(auth.token, 'helloworld');
    });

    test('sends a request using the request auth', () async {
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
      collection.setCurrentEnvironment('dev');

      final reqFour = event.nodes[0].children[1].children[3];
      expect(reqFour.name, 'four.bru');
      expect(reqFour, isA<RequestNode>());

      final hierarchy = explorerService.getNodeHierarchy(reqFour);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'four.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: (reqFour as RequestNode).request,
        node: reqFour,
        collectionNode: event.nodes[0] as CollectionNode,
        explorerService: explorerService,
        runtimeVarsRepo: RuntimeVarsRepo(eventBus: mockEventBus),
        environmentRepo: environmentRepo,
        globalEnvironmentRepo: GlobalEnvironmentRepo(mockAppStorage),
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
      collection.setCurrentEnvironment('dev');

      final reqFour = event.nodes[0].children[0].children[0];
      expect(reqFour.name, 'hello.bru');
      expect(reqFour, isA<RequestNode>());

      final hierarchy = explorerService.getNodeHierarchy(reqFour);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'hello.bru');
      expect(hierarchy[1].name, 'hello');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(
        request: (reqFour as RequestNode).request,
        node: reqFour,
        collectionNode: event.nodes[0] as CollectionNode,
        explorerService: explorerService,
        runtimeVarsRepo: RuntimeVarsRepo(eventBus: mockEventBus),
        environmentRepo: environmentRepo,
        globalEnvironmentRepo: GlobalEnvironmentRepo(mockAppStorage),
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
