import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'services/ocr_time_extractor.dart';

/// Kết quả bóc tách văn bản và xác thực sơ bộ từ ảnh minh chứng.
class OcrScanResult {
  const OcrScanResult({
    required this.rawText,
    required this.extractedTime,
    this.extractedDate,
    this.detectedPeriod,
    required this.isEarlyWakeUpValid,
    required this.detectedKeywords,
    required this.validationMessage,
  });

  /// Toàn bộ văn bản nhận diện được trên ảnh.
  final String rawText;

  /// Mốc giờ trích xuất được từ ảnh (định dạng HH:mm), null nếu không tìm thấy.
  final String? extractedTime;

  /// Ngày tháng trích xuất được trên ảnh (định dạng dd/MM/yyyy), null nếu không tìm thấy.
  final String? extractedDate;

  /// Nhãn buổi trong ngày suy luận từ giờ đồng hồ ('Sáng sớm', 'Buổi sáng', 'Buổi chiều', 'Buổi tối').
  final String? detectedPeriod;

  /// Kết quả kiểm tra khung giờ dậy sớm hợp lệ (04:00 - 06:00 sáng).
  final bool isEarlyWakeUpValid;

  /// Các từ khóa liên quan đến thử thách phát hiện trong ảnh.
  final List<String> detectedKeywords;

  /// Thông điệp gợi ý sơ bộ từ AI cho người nộp và Admin.
  final String validationMessage;

  bool get hasText => rawText.trim().isNotEmpty;

  /// Nhãn tóm tắt trạng thái kiểm tra sơ bộ từ AI OCR.
  String get statusLabel {
    if (!hasText) return 'Chưa có văn bản';
    if (isEarlyWakeUpValid) return 'Đạt chuẩn giờ dậy sớm';
    if (extractedTime != null) return 'Đã nhận diện giờ ($extractedTime)';
    return 'Cần kiểm tra thủ công';
  }
}

/// Dịch vụ AI OCR sử dụng Google ML Kit Text Recognition để đọc chữ và thời gian
/// trên ảnh chụp minh chứng check-in.
class MlKitOcrService {
  MlKitOcrService({
    TextRecognitionScript script = TextRecognitionScript.latin,
    this.timeExtractor = const OcrTimeExtractor(),
  }) : _textRecognizer = TextRecognizer(script: script);

  final TextRecognizer _textRecognizer;
  final OcrTimeExtractor timeExtractor;

  static const List<String> _challengeKeywords = [
    'flutter',
    'lập trình',
    'toán',
    'gia sư',
    'bài tập',
    'học bài',
    'tình thương',
    'thử thách',
    'check-in',
    'strava',
    'km',
    'thuật toán',
  ];

  /// Nhận diện văn bản trực tiếp từ đường dẫn file ảnh bằng Google ML Kit.
  Future<OcrScanResult> recognizeFromImagePath(
    String imagePath, {
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return analyzeText(
      recognizedText.text,
      earlyDeadlineHour: earlyDeadlineHour,
      earlyDeadlineMinute: earlyDeadlineMinute,
    );
  }

  /// Phân tích văn bản bóc tách để tìm mốc thời gian check-in và từ khóa thử thách.
  OcrScanResult analyzeText(
    String rawText, {
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
  }) {
    final normalized = rawText.trim();
    if (normalized.isEmpty) {
      return const OcrScanResult(
        rawText: '',
        extractedTime: null,
        isEarlyWakeUpValid: false,
        detectedKeywords: [],
        validationMessage:
            'Không phát hiện được chữ trên ảnh. Vui lòng chụp rõ đồng hồ hoặc nội dung bài làm.',
      );
    }

    final timeInfo = timeExtractor.extract(
      normalized,
      earlyDeadlineHour: earlyDeadlineHour,
      earlyDeadlineMinute: earlyDeadlineMinute,
    );
    final formattedTime = timeInfo.formattedTime24h;
    final isEarlyValid = timeInfo.isEarlyWakeUpValid;

    final lowerText = normalized.toLowerCase();
    final foundKeywords = _challengeKeywords
        .where((kw) => lowerText.contains(kw))
        .toList();

    final dateSuffix = timeInfo.extractedDate != null
        ? ' ngày ${timeInfo.extractedDate}'
        : '';

    final String message;
    if (formattedTime == null) {
      message =
          'Đã đọc được nội dung chữ nhưng chưa tìm thấy mốc giờ (HH:mm) trên ảnh.';
    } else if (isEarlyValid) {
      message =
          'Hợp lệ khung giờ dậy sớm ($formattedTime$dateSuffix). Minh chứng đạt tiêu chuẩn sơ bộ.';
    } else {
      message =
          'Phát hiện mốc giờ $formattedTime$dateSuffix (${timeInfo.periodLabel ?? 'Ngoài khung giờ'} - ngoài khung dậy sớm 04:00 - '
          '${earlyDeadlineHour.toString().padLeft(2, '0')}:${earlyDeadlineMinute.toString().padLeft(2, '0')}).';
    }

    return OcrScanResult(
      rawText: normalized,
      extractedTime: formattedTime,
      extractedDate: timeInfo.extractedDate,
      detectedPeriod: timeInfo.periodLabel,
      isEarlyWakeUpValid: isEarlyValid,
      detectedKeywords: foundKeywords,
      validationMessage: message,
    );
  }

  /// Giải phóng tài nguyên ML Kit khi không còn sử dụng.
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
