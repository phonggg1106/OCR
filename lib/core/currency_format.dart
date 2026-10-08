import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Định dạng số tiền sang định dạng VNĐ (ví dụ: 150.000 ₫)
  static String formatVND(double amount) {
    return _vndFormat.format(amount).trim();
  }

  /// Định dạng số thuần túy có dấu phân cách hàng nghìn (ví dụ: 150.000)
  static String formatNumber(double amount) {
    return _numberFormat.format(amount);
  }

  /// Chuyển đổi chuỗi tiền tệ bất kỳ thành double
  static double parseAmount(String text) {
    final clean = text
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
    if (clean.isEmpty) return 0.0;
    return double.tryParse(clean) ?? 0.0;
  }

  /// Định dạng ngày hiển thị dd/MM/yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Định dạng ngày giờ hiển thị dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Định dạng tên thứ và ngày tháng ngắn (VD: T2, 08/10)
  static String formatShortDay(DateTime date) {
    final weekdayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final name = weekdayNames[date.weekday - 1];
    return '$name, ${date.day}/${date.month}';
  }
}
