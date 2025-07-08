import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';

class MockEventBus extends Mock implements EventBus {}

const collection1Path = 'test/support/collection1';
void main() {
  late MockEventBus mockEventBus;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEventBus = MockEventBus();
  });

  group('SendRequest()', () {
    test('sends a request using the node hierarchy', () async {
      final explorerRepo = ExplorerRepo(eventBus: mockEventBus);
      explorerRepo.openCollection(collection1Path);
      final captured = verify(() => mockEventBus.fire(captureAny())).captured;
      final event = captured[0] as EventDisplayExplorerItems;

      final reqThree = event.nodes[0].children[1].children[2];
      expect(reqThree.name, 'three.bru');

      final hierarchy = explorerRepo.getNodeHierarchy(reqThree);
      expect(hierarchy.length, 3);
      expect(hierarchy[0].name, 'three.bru');
      expect(hierarchy[1].name, 'myfolder');
      expect(hierarchy[2].name, 'collection1');

      final finalReq = SendRequest(request: reqThree.request!, nodeHierarchy: hierarchy).getFinalRequest();

      // Verify the headers
      expect(finalReq.headers.length, 5);
      expect(finalReq.headers[0].name, 'D');
      expect(finalReq.headers[0].value, "set from collection");
      expect(finalReq.headers[1].name, 'changed-by-test');
      expect(finalReq.headers[1].value, "changed-by-test");
      expect(finalReq.headers[2].name, 'C');
      expect(finalReq.headers[2].value, 'set from folder');
      expect(finalReq.headers[3].name, 'A');
      expect(finalReq.headers[3].value, 'set from request');

      // Verify the variables
      print('finalReq.requestVars:');
      for (final reqvar in finalReq.requestVars) {
        print('  ${reqvar.name}: ${reqvar.value}');
      }

      expect(finalReq.requestVars.length, 3);
      expect(finalReq.requestVars[0].name, 'C_var');
      expect(finalReq.requestVars[0].value, 'set from collection');
      expect(finalReq.requestVars[1].name, 'B_var');
      expect(finalReq.requestVars[1].value, 'set from folder');
      expect(finalReq.requestVars[2].name, 'A_var');
      expect(finalReq.requestVars[2].value, 'set from request');
    });
  });
}
