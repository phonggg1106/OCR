import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/parsed_receipt.dart';
import 'receipt_parser.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    _initRecognizer();
  }

  void _initRecognizer() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Quét văn bản từ đường dẫn tệp ảnh và tự động trích xuất thông tin
  Future<ParsedReceipt> processImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Không tìm thấy tệp ảnh tại đường dẫn: $imagePath');
    }

    if (_textRecognizer == null) {
      _initRecognizer();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer!.processImage(inputImage);

    // Phân tích văn bản OCR bằng ReceiptParser
    return ReceiptParser.parse(recognizedText.text);
  }

  /// Trích xuất toàn bộ văn bản thô từ ảnh
  Future<String> extractRawText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return '';
    }

    if (_textRecognizer == null) {
      _initRecognizer();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer!.processImage(inputImage);
    return recognizedText.text;
  }

  /// Giải phóng tài nguyên bộ nhớ ML Kit TextRecognizer
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
