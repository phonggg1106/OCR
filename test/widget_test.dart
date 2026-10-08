import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/main.dart';

void main() {
  testWidgets('ExpenseTrackerApp khởi chạy giao diện thành công', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra tiêu đề hoặc thành phần giao diện chính xuất hiện
    expect(find.text('Sổ Chi Tiêu & OCR'), findsOneWidget);
    expect(find.text('Quét hóa đơn'), findsWidgets);
  });
}
