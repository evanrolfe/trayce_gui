import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

class MockEventBus extends Mock implements EventBus {}

const collection1Path = 'test/support/collection1';
void main() {
  late ExplorerRepo explorerRepo;
  late MockEventBus mockEventBus;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
    explorerRepo = ExplorerRepo(eventBus: mockEventBus);
  });

  group('openCollection()', () {
    test('it loads collection1 successfully', () async {
      explorerRepo.openCollection(collection1Path);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;

      final event = captured[0] as EventDisplayExplorerItems;

      expect(event.nodes[0].name, 'collection1');
      expect(event.nodes[0].type, NodeType.collection);
      final collection = event.nodes[0].getCollection();
      expect(collection?.type, 'collection');
      final collectionAuth = collection?.auth as BasicAuth;
      expect(collectionAuth.username, 'asdf');
      expect(collectionAuth.password, 'asdf');
      expect(collection?.requestVars[0].name, 'xxx');
      expect(collection?.requestVars[0].value, 'yyy');

      expect(event.nodes[0].children[0].name, 'hello');
      expect(event.nodes[0].children[0].type, NodeType.folder);
      expect(event.nodes[0].children[1].name, 'myfolder');
      expect(event.nodes[0].children[1].type, NodeType.folder);
      expect(event.nodes[0].children[2].name, 'my-request.bru');
      expect(event.nodes[0].children[2].type, NodeType.request);
      Request? request = event.nodes[0].children[2].request;
      expect(request?.method, 'post');
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
      explorerRepo.openCollection(collection1Path);

      final seq = explorerRepo.getNextSeq('test/support/collection1/myfolder/');
      expect(seq, 6);
    });

    test('returns the next sequence number for a folder without a trailing slash', () async {
      explorerRepo.openCollection(collection1Path);

      final seq = explorerRepo.getNextSeq('test/support/collection1/myfolder');
      expect(seq, 6);
    });

    test('returns the next sequence number for collection root', () async {
      explorerRepo.openCollection(collection1Path);

      final seq = explorerRepo.getNextSeq(collection1Path);
      expect(seq, 1);
    });
  });
}
