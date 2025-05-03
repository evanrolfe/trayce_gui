import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
      expect(event.nodes[0].children[0].name, 'hello');
      expect(event.nodes[0].children[1].name, 'myfolder');
      expect(event.nodes[0].children[2].name, 'my-request.bru');

      expect(event.nodes[0].children[1].children[0].name, 'a-req.bru');
      expect(event.nodes[0].children[1].children[1].name, 'another-req.bru');
      expect(event.nodes[0].children[1].children[2].name, 'get users.bru');
      expect(event.nodes[0].children[1].children[3].name, 'new-request.bru');
      expect(event.nodes[0].children[1].children[4].name, 'test-request.bru');
    });
  });
}
