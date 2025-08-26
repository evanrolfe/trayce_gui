import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/agent/gen/api.pb.dart' as pb;
import 'package:trayce/agent/gen/api.pbgrpc.dart';

// https://github.com/flutter/flutter/issues/135673
Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // Find and click the Network tab
  final networkTab = find.byKey(const Key('network-sidebar-btn'));
  expect(networkTab, findsOneWidget); // Add verification that icon exists
  await tester.tap(networkTab);
  await tester.pumpAndSettle();

  // Find and click the Containers button
  final containersButton = find.text('Containers');
  await tester.tap(containersButton);
  await tester.pumpAndSettle();

  // Verify the modal is shown
  expect(find.textContaining('Trayce Agent is not running!'), findsOneWidget);
  expect(find.textContaining('docker run'), findsOneWidget);

  // Create the GRPC client
  final channel = ClientChannel(
    'localhost',
    port: 50052,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(), // Use this for non-TLS connections
    ),
  );
  final client = TrayceAgentClient(channel);

  // Open command stream and receive the commands sent to it
  final agentStarted = pb.AgentStarted(version: '1.0.5');
  final controller = StreamController<pb.AgentStarted>();
  final commandStream = client.openCommandStream(controller.stream);
  final commandsReceived = <pb.Command>[];
  final subscription = commandStream.listen((command) {
    commandsReceived.add(command);
  });
  controller.add(agentStarted);

  // Send containers observed
  final containers = [
    pb.Container(id: 'a2db0b', name: 'hello', ip: "127.0.0.1", image: 'image1', status: 'running'),
    pb.Container(id: 'a3db0b', name: 'world', ip: "127.0.0.2", image: 'image1', status: 'running'),
  ];
  await client.sendContainersObserved(pb.Containers(containers: containers));
  await tester.pumpAndSettle();

  // Verify the modal is shown
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('world'), findsOneWidget);

  // Find and click the checkbox for container a3db0b
  final containerRow = find.text('a3db0b');
  final checkbox =
      find
          .descendant(of: find.ancestor(of: containerRow, matching: find.byType(Row)), matching: find.byType(Checkbox))
          .first;
  await tester.tap(checkbox);
  await tester.pumpAndSettle();

  // Click save button
  expect(find.text('Save'), findsOneWidget);
  final saveButton = find.text('Save');
  await tester.tap(saveButton);
  await tester.pumpAndSettle();

  // Verify the command was sent to intercept the container selected
  expect(commandsReceived.length, 2);
  final cmd0 = commandsReceived[0];
  final cmd1 = commandsReceived[1];
  commandsReceived.clear();

  // It first sends an empty set of container IDs when the agent is first connected
  expect(cmd0.type, 'set_settings');
  expect(cmd0.settings.containerIds, []);

  // It then sends the selected container IDs when save is clicked
  commandsReceived.clear();
  expect(cmd1.type, 'set_settings');
  expect(cmd1.settings.containerIds, ['a3db0b']);

  // Now disconnect the agent
  await subscription.cancel();
  await controller.close();
  await channel.shutdown();

  await tester.pumpAndSettle(const Duration(seconds: 1));
  // Find and click the Containers button
  await tester.tap(containersButton);
  await tester.pumpAndSettle();

  // Verify the "Trayce Agent is not running!" message is shown
  expect(find.textContaining('Trayce Agent is not running!'), findsOneWidget);
  expect(find.textContaining('docker run'), findsOneWidget);

  // Re-Open command stream and receive the commands sent to it
  final channel2 = ClientChannel(
    'localhost',
    port: 50052,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(), // Use this for non-TLS connections
    ),
  );
  final client2 = TrayceAgentClient(channel2);

  final agentStarted2 = pb.AgentStarted(version: '1.0.5');
  final controller2 = StreamController<pb.AgentStarted>();
  final commandStream2 = client2.openCommandStream(controller2.stream);
  final commandsReceived2 = <pb.Command>[];
  final subscription2 = commandStream2.listen((command) {
    commandsReceived2.add(command);
  });
  controller2.add(agentStarted2);

  // Send containers observed
  await client2.sendContainersObserved(pb.Containers(containers: containers));
  await tester.pumpAndSettle();

  // Verify the modal is shown
  expect(find.text('hello'), findsOneWidget);
  expect(find.text('world'), findsOneWidget);

  // Verify the command was sent to intercept the container selected
  expect(commandsReceived2.length, 1);
  final cmd = commandsReceived2[0];
  commandsReceived2.clear();

  // It then sends the selected container IDs when save is clicked
  expect(cmd.type, 'set_settings');
  expect(cmd.settings.containerIds, ['a3db0b']);

  // Verify the checkbox for container a3db0b is checked
  final containerRow2 = find.text('a3db0b');
  final checkbox2 =
      find
          .descendant(of: find.ancestor(of: containerRow2, matching: find.byType(Row)), matching: find.byType(Checkbox))
          .first;
  expect(checkbox2, findsOneWidget);
  expect(tester.widget<Checkbox>(checkbox2).value, true);

  // Now disconnect the agent
  await subscription2.cancel();
  await controller2.close();
  await channel2.shutdown();
}
