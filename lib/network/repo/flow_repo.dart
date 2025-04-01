import 'package:event_bus/event_bus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trayce/agent/server.dart';

import '../models/flow.dart';

class EventDisplayFlows {
  final List<Flow> flows;

  EventDisplayFlows(this.flows);
}

class FlowRepo {
  Database db;
  final EventBus _eventBus;
  String? _searchTerm;

  FlowRepo({required this.db, required EventBus eventBus}) : _eventBus = eventBus {
    _eventBus.on<EventFlowsObserved>().listen((event) async {
      for (final agentFlow in event.flows) {
        final flow = Flow.fromProto(agentFlow);
        await save(flow);
        displayFlows();
      }
    });
  }

  Future<void> displayFlows() async {
    print('Reloading flows with search term: $_searchTerm');
    final flows = await getFlows(_searchTerm);
    _eventBus.fire(EventDisplayFlows(flows));
  }

  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.isEmpty ? null : term;
    await displayFlows();
  }

  Future<Flow> save(Flow flow) async {
    // First check if flow exists
    final existing = await db.query(
      'flows',
      where: 'uuid = ?',
      whereArgs: [flow.uuid],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing flow
      await db.update(
        'flows',
        {
          'response_raw': flow.responseRaw,
          'status': flow.status,
        },
        where: 'uuid = ?',
        whereArgs: [flow.uuid],
      );
      return flow.copyWith(id: existing.first['id'] as int);
    }

    // Insert new flow
    final id = await db.insert('flows', {
      'uuid': flow.uuid,
      'source': flow.source,
      'dest': flow.dest,
      'l4_protocol': flow.l4Protocol,
      'protocol': flow.l7Protocol,
      'operation': flow.operation,
      'status': flow.status,
      'request_raw': flow.requestRaw,
      'response_raw': flow.responseRaw,
      'created_at': flow.createdAt.toIso8601String(),
    });

    return flow.copyWith(id: id);
  }

  Future<List<Flow>> getFlows([String? searchTerm]) async {
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // First get matching flow IDs from FTS
      final List<Map<String, dynamic>> ftsResults = await db.query(
        'flows_fts',
        columns: ['id'],
        where: 'flows_fts MATCH ?',
        // Escape special characters and wrap in quotes for exact matching
        whereArgs: ['"${searchTerm.replaceAll('"', '""')}"'],
      );

      final List<int> matchingIds = ftsResults.map((row) => row['id'] as int).toList();
      if (matchingIds.isEmpty) {
        return [];
      }

      // Then get the actual flows using the matching IDs
      final List<Map<String, dynamic>> maps = await db.query(
        'flows',
        where: 'id IN (${List.filled(matchingIds.length, '?').join(',')})',
        whereArgs: matchingIds,
        orderBy: 'id DESC',
      );
      return maps.map((map) => Flow.fromMap(map)).toList();
    }

    // No search term, get all flows
    final List<Map<String, dynamic>> maps = await db.query(
      'flows',
      orderBy: 'id DESC',
    );
    return maps.map((map) => Flow.fromMap(map)).toList();
  }
}
