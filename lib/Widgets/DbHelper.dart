import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  Future<Database> initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'device_data.db');

    return openDatabase(path, onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE readings(id INTEGER PRIMARY KEY, systolic INT, diastolic INT, pulse INT)",
      );
    }, version: 1);
  }

  Future<void> insertData(Database db, Map<String, Object> data) async {
    await db.insert('readings', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
