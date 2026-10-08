import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';
import 'package:vku_expense_ocr/core/constants.dart';

void main() {
  group('ReceiptParser Heuristic Tests', () {
    test('Phân tích thành công hóa đơn Highlands Coffee với dấu chấm phân cách', () {
      const sample = '''HIGHLANDS COFFEE
Chi nhánh: Da Nang Indochina
Ngày: 22/10/2026 09:30
1x Phin Sữa Đá Size L: 45.000
1x Bánh Mì Thịt Nướng: 20.000
TỔNG TIỀN: 65.000 đ
Cảm ơn quý khách!''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchantName, equals('Highlands Coffee'));
      expect(parsed.totalAmount, equals(65000.0));
      expect(parsed.date?.day, equals(22));
      expect(parsed.date?.month, equals(10));
      expect(parsed.date?.year, equals(2026));
      expect(parsed.detectedCategory, equals(CategoryHelper.getName(ExpenseCategory.food)));
    });

    test('Phân tích thành công hóa đơn Co.opmart với dấu phẩy và ngày gạch nối', () {
      const sample = '''CO.OPMART ĐÀ NẴNG
HÓA ĐƠN BÁN LẺ
Ngày bán: 21-10-2026
Sữa tươi tiệt trùng: 35.000
Bánh quy bơ: 60.000
Nước giặt OMO: 150.000
TỔNG CỘNG: 245,000 VNĐ
TIỀN PHẢI TRẢ: 245.000''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchantName, equals('Co.opmart'));
      expect(parsed.totalAmount, equals(245000.0));
      expect(parsed.date?.day, equals(21));
      expect(parsed.date?.month, equals(10));
      expect(parsed.date?.year, equals(2026));
      expect(parsed.detectedCategory, equals(CategoryHelper.getName(ExpenseCategory.shopping)));
    });

    test('Phân tích hóa đơn Xanh SM taxi với số liền và ngày YYYY-MM-DD', () {
      const sample = '''XANH SM TAXI VIETNAM
Chuyến đi: VKU -> Sân bay Đà Nẵng
Thời gian: 2026-10-20 14:15
Cước phí dịch vụ: 86.000
THANH TOÁN: 86000 đ
Hình thức: Tiền mặt''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchantName, equals('Xanh SM'));
      expect(parsed.totalAmount, equals(86000.0));
      expect(parsed.date?.day, equals(20));
      expect(parsed.date?.month, equals(10));
      expect(parsed.date?.year, equals(2026));
      expect(parsed.detectedCategory, equals(CategoryHelper.getName(ExpenseCategory.transport)));
    });

    test('Fallback trích xuất số tiền lớn nhất khi không có từ khóa rõ ràng', () {
      const sample = '''CỬA HÀNG BÁCH HÓA
Item 1: 15.000
Item 2: 50.000
Item 3: 135.000
Xin cảm ơn hẹn gặp lại''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.totalAmount, equals(135000.0));
    });
  });
}
