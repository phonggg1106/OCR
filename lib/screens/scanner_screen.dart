import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/ocr_service.dart';

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

            const SizedBox(height: 28),

            // Khối hướng dẫn chụp hóa đơn chuẩn AI
            Container(
              padding: const EdgeInsets.all(20),
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
                      Icon(Icons.tips_and_updates_outlined, size: 20, color: AppTheme.primaryNavy),
                      SizedBox(width: 8),
                      Text(
                        'Mẹo chụp & quét hóa đơn rõ nét',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTipRow(
                    Icons.crop_free_rounded,
                    'Căn chỉnh hóa đơn phẳng phiu nằm trọn trong khung ngắm.',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.wb_sunny_outlined,
                    'Đảm bảo đủ ánh sáng, tránh bóng tay che mất dòng Tổng tiền.',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.document_scanner_outlined,
                    'Giữ máy ảnh thẳng góc và không bị rung tay khi chụp.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.accentBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
