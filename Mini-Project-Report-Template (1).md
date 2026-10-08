# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: OCR Expense Tracker & Receipt Parser  
**Team / Student Name:** Bui Hoang Phong  
**Submission Date:** 08/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Bui Hoang Phong — Student ID: 23IT208 — Role: Full-stack Mobile Engineer — Contribution: 100%
* **🔗 Live Demo URL:** https://vku-expense-ocr.vku-bookroom.workers.dev
* **💻 GitHub Repository:** https://github.com/phonggg1106/OCR
* **📦 Release APK:** `build/app/outputs/flutter-apk/app-release.apk` (và `OCR.apk` trong repo)
* **🎥 Video Demo:** `Video_Demo.mp4` (đã đính kèm trong repository)

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **Camera Capture & Image Ingestion** | ✅ Complete | Chụp ảnh qua Máy ảnh hoặc chọn từ Thư viện ảnh bằng `image_picker: ^1.0.7`, hỗ trợ xem trước ảnh tức thì. |
| 2 | **On-Device OCR (Google ML Kit)** | ✅ Complete | Nhận dạng văn bản Offline on-device bằng `google_mlkit_text_recognition: ^0.14.0`, xử lý hoàn toàn trên chip thiết bị, bảo mật dữ liệu riêng tư. |
| 3 | **Regex Heuristic Parser** | ✅ Complete | Bộ giải thuật bóc tách Regex tối ưu cho hóa đơn Việt Nam: trích xuất Tên cửa hàng, Ngày giao dịch, và Tổng số tiền (hỗ trợ dấu chấm/phẩy hàng nghìn, đuôi đ/VNĐ). |
| 4 | **Review & Verification Screen** | ✅ Complete | Màn hình `ReviewScreen` (`EditReceiptForm`) điền sẵn dữ liệu trích xuất từ OCR, cho phép người dùng kiểm tra, chỉnh sửa, chọn danh mục và xác thực form nghiêm ngặt bằng `GlobalKey<FormState>`. |
| 5 | **Local Persistence (SQLite CRUD)** | ✅ Complete | Lưu trữ giao dịch vào cơ sở dữ liệu nội bộ `sqflite: ^2.3.2`, hỗ trợ đầy đủ thêm, sửa, xóa, thống kê tổng chi tiêu theo 6 danh mục và 7 ngày qua. |
| 6 | **Custom Canvas Data Visualization** | ✅ Complete | Vẽ thuần bằng Flutter Canvas với `CustomPainter` & `AnimationController` (120Hz mượt mà): `DonutChartPainter` (cơ cấu danh mục) và `WeeklyBarChartPainter` (chi tiêu tuần). Hoàn toàn **không dùng thư viện ngoài**. |
| 7 | **Riverpod 2 State Management** | ✅ Complete | Quản lý trạng thái bất biến bằng `AsyncNotifier` (`flutter_riverpod: ^2.5.1`), an toàn tuyệt đối ở compile-time, loại bỏ lỗi runtime `ProviderNotFoundException`. |
| 8 | **Declarative Routing (GoRouter)** | ✅ Complete | Điều hướng khai báo bằng `go_router: ^13.2.0`, sử dụng `ShellRoute` để lưu giữ thanh điều hướng dưới cố định cho các tab Home và Scanner. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1 Cấu trúc thư mục (Feature-first Clean Architecture)
```
lib/
├── core/
│   ├── constants.dart        # 6 danh mục chi tiêu, màu sắc & từ điển 40+ thương hiệu Việt
│   ├── currency_format.dart  # Định dạng tiền tệ VNĐ (###.### ₫), ngày giờ tiếng Việt
│   └── theme.dart            # Thiết kế Minimalist White Theme (Material 3)
├── models/
│   ├── expense_item.dart     # Thực thể giao dịch SQLite, toMap/fromMap, copyWith
│   └── parsed_receipt.dart   # Dữ liệu có cấu trúc trích xuất từ OCR
├── services/
│   ├── database_service.dart # SQLite DB Singleton (CRUD, thống kê danh mục & tuần)
│   ├── ocr_service.dart      # Trình điều khiển Google ML Kit Text Recognition
│   └── receipt_parser.dart   # Engine giải thuật Regex Heuristic bóc tách hóa đơn
├── state/
│   ├── expense_notifier.dart # Riverpod 2 AsyncNotifier & Derived Providers
│   └── router.dart           # Cấu hình GoRouter với ShellRoute persistent tabs
├── widgets/
│   ├── charts/
│   │   ├── donut_chart.dart  # DonutChartPainter & AnimatedCategoryDonutChart
│   │   └── bar_chart.dart    # WeeklyBarChartPainter & AnimatedWeeklyBarChart
│   └── expense_card.dart     # Thẻ giao dịch (vuốt xóa Dismissible, Material 3)
├── screens/
│   ├── main_shell.dart       # Scaffold cha giữ NavigationBar cố định
│   ├── home_screen.dart      # Màn hình Dashboard, bộ lọc danh mục & tìm kiếm
│   ├── scanner_screen.dart   # Màn hình ngắm quét camera & thư viện ảnh
│   ├── review_screen.dart    # Màn hình xác thực & chỉnh sửa dữ liệu OCR
│   └── expense_detail_screen.dart # Xem chi tiết giao dịch & ảnh hóa đơn
└── main.dart                 # Điểm khởi chạy ứng dụng (ProviderScope)
```

### 3.2 Bảng quy tắc Regex bóc tách hóa đơn
| Thành phần | Biểu thức chính quy (Regex Pattern) | Ví dụ nhận diện thực tế |
|---|---|---|
| **Từ khóa Tổng tiền** | `r'(tổng\s*cộng\|tổng\s*tiền\|thanh\s*toán\|total\|amount\s*due\|phải\s*trả\|cong\s*tien)'` | `TỔNG TIỀN: 65.000 đ`, `THANH TOÁN: 86000`, `TOTAL: 190.000` |
| **Giá trị Số tiền** | `r'(?:^\|[^\d])(\d{1,3}(?:[.,]\d{3})+(?:\.\d{2})?\|\d{4,9})'` | `65.000`, `245,000`, `86000`, `150.000đ` |
| **Ngày giao dịch** | `r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b)\|(b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)'` | `22/10/2026`, `21-10-2026`, `2026-10-20` |
| **Tên cửa hàng** | Đối khớp Từ điển thương hiệu (`popularVietnameseMerchants`) + Lọc dòng tiêu đề loại trừ | Highlands Coffee, Phúc Long, Co.opmart, Xanh SM, Circle K... |

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

1. **Dashboard & Animated Charts (Màn hình chính):**
   * Hiển thị thẻ tổng chi tiêu VNĐ, bộ chuyển đổi 2 biểu đồ Custom Canvas: **Donut Chart** hiển thị tỷ trọng theo danh mục với tâm số liệu và **Weekly Bar Chart** 7 ngày với cột ngày hiện tại nổi bật.
   * Danh sách giao dịch hỗ trợ tìm kiếm theo tên và lọc theo chip danh mục, hỗ trợ vuốt sang trái để xóa (`Dismissible`).

2. **Scanner & On-Device Processing (Màn hình quét):**
   * Khung ngắm chụp hóa đơn trực quan, nút chụp Máy ảnh và chọn Thư viện ảnh.
   * Thanh tiến trình nhận diện hiển thị trạng thái xử lý On-Device ML Kit thời gian thực.

3. **Review & Verification Screen (Màn hình xác thực):**
   * Điền sẵn Tên đơn vị, Tổng tiền và Ngày giao dịch từ OCR.
   * Xác thực form theo thời gian thực (`AutovalidateMode.onUserInteraction`), kiểm tra số tiền dương, chọn chip danh mục và cho phép xem lại toàn bộ văn bản OCR thô.

4. **Expense Detail Screen (Chi tiết hóa đơn):**
   * Hiển thị đầy đủ thông tin giao dịch, ảnh chụp hóa đơn gốc và tùy chọn chỉnh sửa hoặc xóa vĩnh viễn.

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Thách thức 1: Định dạng số tiền và nhiễu ký tự trên hóa đơn Việt Nam
* **Vấn đề:** Hóa đơn tại Việt Nam rất đa dạng: có nơi dùng dấu chấm (`150.000`), có nơi dùng dấu phẩy (`150,000`), viết liền (`150000`), kèm các đuôi `đ`, `VNĐ`, `VND`. Ngoài ra, camera có thể chụp dính mã số thuế hoặc số điện thoại khiến Regex bắt nhầm.
* **Giải pháp:** Xây dựng quy trình 2 lớp trong `ReceiptParser`:
  1. Quét ngược từ dưới lên trên và ưu tiên các dòng chứa từ khóa chốt tiền (`tổng tiền`, `thanh toán`, `amount due`).
  2. Bỏ qua các dòng chứa từ khóa `MST`, `SĐT`, `TEL` trước khi trích xuất giá trị số.
  3. Làm sạch toàn bộ dấu chấm, phẩy phân cách hàng nghìn trước khi chuyển đổi sang kiểu `double`.

### Thách thức 2: Quản lý vòng đời bộ nhớ (Memory Lifecycle Safety)
* **Vấn đề:** `TextRecognizer` của Google ML Kit và `AnimationController` của Custom Canvas chiếm giữ tài nguyên bộ nhớ C++ / GPU native lớn. Nếu không hủy giải phóng khi chuyển màn hình sẽ gây rò rỉ bộ nhớ (Memory Leaks).
* **Giải pháp:** Tuân thủ nguyên tắc `dispose()` nghiêm ngặt:
  * `OcrService.dispose()` luôn gọi `_textRecognizer.close()`.
  * Toàn bộ `TextEditingController`, `FocusNode` và `AnimationController` đều được giải phóng trong phương thức `dispose()` của các State.