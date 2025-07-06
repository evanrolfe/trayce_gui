import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/repo/flow_repo.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';

class WidgetDependencies {
  late Database db;
  late EventBus eventBus;
  late FlowRepo flowRepo;
  late ProtoDefRepo protoDefRepo;
  late ContainersRepo containersRepo;
  late ExplorerRepo explorerRepo;
  late Config config;

  WidgetDependencies({
    required this.db,
    required this.eventBus,
    required this.flowRepo,
    required this.protoDefRepo,
    required this.containersRepo,
    required this.explorerRepo,
    required this.config,
  });

  // Creates a widget with all required providers
  Future<Widget> wrapWidget(Widget child) async {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FlowRepo>(create: (context) => flowRepo),
        RepositoryProvider<ProtoDefRepo>(create: (context) => protoDefRepo),
        RepositoryProvider<EventBus>(create: (context) => eventBus),
        RepositoryProvider<ContainersRepo>(create: (context) => containersRepo),
        RepositoryProvider<ExplorerRepo>(create: (context) => explorerRepo),
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
  final db = await connectDB();
  final eventBus = EventBus();
  final flowRepo = FlowRepo(db: db, eventBus: eventBus);
  final protoDefRepo = ProtoDefRepo(db: db);
  final containersRepo = ContainersRepo(eventBus: eventBus);
  final explorerRepo = ExplorerRepo(eventBus: eventBus);
  final config = Config.fromArgs([]);

  final deps = WidgetDependencies(
    db: db,
    eventBus: eventBus,
    flowRepo: flowRepo,
    protoDefRepo: protoDefRepo,
    containersRepo: containersRepo,
    explorerRepo: explorerRepo,
    config: config,
  );

  return deps;
}
