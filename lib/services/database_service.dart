import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../models/expense_item.dart';
import '../core/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  // Danh sách lưu trữ trong bộ nhớ khi chạy trên nền tảng Web (Chrome/Edge)
  final List<ExpenseItem> _webExpenses = [];
  bool _webInitialized = false;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'vku_expense_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        rawOcrText TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Thêm các dữ liệu mẫu ban đầu để trực quan hóa biểu đồ ngay lập tức
    
  }

  List<ExpenseItem> _getSampleList() {
    final now = DateTime.now();
    return [
      ExpenseItem(
        id: 'sample_1',
        title: 'Highlands Coffee',
        amount: 65000,
        date: now.subtract(const Duration(hours: 3)),
        category: CategoryHelper.getName(ExpenseCategory.food),
      ),
      ExpenseItem(
        id: 'sample_2',
        title: 'Co.opmart Đà Nẵng',
        amount: 245000,
        date: now.subtract(const Duration(days: 1)),
        category: CategoryHelper.getName(ExpenseCategory.shopping),
      ),
      ExpenseItem(
        id: 'sample_3',
        title: 'Xanh SM Taxi',
        amount: 48000,
        date: now.subtract(const Duration(days: 2)),
        category: CategoryHelper.getName(ExpenseCategory.transport),
      ),
      ExpenseItem(
        id: 'sample_4',
        title: 'CGV Vincom',
        amount: 110000,
        date: now.subtract(const Duration(days: 3)),
        category: CategoryHelper.getName(ExpenseCategory.entertainment),
      ),
      ExpenseItem(
        id: 'sample_5',
        title: 'Cơm Niêu VKU',
        amount: 35000,
        date: now.subtract(const Duration(days: 4)),
        category: CategoryHelper.getName(ExpenseCategory.food),
      ),
      ExpenseItem(
        id: 'sample_6',
        title: 'Tiền Internet Viettel',
        amount: 180000,
        date: now.subtract(const Duration(days: 5)),
        category: CategoryHelper.getName(ExpenseCategory.utilities),
      ),
    ];
  }

  Future<void> _insertSampleData(Database db) async {
    final samples = _getSampleList();
    for (final item in samples) {
      await db.insert('expenses', item.toMap());
    }
  }

  void _initWebIfNeeded() {
    if (kIsWeb && !_webInitialized) {
      _webInitialized = true;
    }
  }

  /// Thêm giao dịch chi tiêu mới
  Future<int> createExpense(ExpenseItem item) async {
    if (kIsWeb) {
      _initWebIfNeeded();
      _webExpenses.removeWhere((e) => e.id == item.id);
      _webExpenses.insert(0, item);
      return 1;
    }

    final db = await database;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy toàn bộ danh sách chi tiêu (sắp xếp giảm dần theo ngày)
  Future<List<ExpenseItem>> getAllExpenses() async {
    if (kIsWeb) {
      _initWebIfNeeded();
      final copy = List<ExpenseItem>.from(_webExpenses);
      copy.sort((a, b) => b.date.compareTo(a.date));
      return copy;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => ExpenseItem.fromMap(maps[i]));
  }

  /// Lấy chi tiêu theo ID
  Future<ExpenseItem?> getExpenseById(String id) async {
    if (kIsWeb) {
      _initWebIfNeeded();
      final match = _webExpenses.where((e) => e.id == id);
      return match.isNotEmpty ? match.first : null;
    }

    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ExpenseItem.fromMap(maps.first);
    }
    return null;
  }

  /// Cập nhật chi tiêu
  Future<int> updateExpense(ExpenseItem item) async {
    if (kIsWeb) {
      _initWebIfNeeded();
      final index = _webExpenses.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        _webExpenses[index] = item;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Xóa chi tiêu theo ID
  Future<int> deleteExpense(String id) async {
    if (kIsWeb) {
      _initWebIfNeeded();
      _webExpenses.removeWhere((e) => e.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Lấy tổng chi tiêu theo từng danh mục
  Future<Map<String, double>> getCategoryTotals() async {
    if (kIsWeb) {
      _initWebIfNeeded();
      final Map<String, double> totals = {};
      for (final e in _webExpenses) {
        totals[e.category] = (totals[e.category] ?? 0.0) + e.amount;
      }
      return totals;
    }

    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      GROUP BY category
    ''');

    final Map<String, double> totals = {};
    for (final row in result) {
      totals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  /// Lấy tổng chi tiêu trong 7 ngày gần nhất
  Future<Map<DateTime, double>> getWeeklyTotals() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<DateTime, double> weeklyMap = {};
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: 6 - i));
      weeklyMap[d] = 0.0;
    }

    if (kIsWeb) {
      _initWebIfNeeded();
      for (final item in _webExpenses) {
        final dayKey = DateTime(item.date.year, item.date.month, item.date.day);
        if (weeklyMap.containsKey(dayKey)) {
          weeklyMap[dayKey] = (weeklyMap[dayKey] ?? 0.0) + item.amount;
        }
      }
      return weeklyMap;
    }

    final db = await database;
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT date, amount
      FROM expenses
      WHERE date >= ?
      ORDER BY date ASC
    ''',
      [sevenDaysAgo.toIso8601String()],
    );

    for (final row in result) {
      final date = DateTime.parse(row['date'] as String);
      final dayKey = DateTime(date.year, date.month, date.day);
      if (weeklyMap.containsKey(dayKey)) {
        weeklyMap[dayKey] = (weeklyMap[dayKey] ?? 0.0) + (row['amount'] as num).toDouble();
      }
    }

    return weeklyMap;
  }

  /// Đóng cơ sở dữ liệu khi không cần thiết
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
    _database = null;
  }
}
