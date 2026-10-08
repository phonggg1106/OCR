import 'package:flutter/material.dart';

/// Các danh mục chi tiêu chính của ứng dụng
enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  other,
}

class CategoryHelper {
  static const Map<ExpenseCategory, String> vietnameseNames = {
    ExpenseCategory.food: 'Ăn uống',
    ExpenseCategory.transport: 'Di chuyển',
    ExpenseCategory.shopping: 'Mua sắm',
    ExpenseCategory.utilities: 'Tiện ích & Hóa đơn',
    ExpenseCategory.entertainment: 'Giải trí',
    ExpenseCategory.other: 'Khác',
  };

  static const Map<ExpenseCategory, IconData> icons = {
    ExpenseCategory.food: Icons.restaurant_rounded,
    ExpenseCategory.transport: Icons.directions_car_rounded,
    ExpenseCategory.shopping: Icons.shopping_bag_rounded,
    ExpenseCategory.utilities: Icons.receipt_long_rounded,
    ExpenseCategory.entertainment: Icons.movie_filter_rounded,
    ExpenseCategory.other: Icons.category_rounded,
  };

  static const Map<ExpenseCategory, Color> colors = {
    ExpenseCategory.food: Color(0xFFF97316), // Cam tươi
    ExpenseCategory.transport: Color(0xFF2563EB), // Xanh dương
    ExpenseCategory.shopping: Color(0xFF8B5CF6), // Tím pastel
    ExpenseCategory.utilities: Color(0xFF0D9488), // Xanh ngọc
    ExpenseCategory.entertainment: Color(0xFFEC4899), // Hồng
    ExpenseCategory.other: Color(0xFF64748B), // Xám xanh
  };

  static String getName(ExpenseCategory category) =>
      vietnameseNames[category] ?? 'Khác';

  static IconData getIcon(ExpenseCategory category) =>
      icons[category] ?? Icons.category_rounded;

  static Color getColor(ExpenseCategory category) =>
      colors[category] ?? const Color(0xFF64748B);

  static ExpenseCategory fromString(String name) {
    for (final entry in vietnameseNames.entries) {
      if (entry.value.toLowerCase() == name.toLowerCase() ||
          entry.key.name.toLowerCase() == name.toLowerCase()) {
        return entry.key;
      }
    }
    return ExpenseCategory.other;
  }
}

/// Danh sách chuỗi nhận diện các chuỗi thương hiệu phổ biến tại Việt Nam
const List<String> popularVietnameseMerchants = [
  'Highlands Coffee',
  'The Coffee House',
  'Phúc Long',
  'Trung Nguyên Legend',
  'Starbucks',
  'Katinat Saigon Kafe',
  'Cheese Coffee',
  'Co.opmart',
  'Co.op Food',
  'Co.op Smile',
  'WinMart',
  'WinMart+',
  'Bách Hóa Xanh',
  'Big C',
  'GO! Mall',
  'Lotte Mart',
  'Aeon Mall',
  'Circle K',
  'FamilyMart',
  'GS25',
  '7-Eleven',
  'Ministop',
  'Shopee',
  'Lazada',
  'Tiki',
  'GrabFood',
  'GrabCar',
  'GrabBike',
  'BeFood',
  'BeBike',
  'Xanh SM',
  'ShopeeFood',
  'CGV Cinemas',
  'Lotte Cinema',
  'Galaxy Cinema',
  'Nhà thuốc An Khang',
  'Nhà thuốc Long Châu',
  'Pharmacity',
  'Thế Giới Di Động',
  'Điện Máy XANH',
  'FPT Shop',
  'CellphoneS',
];
