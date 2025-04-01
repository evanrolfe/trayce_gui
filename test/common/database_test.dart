import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/common/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('connectDB', () {
    test('it creates the flows table in memory', () async {
      final db = await connectDB('dbTest.db');

      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'flows'],
      );

      expect(tables.length, 1);
      expect(tables.first['name'], 'flows');
    });
  });
}
