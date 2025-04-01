import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/network/models/http_request.dart';
import 'package:trayce/network/models/http_response.dart';
import 'package:trayce/network/repo/flow_repo.dart';

import '../../support/database.dart';
import '../../support/flow_factory.dart';

void main() {
  late TestDatabase testDb;
  late FlowRepo flowRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDb = await TestDatabase.instance;
    flowRepo = FlowRepo(db: testDb.db, eventBus: EventBus());
  });

  tearDownAll(() async {});

  tearDown(() => testDb.truncate());

  group('FlowRepo', () {
    group('save()', () {
      test('it saves a flow to the database', () async {
        // Create and save a flow
        final flow = buildHttpReqFlow();
        final savedFlow = await flowRepo.save(flow);

        // Query the database directly to verify
        final List<Map<String, dynamic>> results = await testDb.db.query(
          'flows',
          where: 'id = ?',
          whereArgs: [savedFlow.id],
        );

        expect(results.length, 1);

        final dbFlow = results.first;
        expect(dbFlow['uuid'], flow.uuid);
        expect(dbFlow['source'], flow.source);
        expect(dbFlow['dest'], flow.dest);
        expect(dbFlow['l4_protocol'], flow.l4Protocol);
        expect(dbFlow['protocol'], flow.l7Protocol);
        expect(dbFlow['operation'], flow.operation);
        expect(dbFlow['status'], flow.status);
        expect(dbFlow['request_raw'], flow.requestRaw);
        expect(dbFlow['response_raw'], flow.responseRaw);
        expect(dbFlow['created_at'], flow.createdAt.toIso8601String());
      });

      test('it updates the request flow with a response', () async {
        // Create and save a flow
        final flow1 = buildHttpReqFlow(uuid: "test-1234");
        final savedFlow = await flowRepo.save(flow1);

        // Create and save a response flow
        final flow2 = buildHttpRespFlow(uuid: "test-1234");
        await flowRepo.save(flow2);

        // Query the database directly to verify
        final List<Map<String, dynamic>> results = await testDb.db.query(
          'flows',
          where: 'id = ?',
          whereArgs: [savedFlow.id],
        );

        expect(results.length, 1);

        final dbFlow = results.first;
        expect(dbFlow['uuid'], flow1.uuid);
        expect(dbFlow['source'], flow1.source);
        expect(dbFlow['dest'], flow1.dest);
        expect(dbFlow['l4_protocol'], flow1.l4Protocol);
        expect(dbFlow['protocol'], flow1.l7Protocol);
        expect(dbFlow['operation'], flow1.operation);
        expect(dbFlow['status'], flow2.status);
        expect(dbFlow['request_raw'], flow1.requestRaw);
        expect(dbFlow['response_raw'], flow2.responseRaw);
        expect(dbFlow['created_at'], flow1.createdAt.toIso8601String());
      });
    });

    group('getFlows()', () {
      test('it returns a single HTTP request flow', () async {
        // Save a test flow
        final flow = buildHttpReqFlow();
        final savedFlow = await flowRepo.save(flow);

        // Get all flows
        final flows = await flowRepo.getFlows();
        final flowReq = flows.first.request as HttpRequest;

        expect(flows.length, 1);
        expect(flows.first.id, savedFlow.id);
        expect(flows.first.uuid, flow.uuid);
        expect(flows.first.source, flow.source);
        expect(flows.first.dest, flow.dest);
        expect(flows.first.l4Protocol, flow.l4Protocol);
        expect(flows.first.l7Protocol, flow.l7Protocol);
        expect(flows.first.requestRaw, flow.requestRaw);
        expect(flows.first.responseRaw, flow.responseRaw);
        expect(flows.first.createdAt.toIso8601String(), flow.createdAt.toIso8601String());

        expect(flowReq.method, 'GET');
        expect(flowReq.host, '172.17.0.3');
        expect(flowReq.path, '/');
        expect(flowReq.httpVersion, 'HTTP/1.1');
        expect(flowReq.headers, {});
        expect(flowReq.body, '');
      });

      test('it returns a single HTTP request+response flow', () async {
        // Save a test flow
        final flow1 = buildHttpReqFlow(uuid: "test-1234");
        final savedFlow = await flowRepo.save(flow1);

        final flow2 = buildHttpRespFlow(uuid: "test-1234");
        await flowRepo.save(flow2);

        // Get all flows
        final flows = await flowRepo.getFlows();
        final flowReq = flows.first.request as HttpRequest;
        final flowResp = flows.first.response as HttpResponse;

        expect(flows.length, 1);
        expect(flows.first.id, savedFlow.id);
        expect(flows.first.uuid, flow1.uuid);
        expect(flows.first.source, flow1.source);
        expect(flows.first.dest, flow1.dest);
        expect(flows.first.l4Protocol, flow1.l4Protocol);
        expect(flows.first.l7Protocol, flow1.l7Protocol);
        expect(flows.first.requestRaw, flow1.requestRaw);
        expect(flows.first.responseRaw, flow2.responseRaw);
        expect(flows.first.createdAt.toIso8601String(), flow1.createdAt.toIso8601String());

        expect(flowReq.method, 'GET');
        expect(flowReq.host, '172.17.0.3');
        expect(flowReq.path, '/');
        expect(flowReq.httpVersion, 'HTTP/1.1');
        expect(flowReq.headers, {});
        expect(flowReq.body, '');

        expect(flowResp.httpVersion, 'HTTP/1.1');
        expect(flowResp.status, 200);
        expect(flowResp.statusMsg, 'OK');
        expect(flowResp.headers, {});
        expect(flowResp.body, 'Hello World!');
      });

      test('it returns flows matching the search term', () async {
        // Save test flows with different operations
        final flow1 = buildHttpReqFlow(
            uuid: "test-1",
            request: HttpRequest(
              method: 'GET',
              host: '172.17.0.3',
              path: '/users',
              httpVersion: 'HTTP/1.1',
              headers: {},
              body: '',
            ));
        await flowRepo.save(flow1);

        final flow2 = buildHttpReqFlow(
            uuid: "test-2",
            request: HttpRequest(
              method: 'POST',
              host: '172.17.0.3',
              path: '/posts',
              httpVersion: 'HTTP/1.1',
              headers: {},
              body: '',
            ));
        await flowRepo.save(flow2);

        // Search for flows with 'users' in the operation
        final flows = await flowRepo.getFlows('/users');
        expect(flows.length, 1);
        expect(flows.first.operation, 'GET /users');

        // Search for flows with 'POST' in the operation
        final postFlows = await flowRepo.getFlows('POST');
        expect(postFlows.length, 1);
        expect(postFlows.first.operation, 'POST /posts');

        // Search for non-existent term
        final noFlows = await flowRepo.getFlows('nonexistent');
        expect(noFlows.length, 0);
      });
    });
  });
}
