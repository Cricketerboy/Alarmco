import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize database
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    try {
      final path = await getDatabasesPath();
      return await openDatabase(
        join(path, 'alarms.db'),
        onCreate: (db, version) {
          return db.execute(
            '''
            CREATE TABLE alarms(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              time TEXT,
              repeat TEXT,
              isEnabled INTEGER
            )
            ''',
          );
        },
        version: 1,
      );
    } catch (e) {
      print("Error initializing database: $e");
      rethrow; // Rethrow the error after logging it
    }
  }

  static Future<int> insertAlarm(Map<String, dynamic> alarm) async {
    try {
      final db = await database;
      return await db.insert('alarms', alarm);
    } catch (e) {
      print("Error inserting alarm: $e");
      return -1; // Return -1 to indicate failure
    }
  }

  static Future<List<Map<String, dynamic>>> getAlarms() async {
    try {
      final db = await database;
      return await db.query('alarms');
    } catch (e) {
      print("Error fetching alarms: $e");
      return []; // Return an empty list in case of failure
    }
  }

  static Future<int> updateAlarm(int id, Map<String, dynamic> alarm) async {
    try {
      final db = await database;
      return await db.update('alarms', alarm, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error updating alarm: $e");
      return -1; // Return -1 to indicate failure
    }
  }

  static Future<int> deleteAlarm(int id) async {
    try {
      final db = await database;
      return await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error deleting alarm: $e");
      return -1; // Return -1 to indicate failure
    }
  }
}
