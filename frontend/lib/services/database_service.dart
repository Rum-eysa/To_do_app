import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE todos ADD COLUMN userId TEXT NOT NULL DEFAULT ""');
    }
  }

  Future<void> insertTodo(Todo todo, String userId) async {
    final db = await database;
    final map = todo.toMap();
    map['userId'] = userId;
    await db.insert('todos', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTodo(Todo todo, String userId) async {
    final db = await database;
    final map = todo.toMap();
    map['userId'] = userId;
    await db.update('todos', map,
        where: 'id = ? AND userId = ?', whereArgs: [todo.id, userId]);
  }

  Future<void> deleteTodo(String id, String userId) async {
    final db = await database;
    await db.delete('todos',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<Todo>> getAllTodos(String userId) async {
    final db = await database;
    final maps = await db.query('todos',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return maps.map((e) => Todo.fromMap(e)).toList();
  }

  Future<List<Todo>> getUnsyncedTodos(String userId) async {
    final db = await database;
    final maps = await db.query('todos',
        where: 'isSynced = ? AND userId = ?', whereArgs: [0, userId]);
    return maps.map((e) => Todo.fromMap(e)).toList();
  }

  Future<void> markAsSynced(String id, String userId) async {
    final db = await database;
    await db.update('todos', {'isSynced': 1},
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<void> upsertTodos(List<Todo> todos, String userId) async {
    final db = await database;
    final batch = db.batch();
    for (final todo in todos) {
      final map = todo.toMap();
      map['userId'] = userId;
      batch.insert('todos', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearUserTodos(String userId) async {
    final db = await database;
    await db.delete('todos', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
