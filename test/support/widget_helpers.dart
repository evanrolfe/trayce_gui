import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trayce/common/app_storage.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/environment_repo.dart';
import 'package:trayce/editor/repo/explorer_service.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/repo/global_environment_repo.dart';
import 'package:trayce/editor/repo/request_repo.dart';
import 'package:trayce/editor/repo/runtime_vars_repo.dart';
import 'package:trayce/editor/repo/send_request.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/repo/flow_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';

import 'fake_app_storage.dart';

class MockFilePicker extends Mock implements FilePickerI {}

class MockHttpClient extends Mock implements HttpClientI {}

class MockRequest extends Mock implements http.BaseRequest {}

class MockDuration extends Mock implements Duration {}

class WidgetDependencies {
  late Database db;
  late EventBus eventBus;
  late AppStorageI appStorage;
  late MockFilePicker filePicker;
  late MockHttpClient httpClient;
  late FlowRepo flowRepo;
  late ProtoDefRepo protoDefRepo;
  late ContainersRepo containersRepo;
  late CollectionRepo collectionRepo;
  late EnvironmentRepo environmentRepo;
  late GlobalEnvironmentRepo globalEnvironmentRepo;
  late FolderRepo folderRepo;
  late RequestRepo requestRepo;
  late ExplorerService explorerService;
  late ConfigRepo configRepo;
  late RuntimeVarsRepo runtimeVarsRepo;

  WidgetDependencies({
    required this.db,
    required this.eventBus,
    required this.appStorage,
    required this.filePicker,
    required this.httpClient,
    required this.flowRepo,
    required this.protoDefRepo,
    required this.containersRepo,
    required this.collectionRepo,
    required this.environmentRepo,
    required this.globalEnvironmentRepo,
    required this.folderRepo,
    required this.requestRepo,
    required this.explorerService,
    required this.configRepo,
    required this.runtimeVarsRepo,
  });

  // Creates a widget with all required providers
  Widget wrapWidget(Widget child) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
        RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
        RepositoryProvider<EventBus>(create: (context) => eventBus),
        RepositoryProvider<FilePickerI>(create: (context) => filePicker),
        RepositoryProvider<HttpClientI>(create: (context) => httpClient),
        RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
        RepositoryProvider<CollectionRepo>(create: (context) => collectionRepo),
        RepositoryProvider<EnvironmentRepo>(create: (context) => environmentRepo),
        RepositoryProvider<GlobalEnvironmentRepo>(create: (context) => globalEnvironmentRepo),
        RepositoryProvider<FolderRepo>(create: (context) => folderRepo),
        RepositoryProvider<RequestRepo>(create: (context) => requestRepo),
        RepositoryProvider<ExplorerService>(create: (context) => explorerService),
        RepositoryProvider<ConfigRepo>(create: (context) => configRepo),
        RepositoryProvider<RuntimeVarsRepo>(create: (context) => runtimeVarsRepo),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  MockFilePicker get mockFilePicker => filePicker;

  Future<void> close() async {
    await db.close();
  }
}

/// Sets up all required dependencies for tests
Future<WidgetDependencies> setupTestDependencies() async {
  final db = await connectMemoryDB();
  final eventBus = EventBus();
  final appStorage = FakeAppStorage();
  final filePicker = MockFilePicker();
  final httpClient = MockHttpClient();
  final configRepo = ConfigRepo(appStorage, [], Directory.current, Directory.current);
  final flowRepo = FlowRepo(db: db, eventBus: eventBus);
  final protoDefRepo = ProtoDefRepo(db: db);
  final containersRepo = ContainersRepo(eventBus: eventBus);
  final collectionRepo = CollectionRepo(appStorage);
  final environmentRepo = EnvironmentRepo(appStorage);
  final globalEnvironmentRepo = GlobalEnvironmentRepo(appStorage);
  final folderRepo = FolderRepo();
  final requestRepo = RequestRepo();
  final runtimeVarsRepo = RuntimeVarsRepo(eventBus: eventBus);
  registerFallbackValue(MockRequest());
  registerFallbackValue(MockDuration());

  final explorerService = ExplorerService(
    eventBus: eventBus,
    collectionRepo: collectionRepo,
    folderRepo: folderRepo,
    requestRepo: requestRepo,
  );

  final deps = WidgetDependencies(
    db: db,
    eventBus: eventBus,
    appStorage: appStorage,
    filePicker: filePicker,
    httpClient: httpClient,
    flowRepo: flowRepo,
    protoDefRepo: protoDefRepo,
    containersRepo: containersRepo,
    collectionRepo: collectionRepo,
    environmentRepo: environmentRepo,
    globalEnvironmentRepo: globalEnvironmentRepo,
    folderRepo: folderRepo,
    requestRepo: requestRepo,
    explorerService: explorerService,
    configRepo: configRepo,
    runtimeVarsRepo: runtimeVarsRepo,
  );

  return deps;
}
