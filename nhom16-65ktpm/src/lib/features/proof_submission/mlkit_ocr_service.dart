import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Kết quả bóc tách văn bản và xác thực sơ bộ từ ảnh minh chứng.
class OcrScanResult {
  const OcrScanResult({
    required this.rawText,
    required this.extractedTime,
    required this.isEarlyWakeUpValid,
    required this.detectedKeywords,
    required this.validationMessage,
  });

  /// Toàn bộ văn bản nhận diện được trên ảnh.
  final String rawText;

  /// Mốc giờ trích xuất được từ ảnh (định dạng HH:mm), null nếu không tìm thấy.
  final String? extractedTime;

  /// Kết quả kiểm tra khung giờ dậy sớm hợp lệ (04:00 - 06:00 sáng).
  final bool isEarlyWakeUpValid;

  /// Các từ khóa liên quan đến thử thách phát hiện trong ảnh.
  final List<String> detectedKeywords;

  /// Thông điệp gợi ý sơ bộ từ AI cho người nộp và Admin.
  final String validationMessage;

  bool get hasText => rawText.trim().isNotEmpty;
}

/// Dịch vụ AI OCR sử dụng Google ML Kit Text Recognition để đọc chữ và thời gian
/// trên ảnh chụp minh chứng check-in.
class MlKitOcrService {
  MlKitOcrService({TextRecognitionScript script = TextRecognitionScript.latin})
    : _textRecognizer = TextRecognizer(script: script);

  final TextRecognizer _textRecognizer;

  static final RegExp _timePattern = RegExp(
    r'\b([01]?\d|2[0-3])[:hH]([0-5]\d)\b',
  );

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

    final match = _timePattern.firstMatch(normalized);
    String? formattedTime;
    var isEarlyValid = false;

    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      formattedTime =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final totalMinutes = hour * 60 + minute;
      final minEarlyMinutes = 4 * 60; // Từ 04:00 sáng
      final maxEarlyMinutes = earlyDeadlineHour * 60 + earlyDeadlineMinute;
      isEarlyValid =
          totalMinutes >= minEarlyMinutes && totalMinutes <= maxEarlyMinutes;
    }

    final lowerText = normalized.toLowerCase();
    final foundKeywords = _challengeKeywords
        .where((kw) => lowerText.contains(kw))
        .toList();

    final String message;
    if (formattedTime == null) {
      message =
          'Đã đọc được nội dung chữ nhưng chưa tìm thấy mốc giờ (HH:mm) trên ảnh.';
    } else if (isEarlyValid) {
      message =
          'Hợp lệ khung giờ dậy sớm ($formattedTime). Minh chứng đạt tiêu chuẩn sơ bộ.';
    } else {
      message =
          'Phát hiện mốc giờ $formattedTime (ngoài khung dậy sớm 04:00 - '
          '${earlyDeadlineHour.toString().padLeft(2, '0')}:${earlyDeadlineMinute.toString().padLeft(2, '0')}).';
    }

    return OcrScanResult(
      rawText: normalized,
      extractedTime: formattedTime,
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
