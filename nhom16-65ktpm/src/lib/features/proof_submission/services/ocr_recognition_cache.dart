import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Bộ nhớ đệm LRU (Least Recently Used) lưu văn bản nhận diện được từ tệp ảnh (Sprint 4 - Giai đoạn 1).
/// Giúp tăng tốc độ phản hồi tức thì khi người dùng chuyển đổi thử thách hoặc kiểm tra lại cùng một ảnh
/// mà không phải khởi chạy lại mô hình Google ML Kit trên thiết bị.
class OcrRecognitionCache {
  OcrRecognitionCache({this.maxEntries = 20})
    : assert(maxEntries > 0, 'maxEntries phải lớn hơn 0');

  /// Số lượng bản ghi ảnh tối đa lưu giữ trong bộ nhớ đệm.
  final int maxEntries;

  final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();

  int _hitCount = 0;
  int _missCount = 0;

  int get length => _cache.length;
  int get hitCount => _hitCount;
  int get missCount => _missCount;

  /// Tỷ lệ truy xuất trúng bộ nhớ đệm (0.0 - 1.0).
  double get hitRate {
    final total = _hitCount + _missCount;
    if (total == 0) return 0.0;
    return _hitCount / total;
  }

  /// Tạo khóa định danh duy nhất cho tệp ảnh dựa trên đường dẫn và kích thước tệp.
  Future<String> buildImageCacheKey(String imagePath) async {
    final trimmed = imagePath.trim();
    if (trimmed.isEmpty || kIsWeb) return trimmed;
    try {
      final file = File(trimmed);
      if (await file.exists()) {
        final stat = await file.stat();
        return '$trimmed|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
      }
    } catch (_) {
      // Nếu không đọc được metadata của file, fallback về đường dẫn.
    }
    return trimmed;
  }

  /// Truy xuất văn bản OCR đã lưu theo [cacheKey]. Cập nhật thứ tự sử dụng gần nhất (LRU).
  String? get(String cacheKey) {
    if (!_cache.containsKey(cacheKey)) {
      _missCount++;
      return null;
    }
    final value = _cache.remove(cacheKey)!;
    _cache[cacheKey] = value;
    _hitCount++;
    return value;
  }

  /// Lưu văn bản OCR mới vào bộ nhớ đệm. Tự động loại bỏ phần tử cũ nhất nếu vượt [maxEntries].
  void put(String cacheKey, String recognizedText) {
    if (cacheKey.isEmpty) return;
    if (_cache.containsKey(cacheKey)) {
      _cache.remove(cacheKey);
    } else if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = recognizedText;
  }

  /// Xóa một khóa cụ thể khỏi bộ nhớ đệm (ví dụ khi người dùng xóa ảnh).
  void invalidate(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// Giải phóng toàn bộ bộ nhớ đệm và đặt lại bộ đếm thống kê.
  void clear() {
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }
}
