import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/agent/gen/api.pb.dart' as pb;
import 'package:trayce/agent/gen/api.pbgrpc.dart';
import 'package:uuid/uuid.dart';

import 'const.dart';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('network-sidebar-btn'));
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // Create the GRPC client
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(), // Use this for non-TLS connections
    ),
  );
  final client = TrayceAgentClient(channel);

  // Send flows observed
  final flows = buildFlows();
  try {
    final response = await client.sendFlowsObserved(pb.Flows(flows: flows));
    print('Response received: $response');
  } catch (e) {
    print('Error: $e');
  }
  await tester.pumpAndSettle();

  // Verify the flow appears in the table
  expect(find.text('http'), findsNWidgets(2));
  expect(find.text('10.0.0.1'), findsOneWidget);
  expect(find.text('10.0.0.2'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 1st row
  // --------------------------------------------------------------------------
  final flowRow = find.text('10.0.0.1').first;
  await tester.tap(flowRow);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('POST / HTTP/1.1'), findsOneWidget);
  expect(find.textContaining('user-agent: trayce,app'), findsOneWidget);
  expect(find.textContaining('content-type: application/html'), findsOneWidget);
  expect(find.textContaining('hello world'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 2nd row
  // --------------------------------------------------------------------------
  final flowRow2 = find.text('20.0.0.2').first;
  await tester.tap(flowRow2);
  await tester.pumpAndSettle();

  // Verify the request text
  expect(find.textContaining('PUT /hello HTTP/1.1'), findsOneWidget);
  expect(find.textContaining('user-agent: trayce,app'), findsOneWidget);
  expect(find.textContaining('content-type: application/html'), findsOneWidget);
  expect(find.textContaining('hello world'), findsOneWidget);

  // Verify the response text
  expect(find.textContaining('HTTP/1.1 200 OK'), findsOneWidget);
  expect(find.textContaining('testheader: ok'), findsOneWidget);
  expect(find.textContaining('hi'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 3rd row
  // --------------------------------------------------------------------------
  final flowRow3 = find.text('30.0.0.1').first;
  await tester.tap(flowRow3);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('GRPC /api.TrayceAgent/SendContainersObserved'), findsOneWidget);
  expect(find.textContaining('content-type: application/grpc'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 4th row
  // --------------------------------------------------------------------------
  final flowRow4 = find.text('40.0.0.1').first;
  await tester.tap(flowRow4);
  await tester.pumpAndSettle();
  // await Future.delayed(const Duration(seconds: 5));

  // Verify the request text appears in the top pane
  expect(find.textContaining('GRPC /api.TrayceAgent/SendContainersObserved'), findsOneWidget);
  expect(find.textContaining('content-type: application/grpc'), findsOneWidget);

  expect(find.textContaining('testheader: ok'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 5th row
  // --------------------------------------------------------------------------
  final flowRow5 = find.text('50.0.0.1').first;
  await tester.tap(flowRow5);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('SELECT * FROM users WHERE id = ?'), findsOneWidget);
  expect(find.textContaining('123'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 6th row
  // --------------------------------------------------------------------------
  final flowRow6 = find.text('60.0.0.1').first;
  await tester.tap(flowRow6);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('SELECT * FROM users'), findsOneWidget);
  expect(find.textContaining('alice@example.com'), findsOneWidget);
  expect(find.textContaining('bob@example.com'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 7th row
  // --------------------------------------------------------------------------
  final flowRow7 = find.text('70.0.0.1').first;
  await tester.tap(flowRow7);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('SELECT * FROM things WHERE id = ?'), findsOneWidget);
  expect(find.textContaining('123'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 8th row
  // --------------------------------------------------------------------------
  final flowRow8 = find.text('80.0.0.1').first;
  await tester.tap(flowRow8);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('SELECT * FROM things'), findsOneWidget);
  expect(find.textContaining('widget'), findsOneWidget);
  expect(find.textContaining('doodah'), findsOneWidget);
  expect(find.textContaining('gadget'), findsOneWidget);
  // --------------------------------------------------------------------------
  // Search
  // --------------------------------------------------------------------------
  // Find and enter "http" in the search field
  final searchField = find.byKey(const Key('flow_table_search_input'));
  await tester.enterText(searchField, 'http');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Verify only HTTP flows are shown
  expect(find.text('10.0.0.1'), findsOneWidget);
  expect(find.text('20.0.0.1'), findsOneWidget);
  expect(find.text('30.0.0.1'), findsNothing);
  expect(find.text('40.0.0.1'), findsNothing);

  // Search for "POST"
  await tester.tap(searchField);
  await tester.pumpAndSettle();
  await tester.enterText(searchField, 'POST');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Verify only POST flows are shown
  expect(find.text('10.0.0.1'), findsOneWidget);
  expect(find.text('20.0.0.1'), findsNothing);
  expect(find.text('30.0.0.1'), findsNothing);
  expect(find.text('40.0.0.1'), findsNothing);
}

List<pb.Flow> buildFlows() {
  final uuid2 = Uuid().v4();
  final uuid4 = Uuid().v4();
  final uuid6 = Uuid().v4();
  final uuid8 = Uuid().v4();

  return [
    //
    // Flow 1
    //
    pb.Flow(
      uuid: Uuid().v4(),
      sourceAddr: '10.0.0.1',
      destAddr: '10.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'http',
      httpRequest: pb.HTTPRequest(
        method: 'POST',
        host: '10.0.0.1',
        path: '/',
        httpVersion: '1.1',
        headers: {
          "user-agent": pb.StringList(values: ["trayce", "app"]),
          "content-type": pb.StringList(values: ["application/html"]),
        },
        payload: [0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64], // "hello world"
      ),
    ),
    pb.Flow(
      uuid: uuid2,
      sourceAddr: '20.0.0.1',
      destAddr: '20.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'http',
      httpRequest: pb.HTTPRequest(
        method: 'PUT',
        host: '20.0.0.2',
        path: '/hello',
        httpVersion: '1.1',
        headers: {
          "user-agent": pb.StringList(values: ["trayce", "app"]),
          "content-type": pb.StringList(values: ["application/html"]),
        },
        payload: [0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64], // "hello world"
      ),
    ),
    //
    // Flow 2
    //
    pb.Flow(
      uuid: uuid2,
      sourceAddr: '20.0.0.1',
      destAddr: '20.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'http',
      httpResponse: pb.HTTPResponse(
        status: 200,
        statusMsg: 'OK',
        httpVersion: '1.1',
        headers: {
          "testheader": pb.StringList(values: ["ok"]),
        },
        payload: [0x68, 0x69], // "hi"
      ),
    ),
    //
    // Flow 3 (GRPC Request)
    //
    pb.Flow(
      uuid: Uuid().v4(),
      sourceAddr: '30.0.0.1',
      destAddr: '30.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'grpc',
      grpcRequest: pb.GRPCRequest(
        path: '/api.TrayceAgent/SendContainersObserved',
        headers: {
          "content-type": pb.StringList(values: ["application/grpc"]),
        },
        payload: grpcReqPayload,
      ),
    ), //
    //
    // Flow 4 (GRPC Request)
    //
    pb.Flow(
      uuid: uuid4,
      sourceAddr: '40.0.0.1',
      destAddr: '40.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'grpc',
      grpcRequest: pb.GRPCRequest(
        path: '/api.TrayceAgent/SendContainersObserved',
        headers: {
          "content-type": pb.StringList(values: ["application/grpc"]),
        },
        payload: grpcReqPayload,
      ),
    ),
    //
    // Flow 4 (GRPC Response)
    //
    pb.Flow(
      uuid: uuid4,
      sourceAddr: '40.0.0.1',
      destAddr: '40.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'grpc',
      grpcResponse: pb.GRPCResponse(
        headers: {
          "testheader": pb.StringList(values: ["ok"]),
        },
        payload: grpcRespPayload,
      ),
    ),

    // Flow 5 (MySQL Query)
    pb.Flow(
      uuid: Uuid().v4(),
      sourceAddr: '50.0.0.1',
      destAddr: '50.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'mysql',
      sqlQuery: pb.SQLQuery(query: 'SELECT * FROM users WHERE id = ?', params: pb.StringList(values: ["123"])),
    ),
    // Flow 6 (MySQL Query)
    pb.Flow(
      uuid: uuid6,
      sourceAddr: '60.0.0.1',
      destAddr: '60.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'mysql',
      sqlQuery: pb.SQLQuery(query: 'SELECT * FROM users', params: pb.StringList(values: [])),
    ),

    // Flow 6 (MySQL Response)
    pb.Flow(
      uuid: uuid6,
      sourceAddr: '60.0.0.1',
      destAddr: '60.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'mysql',
      sqlResponse: pb.SQLResponse(
        columns: pb.StringList(values: ["id", "name", "email"]),
        rows: List<StringList>.from([
          StringList(values: ['1', 'alice', 'alice@example.com']),
          StringList(values: ['2', 'bob', 'bob@example.com']),
        ]),
      ),
    ),
    // Flow 7 (Postgres Query)
    pb.Flow(
      uuid: Uuid().v4(),
      sourceAddr: '70.0.0.1',
      destAddr: '70.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'psql',
      sqlQuery: pb.SQLQuery(query: 'SELECT * FROM things WHERE id = ?', params: pb.StringList(values: ["123"])),
    ),
    // Flow 8 (Postgres Query)
    pb.Flow(
      uuid: uuid8,
      sourceAddr: '80.0.0.1',
      destAddr: '80.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'psql',
      sqlQuery: pb.SQLQuery(query: 'SELECT * FROM things', params: pb.StringList(values: [])),
    ),

    // Flow 8 (Postgres Response)
    pb.Flow(
      uuid: uuid8,
      sourceAddr: '80.0.0.1',
      destAddr: '80.0.0.2',
      l4Protocol: 'tcp',
      l7Protocol: 'psql',
      sqlResponse: pb.SQLResponse(
        columns: pb.StringList(values: ["id", "name"]),
        rows: List<StringList>.from([
          StringList(values: ['1', 'widget']),
          StringList(values: ['2', 'doodah']),
          StringList(values: ['3', 'gadget']),
        ]),
      ),
    ),
  ];
}
