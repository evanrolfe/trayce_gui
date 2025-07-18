import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';

import '../../support/helpers.dart';

class MockEventBus extends Mock implements EventBus {}

class MockAppStorage extends Mock implements AppStorageI {}

const collection1Path = 'test/support/collection1';
void main() {
  late MockEventBus mockEventBus;
  late MockAppStorage mockAppStorage;
  late CollectionRepo collectionRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  final emptySecretVars = Map<String, String>.from({});

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
    mockAppStorage = MockAppStorage();
    collectionRepo = CollectionRepo(mockAppStorage);
    folderRepo = FolderRepo();
    requestRepo = RequestRepo();
  });

  group('openCollection()', () {
    test('it loads collection1 successfully', () async {
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

      expect(event.nodes[0].name, 'collection1');
      expect(event.nodes[0].type, NodeType.collection);
      final collection = event.nodes[0].collection;
      expect(collection?.type, 'collection');
      final collectionAuth = collection?.auth as BasicAuth;
      expect(collectionAuth.username, 'asdf');
      expect(collectionAuth.password, 'asdf');
      expect(collection?.requestVars[0].name, 'A_var');
      expect(collection?.requestVars[0].value, 'set from collection');

      expect(collection?.environments.length, 2);

      // Environment 1 - dev.bru
      final devEnv = collection?.environments.firstWhere((e) => e.fileName() == 'dev');
      expect(devEnv, isNotNull);
      expect(devEnv?.vars.length, 2);
      expect(devEnv?.vars[0].name, 'my_key');
      expect(devEnv?.vars[0].value, '1234abcd');
      expect(devEnv?.vars[0].secret, false);
      expect(devEnv?.vars[1].name, 'my_password');
      expect(devEnv?.vars[1].value, isNull);
      expect(devEnv?.vars[1].secret, true);

      // Environment 2 - test.bru
      final testEnv = collection?.environments.firstWhere((e) => e.fileName() == 'test');
      expect(testEnv, isNotNull);
      expect(testEnv?.vars.length, 1);
      expect(testEnv?.vars[0].name, 'my_key');
      expect(testEnv?.vars[0].value, 'testtest');
      expect(testEnv?.vars[0].secret, false);

      expect(event.nodes[0].children[0].name, 'hello');
      expect(event.nodes[0].children[0].type, NodeType.folder);
      expect(event.nodes[0].children[1].name, 'myfolder');
      expect(event.nodes[0].children[1].type, NodeType.folder);
      expect(event.nodes[0].children[2].name, 'my-request.bru');
      expect(event.nodes[0].children[2].type, NodeType.request);
      Request? request = event.nodes[0].children[2].request;
      expect(request?.method, 'get');
      expect(request?.url, 'https://trayce.dev');
      expect(request?.headers[0].name, 'hello');
      expect(request?.headers[0].value, 'world');

      expect(event.nodes[0].children[1].children[0].name, 'one.bru');
      expect(event.nodes[0].children[1].children[0].type, NodeType.request);
      request = event.nodes[0].children[1].children[0].request;
      expect(request?.method, 'post');
      expect(request?.url, 'http://www.github.com/one');

      expect(event.nodes[0].children[1].children[1].name, 'two.bru');
      expect(event.nodes[0].children[1].children[1].type, NodeType.request);
      expect(event.nodes[0].children[1].children[2].name, 'three.bru');
      expect(event.nodes[0].children[1].children[2].type, NodeType.request);
      expect(event.nodes[0].children[1].children[3].name, 'four.bru');
      expect(event.nodes[0].children[1].children[3].type, NodeType.request);
      expect(event.nodes[0].children[1].children[4].name, 'five.bru');
      expect(event.nodes[0].children[1].children[4].type, NodeType.request);
    });
  });

  group('getNextSeq()', () {
    test('returns the next sequence number for a folder with a trailing slash', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );
      explorerService.openCollection(collection1Path);
      verify(() => mockEventBus.fire(captureAny())).captured;

      final seq = explorerService.getNextSeq('test/support/collection1/myfolder/');
      expect(seq, 6);
    });

    test('returns the next sequence number for a folder without a trailing slash', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );
      explorerService.openCollection(collection1Path);
      verify(() => mockEventBus.fire(captureAny())).captured;

      final seq = explorerService.getNextSeq('test/support/collection1/myfolder');
      expect(seq, 6);
    });

    test('returns the next sequence number for collection root', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );
      explorerService.openCollection(collection1Path);
      verify(() => mockEventBus.fire(captureAny())).captured;

      final seq = explorerService.getNextSeq(collection1Path);
      expect(seq, 2);
    });
  });

  group('getNodeHierarchy()', () {
    test('returns the node hierarchy', () async {
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

      final reqThree = event.nodes[0].children[1].children[2];
      expect(reqThree.name, 'three.bru');

      final hierarchy = explorerService.getNodeHierarchy(reqThree);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'three.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');
    });
  });

  group('moveNode()', () {
    test('moving a request to another folder', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      expect(event.nodes[0].children[1].name, 'myfolder');
      final movedNode = event.nodes[0].children[1].children[2];
      expect(movedNode.name, 'three.bru');
      expect(movedNode.type, NodeType.request);

      // Target Node:
      final targetNode = event.nodes[0].children[0];
      expect(targetNode.name, 'hello');
      expect(targetNode.type, NodeType.folder);

      explorerService.moveNode(movedNode, targetNode);

      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect hello have 1 request
      expect(event2.nodes[0].children[0].name, 'hello');
      expect(event2.nodes[0].children[0].children.length, 1);
      expect(event2.nodes[0].children[0].children[0].name, 'three.bru');

      final fiveReq = event2.nodes[0].children[0].children[0].request;
      expect(fiveReq?.seq, 0);

      // Expect test-myfolder to have 4 requests
      final testMyFolder = event2.nodes[0].children[1];
      expect(testMyFolder.name, 'myfolder');
      expect(testMyFolder.children.length, 4);

      // Expect test-myfolder to have requests with the correct seq number
      final expectedFiles = ['one.bru', 'two.bru', 'four.bru', 'five.bru'];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = testMyFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      // Expect three.bru to have seq 0
      final threeReqNew = testMyFolder.children[0].request;
      expect(threeReqNew?.seq, 0);

      await deleteFolder(newFolderPath);
      return;
    });

    test('re-ordering a request within the same folder ahead', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      final movedNode = event.nodes[0].children[1].children[0];
      expect(movedNode.name, 'one.bru');
      expect(movedNode.type, NodeType.request);

      // Target Node:
      final targetNode = event.nodes[0].children[1].children[3];
      expect(targetNode.name, 'four.bru');
      expect(targetNode.type, NodeType.request);

      explorerService.moveNode(movedNode, targetNode);

      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect test-mmyfolder to have 4 requests
      final testMyFolder = event2.nodes[0].children[1];
      expect(testMyFolder.name, 'myfolder');
      expect(testMyFolder.children.length, 5);

      // Expect test-myfolder to have requests with the correct seq number
      final expectedFiles = ['two.bru', 'three.bru', 'four.bru', 'one.bru', 'five.bru'];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = testMyFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      await deleteFolder(newFolderPath);
    });

    test('re-ordering a request within the same folder behind', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      final movedNode = event.nodes[0].children[1].children[3];
      expect(movedNode.name, 'four.bru');
      expect(movedNode.type, NodeType.request);

      // Target Node:
      final targetNode = event.nodes[0].children[1].children[0];
      expect(targetNode.name, 'one.bru');
      expect(targetNode.type, NodeType.request);

      explorerService.moveNode(movedNode, targetNode);

      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect test-mmyfolder to have 4 requests
      final testMyFolder = event2.nodes[0].children[1];
      expect(testMyFolder.name, 'myfolder');
      expect(testMyFolder.children.length, 5);

      // Expect test-myfolder to have requests with the correct seq number
      final expectedFiles = ['one.bru', 'four.bru', 'two.bru', 'three.bru', 'five.bru'];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = testMyFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      await deleteFolder(newFolderPath);
    });

    test('re-ordering a request within the same folder to first position', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      final movedNode = event.nodes[0].children[1].children[3];
      expect(movedNode.name, 'four.bru');
      expect(movedNode.type, NodeType.request);

      // Target Node:
      final targetNode = event.nodes[0].children[1];
      expect(targetNode.name, 'myfolder');
      expect(targetNode.type, NodeType.folder);

      explorerService.moveNode(movedNode, targetNode);

      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect test-mmyfolder to have 4 requests
      final testMyFolder = event2.nodes[0].children[1];
      expect(testMyFolder.name, 'myfolder');
      expect(testMyFolder.children.length, 5);

      // Expect test-myfolder to have requests with the correct seq number
      final expectedFiles = ['four.bru', 'one.bru', 'two.bru', 'three.bru', 'five.bru'];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = testMyFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      await deleteFolder(newFolderPath);
    });

    test('dragging a request to another folder and in a specific position', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      final movedNode = event.nodes[0].children[2];
      expect(movedNode.name, 'my-request.bru');
      expect(movedNode.type, NodeType.request);

      // Target Node:
      final targetNode = event.nodes[0].children[1].children[1];
      expect(targetNode.name, 'two.bru');
      expect(targetNode.type, NodeType.request);

      explorerService.moveNode(movedNode, targetNode);
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect test-mmyfolder to have 6 requests
      final testMyFolder = event2.nodes[0].children[1];
      expect(testMyFolder.name, 'myfolder');
      expect(testMyFolder.children.length, 6);

      // Expect test-myfolder to have requests with the correct seq number
      final expectedFiles = ['one.bru', 'two.bru', 'my-request.bru', 'three.bru', 'four.bru', 'five.bru'];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = testMyFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      await deleteFolder(newFolderPath);
    });

    test('dragging a folder to another folder', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Moved Node:
      final movedNode = event.nodes[0].children[1];
      expect(movedNode.name, 'myfolder');
      expect(movedNode.type, NodeType.folder);

      // Target Node:
      final targetNode = event.nodes[0].children[0];
      expect(targetNode.name, 'hello');
      expect(targetNode.type, NodeType.folder);

      await explorerService.moveNode(movedNode, targetNode);
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect hello to have 1 child which is myfolder
      final helloFolder = event2.nodes[0].children[0];
      expect(helloFolder.name, 'hello');
      expect(helloFolder.children.length, 1);
      expect(helloFolder.children[0].name, 'myfolder');
      expect(helloFolder.children[0].children.length, 5);

      await deleteFolder(newFolderPath);
    });
  });

  group('renameNode()', () {
    test('renaming a collection', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to rename:
      final node = event.nodes[0];
      expect(node.name, 'collection1-test');
      expect(node.type, NodeType.collection);
      expect(event.nodes.length, 1);

      await explorerService.renameNode(node, 'collection1-new');
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect myfolder to be renamed to newname
      final node2 = event2.nodes[0];
      expect(node2.name, 'collection1-new');
      expect(node2.type, NodeType.collection);
      expect(event2.nodes.length, 1);

      final renamedPath = path.join(path.dirname(newFolderPath), 'collection1-new');
      print('renamedPath: $renamedPath');
      await deleteFolder(renamedPath);
    });
    test('renaming a folder', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to rename:
      final node = event.nodes[0].children[1];
      expect(node.name, 'myfolder');
      expect(node.type, NodeType.folder);
      expect(event.nodes[0].children.length, 4);

      await explorerService.renameNode(node, 'newname');
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;

      // Expect myfolder to be renamed to newname
      final node2 = event2.nodes[0].children[1];
      expect(node2.name, 'newname');
      expect(node.type, NodeType.folder);
      expect(event2.nodes[0].children.length, 4);

      await deleteFolder(newFolderPath);
    });

    test('renaming a request', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to rename:
      final node = event.nodes[0].children[2];
      expect(node.name, 'my-request.bru');
      expect(node.type, NodeType.request);

      await explorerService.renameNode(node, 'newname');
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[1] as EventDisplayExplorerItems;

      // Expect myfolder to be renamed to newname
      final node2 = event2.nodes[0].children[2];
      expect(node2.name, 'newname.bru');
      expect(node2.type, NodeType.request);

      await deleteFolder(newFolderPath);
    });
  });

  // TODO: Get this test working
  // group('createCollection()', () {
  //   test('creating a new collection', () async {
  //     final newFolderPath = '$collection1Path-new';

  //     final collectionDir = Directory(newFolderPath);
  //     await collectionDir.create();

  //     final explorerService = ExplorerRepo(eventBus: mockEventBus);

  //     explorerService.createCollection(newFolderPath);
  //     final captured = verify(() => mockEventBus.fire(captureAny())).captured;
  //     final event = captured[0] as EventDisplayExplorerItems;

  //     expect(event.nodes.length, 2);
  //     // expect(node.name, 'collection1-test');
  //     // expect(node.type, NodeType.collection);
  //     // expect(event.nodes.length, 1);

  //     await deleteFolder(newFolderPath);
  //   });
  // });

  group('deleteNode()', () {
    test('deleting a collection', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to delete:
      final node = event.nodes[0];
      expect(node.name, 'collection1-test');
      expect(node.type, NodeType.collection);

      // Delete the node
      await explorerService.deleteNode(node);
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;
      expect(event2.nodes.length, 0);
    });

    test('deleting a folder', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to delete:
      final node = event.nodes[0].children[1];
      expect(event.nodes[0].children[1].children.length, 5);
      expect(node.name, 'myfolder');
      expect(node.type, NodeType.folder);

      // Delete the node
      await explorerService.deleteNode(node);
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;
      expect(event2.nodes[0].children.length, 3);

      await deleteFolder(newFolderPath);
    });

    test('deleting a request', () async {
      when(() => mockAppStorage.getSecretVars(any(), any())).thenAnswer((_) async => emptySecretVars);

      final explorerService = ExplorerService(
        eventBus: mockEventBus,
        collectionRepo: collectionRepo,
        folderRepo: folderRepo,
        requestRepo: requestRepo,
      );

      final folderPath = collection1Path;
      final newFolderPath = '$collection1Path-test';
      await copyFolder(folderPath, newFolderPath);

      explorerService.openCollection(newFolderPath);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      // Node to delete:
      final node = event.nodes[0].children[1].children[0];
      expect(event.nodes[0].children[1].children.length, 5);
      expect(node.name, 'one.bru');
      expect(node.type, NodeType.request);

      // Delete the node
      await explorerService.deleteNode(node);
      final captured2 = verify(() => mockEventBus.fire(captureAny())).captured;
      final event2 = captured2[0] as EventDisplayExplorerItems;
      expect(event2.nodes[0].children[1].children.length, 4);

      // Expect myfolder to have requests with the correct seq number
      final expectedFiles = ['two.bru', 'three.bru', 'four.bru', 'five.bru'];
      final myFolder = event2.nodes[0].children[1];
      for (var i = 0; i < expectedFiles.length; i++) {
        final node = myFolder.children[i];
        expect(node.name, expectedFiles[i]);
        expect(node.request?.seq, i);
      }

      await deleteFolder(newFolderPath);
    });
  });
}
