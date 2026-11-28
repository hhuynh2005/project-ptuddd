import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/features/proof_submission/mlkit_ocr_service.dart';
import 'package:gooddeeds_fund/features/proof_submission/models/ocr_performance_metrics.dart';
import 'package:gooddeeds_fund/features/proof_submission/services/ocr_recognition_cache.dart';

void main() {
  group('OcrRecognitionCache & OcrPerformanceMetrics Unit Tests (Sprint 4 - Stage 1)', () {
    test('OcrPerformanceMetrics phân loại đúng bậc tốc độ OcrSpeedTier', () {
      const cached = OcrPerformanceMetrics(
        processingDurationMs: 2,
        isFromCache: true,
      );
      expect(cached.speedTier, OcrSpeedTier.instantCache);
      expect(cached.isOptimal, isTrue);
      expect(cached.speedBadgeLabel, '2ms • Cache');

      const fast = OcrPerformanceMetrics(processingDurationMs: 210);
      expect(fast.speedTier, OcrSpeedTier.fast);
      expect(fast.isOptimal, isTrue);

      const moderate = OcrPerformanceMetrics(processingDurationMs: 750);
      expect(moderate.speedTier, OcrSpeedTier.moderate);
      expect(moderate.isOptimal, isFalse);

      const timedOut = OcrPerformanceMetrics(
        processingDurationMs: 8000,
        isTimedOut: true,
      );
      expect(timedOut.speedTier, OcrSpeedTier.timedOut);
      expect(timedOut.isOptimal, isFalse);
    });

    test('OcrRecognitionCache hoạt động đúng theo cơ chế LRU và tính đúng hitRate', () {
      final cache = OcrRecognitionCache(maxEntries: 2);

      expect(cache.get('img_1'), isNull);
      expect(cache.missCount, 1);

      cache.put('img_1', '05:30 AM - Bài tập 1');
      cache.put('img_2', '05:45 AM - Bài tập 2');
      expect(cache.length, 2);

      // Truy cập img_1 để đẩy img_1 lên mới nhất (LRU)
      expect(cache.get('img_1'), '05:30 AM - Bài tập 1');
      expect(cache.hitCount, 1);

      // Thêm img_3 vượt quá maxEntries=2 -> img_2 (ít dùng gần nhất) bị loại bỏ
      cache.put('img_3', '19:00 - Gia sư');
      expect(cache.length, 2);
      expect(cache.get('img_2'), isNull);
      expect(cache.get('img_1'), '05:30 AM - Bài tập 1');
      expect(cache.get('img_3'), '19:00 - Gia sư');
      expect(cache.hitRate, greaterThan(0.5));

      cache.invalidate('img_1');
      expect(cache.length, 1);

      cache.clear();
      expect(cache.length, 0);
      expect(cache.hitCount, 0);
      expect(cache.missCount, 0);
    });

    test('MlKitOcrService gắn kèm OcrPerformanceMetrics khi phân tích văn bản', () async {
      final service = MlKitOcrService();
      final result = service.analyzeText(
        '05:40 AM - Ôn tập Flutter',
        targetChallengeId: 'ch_01',
      );

      expect(result.performanceMetrics, isNotNull);
      expect(result.performanceMetrics!.processingDurationMs, greaterThanOrEqualTo(0));
      expect(result.performanceMetrics!.isTimedOut, isFalse);

      await service.dispose();
    });
  });
}
