# Mini-Project 3: Sổ Quản Lý Chi Tiêu & Quét Hóa Đơn Tự Động (OCR On-Device)

> **Môn học:** Lập trình ứng dụng di động đa nền tảng (Cross-Platform Mobile App Development)  
> **Trường:** Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU), Đại học Đà Nẵng  
> **Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  

---

## 📱 Giới thiệu tổng quan
Ứng dụng **VKU Expense OCR** là giải pháp quản lý tài chính cá nhân dành cho sinh viên và người dùng, tích hợp **Trí tuệ nhân tạo On-Device (Google ML Kit)** nhằm tự động nhận diện và trích xuất thông tin hóa đơn (Tên thương hiệu/cửa hàng, Tổng số tiền thanh toán, Ngày giao dịch) từ ảnh chụp máy ảnh hoặc thư viện mà **hoàn toàn không cần kết nối mạng hay gửi dữ liệu lên server ngoài**.

Dữ liệu được lưu trữ an toàn trong cơ sở dữ liệu nội bộ **SQLite**, hiển thị trực quan thông qua các biểu đồ **Donut Chart** và **Weekly Bar Chart** được vẽ thuần bằng **CustomPainter** kết hợp hiệu ứng chuyển động mượt mà 120Hz.

---

## 🌟 Tính năng nổi bật & Kiến trúc hệ thống

1. **On-Device OCR & Regex Heuristic Parser:**
   - Sử dụng `google_mlkit_text_recognition` chạy trực tiếp trên GPU/NPU của thiết bị.
   - Bộ giải thuật Heuristic tối ưu hóa riêng cho các loại hóa đơn tại Việt Nam (hỗ trợ dấu chấm/phẩy hàng nghìn, đơn vị VNĐ/đ, nhận diện các chuỗi thương hiệu lớn như Highlands Coffee, Phúc Long, Co.opmart, WinMart, Xanh SM...).
2. **Màn hình Xác thực & Kiểm tra (Review & Verification Screen):**
   - Cho phép người dùng trực tiếp kiểm tra giá trị ML Kit bóc tách, tự động điền form với kiểm thử tính hợp lệ nghiêm ngặt (`Form`, `GlobalKey<FormState>`, `TextFormField`).
   - Hỗ trợ chọn danh mục chi tiêu, ngày giao dịch và xem ảnh chụp gốc.
3. **Quản lý trạng thái hiện đại với Riverpod 2:**
   - Áp dụng mô hình `AsyncNotifier` và `ref.watch`/`ref.read` giúp ứng dụng đạt độ an toàn kiểu tĩnh ở thời điểm biên dịch (Compile-time Safety), loại bỏ hiện tượng lỗi `ProviderNotFoundException`.
4. **Điều hướng khai báo (Declarative Routing) với GoRouter:**
   - Sử dụng `ShellRoute` để lưu giữ trạng thái thanh điều hướng dưới đáy (Bottom Navigation Bar) cho các tab `Tổng quan` và `Quét hóa đơn`.
5. **Biểu đồ động vẽ thuần bằng Custom Canvas (`CustomPainter`):**
   - **Donut Chart**: Thể hiện tỷ trọng cơ cấu danh mục chi tiêu với hiệu ứng quay và bung cung (`canvas.drawArc`), hiển thị tâm và chú thích tương tác.
   - **Weekly Bar Chart**: Biểu đồ cột thể hiện mức chi tiêu theo 7 ngày gần nhất (`canvas.drawRRect`), phân biệt ngày hiện tại và tương tác chọn cột.
   - Hoàn toàn **không dùng thư viện ngoài**, đạt chuẩn 120Hz mượt mà.
6. **Lưu trữ dữ liệu SQLite nội bộ (`sqflite`):**
   - Quản lý toàn bộ giao dịch, hỗ trợ CRUD, tính toán tổng danh mục và tổng chi tiêu theo tuần.

---

## 🏛 Cấu trúc thư mục (Clean Architecture)

```
lib/
├── core/
│   ├── constants.dart        # Danh mục chi tiêu, màu sắc, danh sách thương hiệu Việt
│   ├── currency_format.dart  # Định dạng tiền tệ VNĐ, ngày tháng tiếng Việt
│   └── theme.dart            # Thiết kế Minimalist White Theme (Material 3)
├── models/
│   ├── expense_item.dart     # Model chi tiêu (SQLite entity, copyWith, toMap)
│   └── parsed_receipt.dart   # Model kết quả bóc tách OCR
├── services/
│   ├── database_service.dart # SQLite DB Singleton (CRUD, thống kê)
│   ├── ocr_service.dart      # Bộ xử lý Google ML Kit Text Recognition
│   └── receipt_parser.dart   # Engine Regex Heuristic bóc tách hóa đơn
├── state/
│   ├── expense_notifier.dart # Riverpod 2 AsyncNotifier & Derived Providers
│   └── router.dart           # Cấu hình GoRouter với ShellRoute
├── widgets/
│   ├── charts/
│   │   ├── donut_chart.dart  # DonutChartPainter & AnimatedCategoryDonutChart
│   │   └── bar_chart.dart    # WeeklyBarChartPainter & AnimatedWeeklyBarChart
│   └── expense_card.dart     # Thẻ hiển thị hóa đơn (Dismissible vuốt xóa, Material 3)
├── screens/
│   ├── main_shell.dart       # Khung Scaffold cố định thanh NavigationBar
│   ├── home_screen.dart      # Màn hình Dashboard tổng quan & danh sách
│   ├── scanner_screen.dart   # Màn hình chụp/quét hóa đơn & bộ mẫu thử nghiệm
│   ├── review_screen.dart    # Màn hình xác thực & chỉnh sửa dữ liệu OCR
│   └── expense_detail_screen.dart # Xem chi tiết giao dịch
└── main.dart                 # Điểm khởi chạy ứng dụng (ProviderScope)
```

---

## 🔍 Bảng quy tắc Regex Heuristic bóc tách hóa đơn

| Thành phần | Biểu thức chính quy (Regex) | Ví dụ nhận diện thực tế |
|---|---|---|
| **Từ khóa Tổng tiền** | `r'(tổng\s*cộng\|tổng\s*tiền\|thanh\s*toán\|total\|amount\s*due\|phải\s*trả\|cong\s*tien)'` | `TỔNG TIỀN: 65.000 đ`, `THANH TOÁN: 86000`, `TOTAL: 190.000` |
| **Giá trị Tiền (Số)** | `r'(?:^\|[^\d])(\d{1,3}(?:[.,]\d{3})+(?:\.\d{2})?\|\d{4,9})'` | `65.000`, `245,000`, `86000`, `150.000đ` |
| **Ngày giao dịch** | `r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b)\|(b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)'` | `22/10/2026`, `21-10-2026`, `2026-10-20` |
| **Tên cửa hàng** | Đối khớp danh sách chuỗi thương hiệu Việt Nam (`popularVietnameseMerchants`) + bộ lọc loại trừ tiêu đề rác (`HÓA ĐƠN`, `RECEIPT`, `VAT`) | Highlands Coffee, Phúc Long, Co.opmart, Xanh SM, Circle K... |

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### 1. Yêu cầu môi trường
- Flutter SDK: `>=3.0.0` (khuyên dùng Flutter 3.20+ hoặc 3.47+)
- Dart SDK: `>=3.0.0`
- Thiết bị Android vật lý hoặc Emulator (Android 5.0 Lollipop - API 21 trở lên)

### 2. Cài đặt các gói phụ thuộc
```bash
flutter pub get
```

### 3. Chạy kiểm thử tự động (Unit Tests)
```bash
flutter test test/receipt_parser_test.dart
```

### 4. Khởi chạy ứng dụng
```bash
flutter run
```

### 5. Đóng gói bản phát hành APK
```bash
flutter build apk --release
```
Tệp APK sau khi xuất bản sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`.
