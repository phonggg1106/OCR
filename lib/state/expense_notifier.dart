import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_item.dart';
import '../services/database_service.dart';

/// Notifier quản lý danh sách giao dịch chi tiêu thông qua Riverpod 2 AsyncNotifier
class ExpenseNotifier extends AsyncNotifier<List<ExpenseItem>> {
  final DatabaseService _db = DatabaseService.instance;

  @override
  Future<List<ExpenseItem>> build() async {
    return await _db.getAllExpenses();
  }

  /// Thêm khoản chi tiêu mới và cập nhật trạng thái UI ngay lập tức
  Future<void> addExpense(ExpenseItem item) async {
    // 1. Lưu vào SQLite
    await _db.createExpense(item);

    // 2. Cập nhật state bất biến (Immutable State)
    final previousState = state.value ?? [];
    state = AsyncData([item, ...previousState]);
  }

  /// Xóa khoản chi tiêu theo ID
  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);

    final previousState = state.value ?? [];
    state = AsyncData(previousState.where((e) => e.id != id).toList());
  }

  /// Cập nhật thông tin chi tiêu đã có
  Future<void> updateExpense(ExpenseItem updated) async {
    await _db.updateExpense(updated);

    final previousState = state.value ?? [];
    state = AsyncData(
      previousState.map((e) => e.id == updated.id ? updated : e).toList(),
    );
  }

  /// Làm mới lại danh sách từ cơ sở dữ liệu
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _db.getAllExpenses());
  }
}

/// Global Compile-time Safe Provider định nghĩa theo chuẩn Riverpod 2
final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<ExpenseItem>>(
  ExpenseNotifier.new,
);

/// Provider tính tổng chi tiêu toàn bộ
final grandTotalProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseProvider);
  return expensesAsync.maybeWhen(
    data: (items) => items.fold(0.0, (sum, item) => sum + item.amount),
    orElse: () => 0.0,
  );
});

/// Provider tính tổng chi tiêu theo từng danh mục
final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expensesAsync = ref.watch(expenseProvider);
  return expensesAsync.maybeWhen(
    data: (items) {
      final Map<String, double> totals = {};
      for (final item in items) {
        totals[item.category] = (totals[item.category] ?? 0.0) + item.amount;
      }
      return totals;
    },
    orElse: () => {},
  );
});

/// Provider tính tổng chi tiêu 7 ngày qua
final weeklyTotalsProvider = Provider<Map<DateTime, double>>((ref) {
  final expensesAsync = ref.watch(expenseProvider);
  return expensesAsync.maybeWhen(
    data: (items) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final Map<DateTime, double> weekly = {};

      for (int i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: 6 - i));
        weekly[day] = 0.0;
      }

      for (final item in items) {
        final itemDay = DateTime(item.date.year, item.date.month, item.date.day);
        if (weekly.containsKey(itemDay)) {
          weekly[itemDay] = (weekly[itemDay] ?? 0.0) + item.amount;
        }
      }

      return weekly;
    },
    orElse: () => {},
  );
});
