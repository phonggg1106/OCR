import '../models/parsed_receipt.dart';
import '../core/constants.dart';

class ReceiptParser {
  /// Biểu thức chính quy tìm các từ khóa liên quan đến tổng tiền hóa đơn
  static final RegExp _totalKeywordPattern = RegExp(
    r'(tổng\s*cộng|tong\s*cong|tổng\s*tiền|tong\s*tien|thanh\s*toán|thanh\s*toan|tiền\s*thanh\s*toán|tổng|tong|total|amount\s*due|grand\s*total|tiền\s*phải\s*trả|phải\s*trả|phai\s*tra|cộng\s*tiền|cong\s*tien|net\s*total)',
    caseSensitive: false,
  );

  /// Biểu thức chính quy trích xuất số tiền (hỗ trợ phân cách chấm hoặc phẩy hàng nghìn)
  static final RegExp _amountPattern = RegExp(
    r'(?:^|[^\d])(\d{1,3}(?:[.,]\d{3})+(?:\.\d{2})?|\d{4,9})(?:\s*(?:đ|vnd|vnđ|d))?',
    caseSensitive: false,
  );

  /// Biểu thức chính quy nhận diện ngày tháng
  static final RegExp _datePattern = RegExp(
    r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b)|(\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)',
  );

  /// Các từ khóa loại trừ khi xác định tên cửa hàng (tránh lấy tiêu đề chung)
  static final List<String> _ignoredHeaderWords = [
    'hóa đơn',
    'hoa don',
    'hóa đơn bán lẻ',
    'hoa don ban le',
    'phiếu thanh toán',
    'phieu thanh toan',
    'phiếu thu',
    'phieu thu',
    'receipt',
    'bill',
    'tax invoice',
    'vat',
    'welcome',
    'xin chào',
    'cảm ơn',
    'cam on',
  ];

  /// Phương thức chính để phân tích văn bản OCR thô thành dữ liệu cấu trúc
  static ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedReceipt(rawText: '');
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final (totalAmount, matchedKeyword) = _extractTotalWithKeyword(lines);
    final merchantName = _extractMerchantName(lines);
    final date = _extractDate(lines);
    final category = _detectCategory(merchantName, rawText);

    return ParsedReceipt(
      merchantName: merchantName,
      totalAmount: totalAmount,
      date: date ?? DateTime.now(),
      rawText: rawText,
      detectedCategory: category,
      matchedKeyword: matchedKeyword,
      lines: lines,
    );
  }

  /// Trích xuất tổng tiền hóa đơn với từ khóa
  static (double?, String?) _extractTotalWithKeyword(List<String> lines) {
    // 1. Duyệt từ dưới lên trên vì "Tổng tiền" thường nằm ở cuối hóa đơn
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (_totalKeywordPattern.hasMatch(line)) {
        // Tìm số tiền trong dòng này
        final amount = _parseAmountFromLine(line);
        if (amount != null && amount > 0) {
          final keyword = _totalKeywordPattern.firstMatch(line)?.group(0);
          return (amount, keyword);
        }

        // Nếu dòng từ khóa không có số tiền (ví dụ bị ngắt dòng), kiểm tra dòng kế tiếp
        if (i + 1 < lines.length) {
          final nextAmount = _parseAmountFromLine(lines[i + 1]);
          if (nextAmount != null && nextAmount > 0) {
            return (nextAmount, 'Dòng kế tiếp');
          }
        }
      }
    }

    // 2. Dự phòng: Quét toàn bộ các số tiền xuất hiện và lấy số lớn nhất hợp lý (>= 1.000 VNĐ)
    double? maxSensibleAmount;
    for (final line in lines) {
      final amount = _parseAmountFromLine(line);
      if (amount != null && amount >= 1000) {
        if (maxSensibleAmount == null || amount > maxSensibleAmount) {
          maxSensibleAmount = amount;
        }
      }
    }

    return (maxSensibleAmount, maxSensibleAmount != null ? 'Ước tính từ số lớn nhất' : null);
  }

  /// Làm sạch và chuyển đổi số tiền từ một dòng văn bản
  static double? _parseAmountFromLine(String line) {
    // Bỏ qua các chuỗi như số điện thoại, mã số thuế nếu có từ khóa nhận diện
    if (line.toLowerCase().contains('mst') ||
        line.toLowerCase().contains('sđt') ||
        line.toLowerCase().contains('tel:')) {
      return null;
    }

    final matches = _amountPattern.allMatches(line);
    if (matches.isEmpty) return null;

    // Ưu tiên số ở cuối dòng
    for (final match in matches.toList().reversed) {
      final raw = match.group(1);
      if (raw == null) continue;

      // Loại bỏ dấu chấm, phẩy phân cách hàng nghìn
      final sanitized = raw.replaceAll('.', '').replaceAll(',', '');
      final parsed = double.tryParse(sanitized);
      if (parsed != null && parsed > 0 && parsed < 1000000000) {
        return parsed;
      }
    }
    return null;
  }

  /// Trích xuất tên nhà bán hàng / cửa hàng
  static String? _extractMerchantName(List<String> lines) {
    // 1. Kiểm tra đối sánh với danh sách các thương hiệu phổ biến tại Việt Nam
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      for (final merchant in popularVietnameseMerchants) {
        if (lineLower.contains(merchant.toLowerCase())) {
          return merchant;
        }
      }
    }

    // 2. Nếu không thuộc danh sách mẫu, lấy dòng đầu tiên có nghĩa (bỏ qua tiêu đề "HÓA ĐƠN", v.v.)
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      bool isIgnored = false;
      for (final ignored in _ignoredHeaderWords) {
        if (lineLower.contains(ignored) && lineLower.length < 25) {
          isIgnored = true;
          break;
        }
      }

      // Bỏ qua nếu dòng chỉ toàn số hoặc quá ngắn
      if (isIgnored || RegExp(r'^[0-9\W]+$').hasMatch(line) || line.length < 3) {
        continue;
      }

      // Làm sạch ký tự lạ ở đầu dòng
      return line.replaceAll(RegExp(r'^[^a-zA-ZÀ-ỹ0-9]+'), '').trim();
    }

    return 'Cửa hàng';
  }

  /// Trích xuất ngày giao dịch
  static DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      final match = _datePattern.firstMatch(line);
      if (match != null) {
        final dateStr = match.group(0)!;
        final parsed = _parseDateString(dateStr);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Chuyển đổi định dạng ngày phổ biến (DD/MM/YYYY hoặc YYYY-MM-DD)
  static DateTime? _parseDateString(String input) {
    try {
      final sep = input.contains('/') ? '/' : '-';
      final parts = input.split(sep);
      if (parts.length != 3) return null;

      int day;
      int month;
      int year;

      if (parts[0].length == 4) {
        // YYYY-MM-DD
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        // DD/MM/YYYY
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
        if (year < 100) year += 2000;
      }

      if (year >= 2000 && year <= 2050 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Suy luận danh mục chi tiêu tự động dựa trên tên cửa hàng hoặc nội dung hóa đơn
  static String _detectCategory(String? merchant, String rawText) {
    final text = '${merchant ?? ""} $rawText'.toLowerCase();

    if (text.contains('coffee') ||
        text.contains('cà phê') ||
        text.contains('trà sữa') ||
        text.contains('quán ăn') ||
        text.contains('nhà hàng') ||
        text.contains('food') ||
        text.contains('cơm') ||
        text.contains('bún') ||
        text.contains('phở') ||
        text.contains('highlands') ||
        text.contains('phúc long') ||
        text.contains('starbucks')) {
      return CategoryHelper.getName(ExpenseCategory.food);
    }

    if (text.contains('grab') ||
        text.contains('be ') ||
        text.contains('xanh sm') ||
        text.contains('xăng') ||
        text.contains('petrolimex') ||
        text.contains('taxi') ||
        text.contains('vé xe') ||
        text.contains('gửi xe')) {
      return CategoryHelper.getName(ExpenseCategory.transport);
    }

    if (text.contains('siêu thị') ||
        text.contains('mart') ||
        text.contains('co.op') ||
        text.contains('winmart') ||
        text.contains('bách hóa') ||
        text.contains('circle k') ||
        text.contains('shopee') ||
        text.contains('lazada') ||
        text.contains('tiki') ||
        text.contains('quần áo') ||
        text.contains('thời trang')) {
      return CategoryHelper.getName(ExpenseCategory.shopping);
    }

    if (text.contains('tiền điện') ||
        text.contains('tiền nước') ||
        text.contains('internet') ||
        text.contains('viettel') ||
        text.contains('vnpt') ||
        text.contains('fpt') ||
        text.contains('nhà thuốc') ||
        text.contains('pharmacity') ||
        text.contains('long châu')) {
      return CategoryHelper.getName(ExpenseCategory.utilities);
    }

    if (text.contains('cgv') ||
        text.contains('cinema') ||
        text.contains('rạp phim') ||
        text.contains('billiards') ||
        text.contains('karaoke') ||
        text.contains('game')) {
      return CategoryHelper.getName(ExpenseCategory.entertainment);
    }

    return CategoryHelper.getName(ExpenseCategory.other);
  }
}
