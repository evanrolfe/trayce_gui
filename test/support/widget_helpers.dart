import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/repo/flow_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';

import 'fake_app_storage.dart';

class WidgetDependencies {
  late Database db;
  late EventBus eventBus;
  late AppStorageI appStorage;
  late FlowRepo flowRepo;
  late ProtoDefRepo protoDefRepo;
  late ContainersRepo containersRepo;
  late CollectionRepo collectionRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late ExplorerService explorerService;
  late Config config;

  WidgetDependencies({
    required this.db,
    required this.eventBus,
    required this.appStorage,
    required this.flowRepo,
    required this.protoDefRepo,
    required this.containersRepo,
    required this.collectionRepo,
    required this.folderRepo,
    required this.requestRepo,
    required this.explorerService,
    required this.config,
  });

  // Creates a widget with all required providers
  Widget wrapWidget(Widget child) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
        RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
        RepositoryProvider<EventBus>(create: (context) => eventBus),
        RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
        RepositoryProvider<CollectionRepo>(create: (context) => collectionRepo),
        RepositoryProvider<FolderRepo>(create: (context) => folderRepo),
        RepositoryProvider<RequestRepo>(create: (context) => requestRepo),
        RepositoryProvider<ExplorerService>(create: (context) => explorerService),
        RepositoryProvider<Config>(create: (context) => config),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  Future<void> close() async {
    await db.close();
  }
}

/// Sets up all required dependencies for tests
Future<WidgetDependencies> setupTestDependencies() async {
  final db = await connectMemoryDB();
  final eventBus = EventBus();
  final appStorage = await FakeAppStorage.getInstance();

  final flowRepo = FlowRepo(db: db, eventBus: eventBus);
  final protoDefRepo = ProtoDefRepo(db: db);
  final containersRepo = ContainersRepo(eventBus: eventBus);
  final collectionRepo = CollectionRepo(appStorage);
  final folderRepo = FolderRepo();
  final requestRepo = RequestRepo();

  final explorerService = ExplorerService(
    eventBus: eventBus,
    collectionRepo: collectionRepo,
    folderRepo: folderRepo,
    requestRepo: requestRepo,
  );
  final config = Config.fromArgs(['--test']);

  final deps = WidgetDependencies(
    db: db,
    eventBus: eventBus,
    appStorage: appStorage,
    flowRepo: flowRepo,
    protoDefRepo: protoDefRepo,
    containersRepo: containersRepo,
    collectionRepo: collectionRepo,
    folderRepo: folderRepo,
    requestRepo: requestRepo,
    explorerService: explorerService,
    config: config,
  );

  return deps;
}
