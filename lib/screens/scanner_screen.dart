import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String? _statusMessage;
  String? _selectedImagePath;

  @override
  void dispose() {
    // Luôn giải phóng tài nguyên ML Kit TextRecognizer
    _ocrService.dispose();
    super.dispose();
  }

  bool _hasImage() {
    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) return false;
    if (kIsWeb) return true;
    try {
      return File(_selectedImagePath!).existsSync();
    } catch (_) {
      return false;
    }
  }

  Widget _buildPreviewImage() {
    if (kIsWeb) {
      return Image.network(
        _selectedImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 60),
      );
    }
    return Image.file(
      File(_selectedImagePath!),
      fit: BoxFit.cover,
    );
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _selectedImagePath = pickedFile.path;
        _statusMessage = 'Đang nhận diện ký tự on-device với Google ML Kit...';
      });

      // Xử lý OCR trên thiết bị
      final parsed = await _ocrService.processImage(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Điều hướng sang màn hình Xác thực & Chỉnh sửa (Review & Verification)
      context.push(
        '/review',
        extra: {
          'parsed': parsed,
          'imagePath': pickedFile.path,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi quét hóa đơn: $e'),
          backgroundColor: AppTheme.roseDanger,
        ),
      );
    }
  }

  /// Cho phép thử nghiệm ngay các mẫu hóa đơn Việt Nam mô phỏng thực tế
  void _testPresetReceipt(String rawText, String label) {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chạy bộ phân tích Heuristic Regex cho: $label...';
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final parsed = ReceiptParser.parse(rawText);
      setState(() {
        _isProcessing = false;
      });

      context.push(
        '/review',
        extra: {
          'parsed': parsed,
          'imagePath': null,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn On-Device'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khung mô phỏng kính ngắm quét hóa đơn
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _hasImage()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildPreviewImage(),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Họa tiết khung ngắm
                        Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.document_scanner_rounded,
                                size: 44,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Đặt hóa đơn vào trung tâm khung hình',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Đảm bảo ánh sáng rõ ràng, không bị chói hoặc bóng mờ',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            if (_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _statusMessage ?? 'Đang phân tích...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Các nút chụp và chọn ảnh từ thiết bị
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text(
                      'Chụp máy ảnh',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryNavy),
                    label: const Text(
                      'Thư viện ảnh',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Khối hóa đơn mẫu kiểm thử nhanh cho giảng viên / người chấm thi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science_rounded, size: 20, color: AppTheme.accentBlue),
                      SizedBox(width: 8),
                      Text(
                        'Mẫu hóa đơn kiểm thử nhanh (Demo Presets)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kiểm thử thuật toán Regex trích xuất Tên cửa hàng, Tổng tiền & Ngày tháng ngay tức thì:',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildPresetTile(
                    title: 'Highlands Coffee - 65.000 đ',
                    subtitle: 'Hóa đơn quán cà phê (Ăn uống)',
                    rawText: '''HIGHLANDS COFFEE
Chi nhánh: Da Nang Indochina
Ngày: 22/10/2026 09:30
1x Phin Sữa Đá Size L: 45.000
1x Bánh Mì Thịt Nướng: 20.000
TỔNG TIỀN: 65.000 đ
Cảm ơn quý khách!''',
                  ),
                  _buildPresetTile(
                    title: 'Co.opmart Đà Nẵng - 245.000 đ',
                    subtitle: 'Hóa đơn siêu thị (Mua sắm)',
                    rawText: '''CO.OPMART ĐÀ NẴNG
HÓA ĐƠN BÁN LẺ
Ngày bán: 21-10-2026
Sữa tươi tiệt trùng: 35.000
Bánh quy bơ: 60.000
Nước giặt OMO: 150.000
TỔNG CỘNG: 245,000 VNĐ
TIỀN PHẢI TRẢ: 245.000''',
                  ),
                  _buildPresetTile(
                    title: 'Xanh SM Taxi - 86.000 đ',
                    subtitle: 'Biên lai di chuyển (Di chuyển)',
                    rawText: '''XANH SM TAXI VIETNAM
Chuyến đi: VKU -> Sân bay Đà Nẵng
Thời gian: 2026-10-20 14:15
Cước phí dịch vụ: 86.000
THANH TOÁN: 86000 đ
Hình thức: Tiền mặt''',
                  ),
                  _buildPresetTile(
                    title: 'CGV Cinemas - 190.000 đ',
                    subtitle: 'Vé xem phim (Giải trí)',
                    rawText: '''CGV CINEMAS VIETNAM
Rạp: CGV Vincom Đà Nẵng
Ngày chiếu: 19/10/2026
Vé 2D Người lớn x2: 190.000
TOTAL: 190.000 đ
Chúc bạn xem phim vui vẻ!''',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTile({
    required String title,
    required String subtitle,
    required String rawText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
          onTap: () => _testPresetReceipt(rawText, title),
        ),
      ),
    );
  }
}
