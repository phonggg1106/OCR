import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/main.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';
import 'package:vku_expense_ocr/state/expense_notifier.dart';

class _SimpleMockNotifier extends ExpenseNotifier {
  final List<ExpenseItem> items;
  _SimpleMockNotifier(this.items);

  @override
  Future<List<ExpenseItem>> build() async {
    return items;
  }
}

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('ExpenseTrackerApp khởi chạy giao diện thành công', (WidgetTester tester) async {
    // Đặt kích thước màn hình test chuẩn thiết bị di động
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final sampleExpenses = [
      ExpenseItem(
        id: 'test_1',
        title: 'Highlands Coffee',
        amount: 65000,
        date: DateTime.now(),
        category: 'Ăn uống',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseProvider.overrideWith(() => _SimpleMockNotifier(sampleExpenses)),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );

    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Sổ Chi Tiêu & OCR'), findsOneWidget);
    expect(find.text('Quét hóa đơn'), findsWidgets);
    expect(find.text('Highlands Coffee'), findsOneWidget);
  });
}
