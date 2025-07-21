import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// Return a function that matches the onCreate callback signature: void Function(Database db, int version)
Function(Database db, int version) initSchema(String schema) {
  return (Database db, int version) {
    final batch = db.batch();

    final List<String> queries = schema.split(';').map((q) => q.trim()).where((q) => q.isNotEmpty).toList();

    for (final query in queries) {
      batch.execute(query);
    }

    // These can't be part of schema.sql for some reason
    batch.execute("""CREATE TRIGGER flow_insert AFTER INSERT ON flows BEGIN
      INSERT INTO flows_fts (rowid, uuid, source, dest, protocol, operation, status)
      VALUES (new.id, new.uuid, new.source, new.dest, new.protocol, new.operation, new.status);
    END;""");

    batch.execute("""CREATE TRIGGER flow_update AFTER UPDATE ON flows BEGIN
      INSERT INTO flows_fts (flows_fts) VALUES ('rebuild');
    END;""");

    batch.execute("""CREATE TRIGGER flow_delete AFTER DELETE ON flows BEGIN
      INSERT INTO flows_fts(flows_fts, rowid , uuid, source, dest, protocol, operation, status)
      VALUES('delete', old.id, old.uuid, old.source, old.dest, old.protocol, old.operation, old.status);
    END;""");

    return batch.commit();
  };
}

Future<Database> connectDB([String? dbFile]) async {
  final defaultDBFile = 'tmp.db';

  // Load schema.sql file
  final String schema = await rootBundle.loadString('schema.sql');

  // Initialize SQLite with sqlite3_flutter_libs
  sqfliteFfiInit();

  // Ensure that the SQLite library from sqlite3_flutter_libs is used
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    // This ensures the bundled sqlite3 library is loaded and used
    // For Android 6.0 compatibility, you might need to use:
    // await sqlite3_flutter_libs.applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    try {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (e) {
      print('Warning: Could not apply Android 6.0 workaround: $e');
    }
  }

  databaseFactory = databaseFactoryFfi;

  // this stores the file in .dart_tool/sqflite_common_ffi/databases/
  String dbPath;
  if (dbFile != null) {
    dbPath = dbFile;
  } else {
    var databasesPath = await getDatabasesPath();
    dbPath = path.join(databasesPath, dbFile ?? defaultDBFile);

    // Delete existing tmp.db database file if it exists
    if (await databaseFactory.databaseExists(dbPath)) {
      await databaseFactory.deleteDatabase(dbPath);
    }
  }

  print('loading db from: $dbPath');

  var db = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(version: 1, onCreate: initSchema(schema)),
  );

  // Workaround for this issue: https://stackoverflow.com/questions/78908421/sqlite-not-working-on-macos-using-swiftui-with-the-app-sandbox
  await db.execute("PRAGMA journal_mode = MEMORY");

  return db;
}

Future<Database> connectMemoryDB() async {
  // Load schema.sql file
  final String schema = await rootBundle.loadString('schema.sql');

  // Initialize SQLite with sqlite3_flutter_libs
  sqfliteFfiInit();

  // Ensure that the SQLite library from sqlite3_flutter_libs is used
  if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    try {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (e) {
      print(
        'Warning: Could not apply Android 6.0 workaround: '
        ' [33m$e [0m',
      );
    }
  }

  databaseFactory = databaseFactoryFfi;

  // Use in-memory database
  const String memoryDbPath = ':memory:';
  print('loading in-memory db');

  var db = await databaseFactory.openDatabase(
    memoryDbPath,
    options: OpenDatabaseOptions(version: 1, onCreate: initSchema(schema)),
  );

  await db.execute("PRAGMA journal_mode = MEMORY");

  return db;
}
