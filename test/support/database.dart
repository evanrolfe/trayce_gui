import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:trayce/common/database.dart';

class TestDatabase {
  static TestDatabase? _instance;
  late Database _db;

  // Private constructor
  TestDatabase._();

  // Getter for the database instance
  Database get db => _db;

  // Static method to get the singleton instance
  // IMPORTANT: TestWidgetsFlutterBinding.ensureInitialized() must be called before this
  static Future<TestDatabase> get instance async {
    // Create instance if it doesn't exist
    _instance ??= TestDatabase._();

    try {
      _instance!._db;
    } catch (_) {
      await _instance!._initialize();
    }

    return _instance!;
  }

  // Initialize the database connection
  Future<void> _initialize() async {
    // Connect DB
    sqfliteFfiInit();

    // Ensure that the SQLite library from sqlite3_flutter_libs is used
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      try {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      } catch (e) {
        print('Warning: Could not apply Android 6.0 workaround: $e');
      }
    }

    databaseFactory = databaseFactoryFfi;

    final String schema = await rootBundle.loadString('schema.sql');

    // Get the database path
    var databasesPath = await getDatabasesPath();
    var dbPath = path.join(databasesPath, 'test.db');

    // this stores the file in .dart_tool/sqflite_common_ffi/databases/
    _db = await databaseFactory.openDatabase(dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: initSchema(schema),
        ));

    print('Database initialized');
  }

  // Method to close the database
  Future<void> close() async {
    await _db.close();
  }

  // truncate all tables
  Future<void> truncate() async {
    await _db.delete('flows');
    await _db.delete('proto_defs');
  }
}
