import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';

class IntakeDatabase {
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'hydraflow.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE intake (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          drink_id TEXT NOT NULL, volume_ml INTEGER NOT NULL,
          effective_ml INTEGER NOT NULL, timestamp INTEGER NOT NULL,
          goal_ml INTEGER NOT NULL
        )
      '''),
    );
    return _db!;
  }
  Future<int> insert(IntakeEntry entry) async {
    final db = await database;
    return db.insert('intake', entry.toMap()..remove('id'));
  }
  Future<void> delete(int id) async => (await database).delete('intake', where: 'id = ?', whereArgs: [id]);
  Future<List<IntakeEntry>> all() async {
    final rows = await (await database).query('intake', orderBy: 'timestamp DESC');
    return rows.map(IntakeEntry.fromMap).toList();
  }
  Future<List<IntakeEntry>> between(DateTime start, DateTime end) async {
    final rows = await (await database).query(
      'intake', where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return rows.map(IntakeEntry.fromMap).toList();
  }
}
