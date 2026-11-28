/// Phân loại mức tốc độ xử lý nhận diện ảnh của AI OCR (Sprint 4 - Giai đoạn 1).
enum OcrSpeedTier {
  instantCache,
  fast,
  moderate,
  slow,
  timedOut,
}

/// Model lưu trữ chỉ số hiệu năng và tốc độ nhận diện văn bản của AI OCR (Sprint 4 - Giai đoạn 1).
class OcrPerformanceMetrics {
  const OcrPerformanceMetrics({
    required this.processingDurationMs,
    this.isFromCache = false,
    this.isTimedOut = false,
  });

  /// Thời gian thực thi nhận diện và phân tích văn bản (đơn vị: mili-giây).
  final int processingDurationMs;

  /// Đánh dấu kết quả được lấy tức thì từ bộ nhớ đệm LRU mà không cần quét lại ảnh.
  final bool isFromCache;

  /// Đánh dấu quá trình nhận diện bị vượt ngưỡng thời gian chờ tối đa (timeout).
  final bool isTimedOut;

  /// Phân loại bậc tốc độ xử lý để hiển thị phản hồi hiệu năng trên giao diện.
  OcrSpeedTier get speedTier {
    if (isTimedOut) return OcrSpeedTier.timedOut;
    if (isFromCache) return OcrSpeedTier.instantCache;
    if (processingDurationMs <= 400) return OcrSpeedTier.fast;
    if (processingDurationMs <= 1200) return OcrSpeedTier.moderate;
    return OcrSpeedTier.slow;
  }

  /// Kiểm tra tốc độ xử lý có đạt mức tối ưu (trúng cache hoặc dưới 400ms) hay không.
  bool get isOptimal =>
      !isTimedOut && (isFromCache || processingDurationMs <= 400);

  /// Nhãn hiển thị ngắn gọn trên giao diện người dùng.
  String get speedBadgeLabel {
    switch (speedTier) {
      case OcrSpeedTier.timedOut:
        return 'Quá thời gian chờ (${processingDurationMs}ms)';
      case OcrSpeedTier.instantCache:
        return '${processingDurationMs}ms • Cache';
      case OcrSpeedTier.fast:
        return '${processingDurationMs}ms • Nhanh';
      case OcrSpeedTier.moderate:
        return '${processingDurationMs}ms • Ổn định';
      case OcrSpeedTier.slow:
        return '${processingDurationMs}ms • Ảnh nặng';
    }
  }
}
