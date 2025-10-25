import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static late Database db;

  static Future<Database> init() async {
    db = sqlite3.open('mensajeria.db');
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      );
    ''');
    return db;
  }
}
