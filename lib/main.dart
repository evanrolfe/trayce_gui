import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trayce/app.dart';
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:trayce/utils/grpc_parser_lib.dart';
import 'package:window_manager/window_manager.dart';

import 'agent/server.dart';
import 'network/repo/containers_repo.dart';
import 'network/repo/flow_repo.dart';

const String appVersion = '1.6.0';

void main(List<String> args) async {
  // Check for --version flag
  if (args.contains('--version')) {
    stdout.writeln('trayce v$appVersion');
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await GrpcParserLib.ensureExists();
  final appSupportDir = await getApplicationSupportDirectory();

  // Core dependencies
  final eventBus = EventBus();
  final db = await connectDB();
  final grpcService = TrayceAgentService(eventBus: eventBus);
  final appStorage = await AppStorage.getInstance();
  final filePicker = FilePicker();

  // Repos
  final configRepo = ConfigRepo(appStorage, args, appSupportDir);
  final flowRepo = FlowRepo(db: db, eventBus: eventBus);
  final protoDefRepo = ProtoDefRepo(db: db);
  final containersRepo = ContainersRepo(eventBus: eventBus);
  final collectionRepo = CollectionRepo(appStorage);
  final folderRepo = FolderRepo();
  final requestRepo = RequestRepo();

  // Services
  final explorerService = ExplorerService(
    eventBus: eventBus,
    collectionRepo: collectionRepo,
    folderRepo: folderRepo,
    requestRepo: requestRepo,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ConfigRepo>(create: (context) => configRepo),
        RepositoryProvider<FilePickerI>(create: (context) => filePicker),
        RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
        RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
        RepositoryProvider<EventBus>(create: (context) => eventBus),
        RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
        RepositoryProvider<CollectionRepo>(create: (context) => collectionRepo),
        RepositoryProvider<FolderRepo>(create: (context) => folderRepo),
        RepositoryProvider<RequestRepo>(create: (context) => requestRepo),
        RepositoryProvider<ExplorerService>(create: (context) => explorerService),
      ],
      child: const App(appVersion: appVersion),
    ),
  );

  // Start the gRPC server
  final server = Server.create(services: [grpcService]);
  await server.serve(address: InternetAddress.anyIPv4, port: 50051, shared: true);
  print('Server listening on port 50051');
}
