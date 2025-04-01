import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/agent/gen/api.pb.dart' as pb;
import 'package:trayce/agent/gen/api.pbgrpc.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:uuid/uuid.dart';

import 'const.dart';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // Create ProtoDef because the integration test isn't able to interact with the native file browser
  final protoDefRepo = ProtoDefRepo(db: db);
  final protoPath = 'lib/agent/api.proto';
  await protoDefRepo.upload('api.proto', protoPath);

  // Find and click the Network tab
  final networkTab = find.byIcon(Icons.format_list_numbered);
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
  expect(find.text('grpc'), findsNWidgets(2));
  expect(find.text('30.0.0.1'), findsOneWidget);
  expect(find.text('40.0.0.1'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 1st row
  // --------------------------------------------------------------------------
  final flowRow3 = find.text('30.0.0.1').first;
  await tester.tap(flowRow3);
  await tester.pumpAndSettle();

  // Verify the request text appears in the top pane
  expect(find.textContaining('GRPC /api.TrayceAgent/SendContainersObserved'), findsOneWidget);
  expect(find.textContaining('content-type: application/grpc'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Select the ProtoDef
  // --------------------------------------------------------------------------
  final dropdown = find.byType(DropdownButton2<String>);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final protoDefOption = find.text('api.proto').last;
  await tester.tap(protoDefOption);
  await tester.pumpAndSettle();

  expect(find.textContaining('"containers": ['), findsOneWidget);
  expect(find.textContaining('"id": "1234",'), findsOneWidget);
  expect(find.textContaining('"image": "ubuntu",'), findsOneWidget);
  expect(find.textContaining('"ip": "172.0.1.19",'), findsOneWidget);
  expect(find.textContaining('"name": "HELLOWORLD!!!",'), findsOneWidget);
  expect(find.textContaining('"status": "running"'), findsOneWidget);

  // --------------------------------------------------------------------------
  // Click on the 2nd row
  // --------------------------------------------------------------------------
  final flowRow4 = find.text('40.0.0.1').first;
  await tester.tap(flowRow4);
  await tester.pumpAndSettle();
  // await Future.delayed(const Duration(seconds: 5));

  // Verify the request text appears in the top pane
  expect(find.textContaining('GRPC /api.TrayceAgent/SendContainersObserved'), findsOneWidget);
  expect(find.textContaining('content-type: application/grpc'), findsOneWidget);

  expect(find.textContaining('testheader: ok'), findsOneWidget);

  expect(find.textContaining('"containers": ['), findsOneWidget);
  expect(find.textContaining('"id": "1234",'), findsOneWidget);
  expect(find.textContaining('"image": "ubuntu",'), findsOneWidget);
  expect(find.textContaining('"ip": "172.0.1.19",'), findsOneWidget);
  expect(find.textContaining('"name": "HELLOWORLD!!!",'), findsOneWidget);
  expect(find.textContaining('"status": "running"'), findsOneWidget);

  expect(find.textContaining('"status": "success "'), findsOneWidget);
}

List<pb.Flow> buildFlows() {
  final uuid4 = Uuid().v4();

  return [
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
          "content-type": pb.StringList(values: ["application/grpc"])
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
          "content-type": pb.StringList(values: ["application/grpc"])
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
          "testheader": pb.StringList(values: ["ok"])
        },
        payload: grpcRespPayload,
      ),
    ),
  ];
}
