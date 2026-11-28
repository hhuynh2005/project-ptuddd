import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'models/ocr_analysis_detail.dart';
import 'models/ocr_performance_metrics.dart';
import 'services/ocr_homework_matcher.dart';
import 'services/ocr_recognition_cache.dart';
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
    this.analysisDetail,
    this.performanceMetrics,
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

  /// Chi tiết phân tích chuyên sâu cả giờ đồng hồ và nội dung chữ trên bài làm (Sprint 3).
  final OcrAnalysisDetail? analysisDetail;

  /// Chỉ số tốc độ xử lý và trạng thái trúng bộ nhớ đệm AI OCR (Sprint 4 - Giai đoạn 1).
  final OcrPerformanceMetrics? performanceMetrics;

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
/// trên ảnh chụp minh chứng check-in, tích hợp LRU Cache và Timeout bảo vệ hiệu năng.
class MlKitOcrService {
  MlKitOcrService({
    this.script = TextRecognitionScript.latin,
    this.timeExtractor = const OcrTimeExtractor(),
    this.homeworkMatcher = const OcrHomeworkMatcher(),
    OcrRecognitionCache? recognitionCache,
    this.recognitionTimeout = const Duration(seconds: 8),
  }) : recognitionCache = recognitionCache ?? OcrRecognitionCache();

  final TextRecognitionScript script;
  final OcrTimeExtractor timeExtractor;
  final OcrHomeworkMatcher homeworkMatcher;
  final OcrRecognitionCache recognitionCache;
  final Duration recognitionTimeout;

  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: script);

  /// Nhận diện văn bản trực tiếp từ đường dẫn file ảnh bằng Google ML Kit,
  /// ưu tiên đọc từ bộ nhớ đệm LRU nếu ảnh đã được quét trước đó.
  Future<OcrScanResult> recognizeFromImagePath(
    String imagePath, {
    String? targetChallengeId,
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cacheKey = await recognitionCache.buildImageCacheKey(imagePath);

    if (!forceRefresh) {
      final cachedText = recognitionCache.get(cacheKey);
      if (cachedText != null) {
        stopwatch.stop();
        return analyzeText(
          cachedText,
          targetChallengeId: targetChallengeId,
          earlyDeadlineHour: earlyDeadlineHour,
          earlyDeadlineMinute: earlyDeadlineMinute,
          performanceMetrics: OcrPerformanceMetrics(
            processingDurationMs: stopwatch.elapsedMilliseconds,
            isFromCache: true,
          ),
        );
      }
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer
          .processImage(inputImage)
          .timeout(recognitionTimeout);
      recognitionCache.put(cacheKey, recognizedText.text);
      stopwatch.stop();

      return analyzeText(
        recognizedText.text,
        targetChallengeId: targetChallengeId,
        earlyDeadlineHour: earlyDeadlineHour,
        earlyDeadlineMinute: earlyDeadlineMinute,
        performanceMetrics: OcrPerformanceMetrics(
          processingDurationMs: stopwatch.elapsedMilliseconds,
          isFromCache: false,
        ),
      );
    } on TimeoutException {
      stopwatch.stop();
      return OcrScanResult(
        rawText: '',
        extractedTime: null,
        isEarlyWakeUpValid: false,
        detectedKeywords: const [],
        validationMessage:
            'Quá thời gian xử lý ảnh (${recognitionTimeout.inSeconds}s). Hãy chụp ảnh gần hơn hoặc giảm độ phức tạp nền.',
        performanceMetrics: OcrPerformanceMetrics(
          processingDurationMs: stopwatch.elapsedMilliseconds,
          isTimedOut: true,
        ),
      );
    }
  }

  /// Xóa kết quả lưu đệm của một tệp ảnh cụ thể khi người dùng chụp lại hoặc xóa ảnh.
  Future<void> invalidateImageCache(String imagePath) async {
    final key = await recognitionCache.buildImageCacheKey(imagePath);
    recognitionCache.invalidate(key);
  }

  /// Phân tích chi tiết văn bản OCR gồm cả giờ đồng hồ và chữ trên bài làm (Sprint 3).
  OcrAnalysisDetail analyzeDetailedText(
    String rawText, {
    String? targetChallengeId,
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
  }) {
    final normalized = rawText.trim();
    if (normalized.isEmpty) {
      return const OcrAnalysisDetail(
        rawText: '',
        confidenceScore: 0,
        isTimeValid: false,
        isContentMatched: false,
        summaryMessage:
            'Không phát hiện được chữ trên ảnh. Vui lòng chụp rõ đồng hồ hoặc nội dung bài làm.',
      );
    }

    final timeInfo = timeExtractor.extract(
      normalized,
      earlyDeadlineHour: earlyDeadlineHour,
      earlyDeadlineMinute: earlyDeadlineMinute,
    );
    final homeworkInfo = homeworkMatcher.matchHomeworkContent(
      normalized,
      targetChallengeId: targetChallengeId,
    );

    final isEarlyChallenge =
        targetChallengeId == null || targetChallengeId == 'ch_01';
    final isTimeValid = isEarlyChallenge
        ? timeInfo.isEarlyWakeUpValid
        : timeInfo.hasTime;

    var timeScore = 0;
    if (timeInfo.hasTime) {
      timeScore = isTimeValid ? 40 : 20;
    }

    final totalConfidence = (timeScore + homeworkInfo.contentScore).clamp(
      0,
      100,
    );

    final dateSuffix = timeInfo.extractedDate != null
        ? ' ngày ${timeInfo.extractedDate}'
        : '';

    final String message;
    if (!timeInfo.hasTime) {
      message =
          'Đã đọc được nội dung bài làm nhưng chưa tìm thấy mốc giờ (HH:mm) trên ảnh.';
    } else if (isEarlyChallenge && timeInfo.isEarlyWakeUpValid) {
      message =
          'Hợp lệ khung giờ dậy sớm (${timeInfo.formattedTime24h}$dateSuffix). Minh chứng đạt tiêu chuẩn sơ bộ ($totalConfidence%).';
    } else if (!isEarlyChallenge && homeworkInfo.isTargetChallengeMatched) {
      message =
          'Nhận diện giờ ${timeInfo.formattedTime24h}$dateSuffix và nội dung bài làm khớp thử thách ($totalConfidence%).';
    } else {
      message =
          'Phát hiện mốc giờ ${timeInfo.formattedTime24h}$dateSuffix (${timeInfo.periodLabel ?? 'Ngoài khung giờ'} - ngoài khung dậy sớm 04:00 - '
          '${earlyDeadlineHour.toString().padLeft(2, '0')}:${earlyDeadlineMinute.toString().padLeft(2, '0')}).';
    }

    return OcrAnalysisDetail(
      rawText: normalized,
      extractedTime: timeInfo.formattedTime24h,
      extractedDate: timeInfo.extractedDate,
      detectedPeriod: timeInfo.periodLabel,
      suggestedChallengeId: homeworkInfo.suggestedChallengeId,
      suggestedCategory: homeworkInfo.suggestedCategory,
      matchedKeywords: homeworkInfo.matchedKeywords,
      homeworkMetrics: homeworkInfo.homeworkMetrics,
      confidenceScore: totalConfidence,
      isTimeValid: isTimeValid,
      isContentMatched: homeworkInfo.isTargetChallengeMatched,
      summaryMessage: message,
    );
  }

  /// Phân tích văn bản bóc tách để tìm mốc thời gian check-in và từ khóa thử thách.
  OcrScanResult analyzeText(
    String rawText, {
    String? targetChallengeId,
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
    OcrPerformanceMetrics? performanceMetrics,
  }) {
    final stopwatch = Stopwatch()..start();
    final detail = analyzeDetailedText(
      rawText,
      targetChallengeId: targetChallengeId,
      earlyDeadlineHour: earlyDeadlineHour,
      earlyDeadlineMinute: earlyDeadlineMinute,
    );

    final timeInfo = timeExtractor.extract(
      rawText,
      earlyDeadlineHour: earlyDeadlineHour,
      earlyDeadlineMinute: earlyDeadlineMinute,
    );
    stopwatch.stop();

    return OcrScanResult(
      rawText: detail.rawText,
      extractedTime: detail.extractedTime,
      extractedDate: detail.extractedDate,
      detectedPeriod: detail.detectedPeriod,
      isEarlyWakeUpValid: timeInfo.isEarlyWakeUpValid,
      detectedKeywords: detail.matchedKeywords,
      validationMessage: detail.summaryMessage,
      analysisDetail: detail,
      performanceMetrics:
          performanceMetrics ??
          OcrPerformanceMetrics(
            processingDurationMs: stopwatch.elapsedMilliseconds,
          ),
    );
  }

  /// Tạo chuỗi tóm tắt gợi ý ngắn gọn dành cho màn hình Admin duyệt minh chứng (Sprint 3 - Giai đoạn 6).
  String buildAdminReviewHint(OcrScanResult? result) {
    if (result == null || !result.hasText) {
      return '[AI OCR: Chưa đọc được chữ - cần kiểm tra ảnh thủ công]';
    }

    final detail = result.analysisDetail;
    final score = detail?.confidenceScore ?? 0;
    final verdict = score >= 80
        ? 'Gợi ý Duyệt'
        : (score >= 50 ? 'Khớp một phần' : 'Cần kiểm tra kỹ');

    final parts = <String>[
      'AI $score% ($verdict)',
      if (result.extractedTime != null) 'Giờ: ${result.extractedTime}',
      if (detail != null && detail.homeworkMetrics.isNotEmpty)
        detail.homeworkMetrics.values.join(', '),
    ];
    return '[${parts.join(' • ')}]';
  }

  /// Giải phóng tài nguyên ML Kit và bộ nhớ đệm khi không còn sử dụng.
  Future<void> dispose() async {
    recognitionCache.clear();
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
