/*
// Commented out for now, need to make the tests start a server and then make the app use that
// server for verification rather than the real thing.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/agent/gen/api.pb.dart' as pb;
import 'package:trayce/agent/gen/api.pbgrpc.dart';

Future<void> test(WidgetTester tester, Database db) async {
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

  // Open command stream and receive the commands sent to it
  final agentStarted = pb.AgentStarted(version: '1.0.0');
  final controller = StreamController<pb.AgentStarted>();
  final commandStream = client.openCommandStream(controller.stream);
  final commandsReceived = <pb.Command>[];
  final subscription = commandStream.listen((command) {
    commandsReceived.add(command);
  });
  controller.add(agentStarted);

  // Find and click the File menu
  final fileMenu = find.text('File');
  await tester.tap(fileMenu);
  await tester.pumpAndSettle();

  // Find and click the Settings menu item
  final settingsMenuItem = find.text('Settings');
  await tester.tap(settingsMenuItem);
  await tester.pumpAndSettle();

  // Find the license key text field by key and enter "test"
  final textField = find.byKey(const Key('license-key-input'));
  await tester.enterText(textField, 'test');
  await tester.pumpAndSettle();

  // Find and click the Verify button
  final verifyButton = find.text('Verify');
  await tester.tap(verifyButton);
  print('Tapped verify button');

  // Verify the command was sent to verify the license key
  await Future.delayed(const Duration(milliseconds: 250));
  expect(commandsReceived.length, 1);
  final cmd = commandsReceived[0];
  expect(cmd.type, 'set_settings');
  expect(cmd.settings.licenseKey, 'test');
  commandsReceived.clear();

  // The license key is valid
  await client.sendAgentVerified(pb.AgentVerified(valid: true));
  print('Sent agent verified');
  await tester.pumpAndSettle();

  expect(find.textContaining('valid'), findsOne);
  await Future.delayed(const Duration(seconds: 3));

  // Click the Save button
  final saveButton = find.text('Save');
  await tester.tap(saveButton);
  await tester.pumpAndSettle();

  // Find and click the File menu
  await tester.tap(fileMenu);
  await tester.pumpAndSettle();

  // Find and click the Settings menu item
  await tester.tap(settingsMenuItem);
  await tester.pumpAndSettle();

  // Find the license key text field by key and enter "test"
  final textField2 = find.byKey(const Key('license-key-input'));
  expect((tester.widget(textField2) as TextField).controller?.text, 'test');

  // Now disconnect the agent
  await subscription.cancel();
  await controller.close();
  await channel.shutdown();
}
*/
