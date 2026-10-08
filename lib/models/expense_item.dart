import '../core/currency_format.dart';
import '../core/constants.dart';

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? imagePath;
  final String? rawOcrText;
  final DateTime createdAt;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? date;

  String get formattedAmount => CurrencyFormat.formatVND(amount);
  String get formattedDate => CurrencyFormat.formatDate(date);
  ExpenseCategory get categoryEnum => CategoryHelper.fromString(category);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      imagePath: map['imagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
