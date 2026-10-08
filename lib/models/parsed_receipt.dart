class ParsedReceipt {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final String rawText;
  final String? detectedCategory;
  final String? matchedKeyword;
  final List<String> lines;

  const ParsedReceipt({
    this.merchantName,
    this.totalAmount,
    this.date,
    required this.rawText,
    this.detectedCategory,
    this.matchedKeyword,
    this.lines = const [],
  });

  bool get hasValidData =>
      (merchantName != null && merchantName!.trim().isNotEmpty) ||
      (totalAmount != null && totalAmount! > 0);

  ParsedReceipt copyWith({
    String? merchantName,
    double? totalAmount,
    DateTime? date,
    String? rawText,
    String? detectedCategory,
    String? matchedKeyword,
    List<String>? lines,
  }) {
    return ParsedReceipt(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      rawText: rawText ?? this.rawText,
      detectedCategory: detectedCategory ?? this.detectedCategory,
      matchedKeyword: matchedKeyword ?? this.matchedKeyword,
      lines: lines ?? this.lines,
    );
  }

  @override
  String toString() {
    return 'ParsedReceipt(merchant: $merchantName, total: $totalAmount, date: $date, category: $detectedCategory)';
  }
}
