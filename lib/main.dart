import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grpc/grpc.dart';
import 'package:trayce/app.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:trayce/utils/grpc_parser_lib.dart';
import 'package:window_manager/window_manager.dart';

import 'agent/server.dart';
import 'network/repo/containers_repo.dart';
import 'network/repo/flow_repo.dart';

const String appVersion = '1.3.0';

void main(List<String> args) async {
  // Check for --version flag
  if (args.contains('--version')) {
    stdout.writeln('trayce v$appVersion');
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await GrpcParserLib.ensureExists();

  // Connect DB, EventBus & GRPC server
  EventBus eventBus = EventBus();
  final db = await connectDB();
  final grpcService = TrayceAgentService(eventBus: eventBus);
  final config = Config.fromArgs(args);

  // Init repos
  final flowRepo = FlowRepo(db: db, eventBus: eventBus);
  final protoDefRepo = ProtoDefRepo(db: db);
  final containersRepo = ContainersRepo(eventBus: eventBus);
  final explorerRepo = ExplorerRepo(eventBus: eventBus);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
        RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
        RepositoryProvider<EventBus>(create: (context) => eventBus),
        RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
        RepositoryProvider<ExplorerRepo>(create: (context) => explorerRepo),
        RepositoryProvider<Config>(create: (context) => config),
      ],
      child: const App(appVersion: appVersion),
    ),
  );

  // Start the gRPC server
  final server = Server.create(services: [grpcService]);
  await server.serve(address: InternetAddress.anyIPv4, port: 50051, shared: true);
  print('Server listening on port 50051');
}
