import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/parsed_receipt.dart';
import 'receipt_parser.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    if (isSupported) {
      _initRecognizer();
    }
  }

  /// ML Kit Text Recognition chỉ hỗ trợ native trên Android và iOS
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void _initRecognizer() {
    if (isSupported) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// Quét văn bản từ đường dẫn tệp ảnh và tự động trích xuất thông tin
  Future<ParsedReceipt> processImage(String imagePath) async {
    if (!kIsWeb) {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Không tìm thấy tệp ảnh tại đường dẫn: $imagePath');
      }
    }

    // Nếu chạy trên thiết bị Android / iOS thực tế
    if (isSupported) {
      if (_textRecognizer == null) {
        _initRecognizer();
      }
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return ReceiptParser.parse(recognizedText.text);
    }

    // Nếu chạy trên Web / Desktop (nơi ML Kit native không có driver)
    // Cung cấp kết quả mẫu mô phỏng để người dùng trải nghiệm form mà không bị crash
    const simulatedReceipt = '''HIGHLANDS COFFEE
Chi nhánh: Da Nang Indochina
Ngày: 22/10/2026 09:30
1x Phin Sữa Đá Size L: 45.000
1x Bánh Mì Thịt Nướng: 20.000
TỔNG TIỀN: 65.000 đ
Cảm ơn quý khách!''';

    return ReceiptParser.parse(simulatedReceipt);
  }

  /// Trích xuất toàn bộ văn bản thô từ ảnh
  Future<String> extractRawText(String imagePath) async {
    if (isSupported) {
      if (_textRecognizer == null) {
        _initRecognizer();
      }
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    }
    return 'Văn bản mẫu trên nền tảng Web / Desktop';
  }

  /// Giải phóng tài nguyên bộ nhớ ML Kit TextRecognizer
  void dispose() {
    if (isSupported && _textRecognizer != null) {
      try {
        _textRecognizer?.close();
      } catch (_) {}
      _textRecognizer = null;
    }
  }
}
