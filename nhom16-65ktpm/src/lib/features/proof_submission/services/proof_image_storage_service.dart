import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Thông tin tệp ảnh minh chứng sau khi đã được sao chép và lưu trữ vào bộ nhớ máy.
class StoredProofImage {
  const StoredProofImage({
    required this.savedPath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.savedAt,
  });

  /// Đường dẫn tuyệt đối của tệp ảnh trong bộ nhớ cục bộ của ứng dụng.
  final String savedPath;

  /// Tên tệp ảnh đã chuẩn hóa (vd: proof_1763548200000.jpg).
  final String fileName;

  /// Dung lượng tệp ảnh tính bằng byte sau khi nén.
  final int fileSizeBytes;

  /// Thời điểm lưu ảnh vào bộ nhớ máy.
  final DateTime savedAt;

  /// Hiển thị dung lượng tệp dễ đọc (KB / MB).
  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 KB';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

/// Dịch vụ quản lý lưu trữ tệp ảnh minh chứng cục bộ an toàn (Sprint 2).
class ProofImageStorageService {
  const ProofImageStorageService();

  static const String _proofFolderName = 'proof_images';

  /// Lấy thư mục lưu trữ ảnh minh chứng riêng của ứng dụng trên bộ nhớ thiết bị.
  Future<Directory> getProofStorageDirectory() async {
    String baseDirPath;
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dbPath = await getDatabasesPath();
        baseDirPath = p.dirname(dbPath);
      } else {
        baseDirPath = Directory.systemTemp.path;
      }
    } catch (_) {
      baseDirPath = Directory.systemTemp.path;
    }

    final proofDir = Directory(p.join(baseDirPath, _proofFolderName));
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }
    return proofDir;
  }

  /// Sao chép ảnh từ đường dẫn tạm của Camera/Gallery vào bộ nhớ lưu trữ lâu dài của máy.
  Future<StoredProofImage> saveImageToLocalStorage(
    String sourcePath, {
    String? challengeId,
  }) async {
    final now = DateTime.now();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final prefix = (challengeId != null && challengeId.isNotEmpty)
        ? 'proof_${challengeId}_'
        : 'proof_';
    final fileName = '$prefix${now.millisecondsSinceEpoch}$ext';

    if (kIsWeb) {
      return StoredProofImage(
        savedPath: sourcePath,
        fileName: fileName,
        fileSizeBytes: 0,
        savedAt: now,
      );
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Không tìm thấy tệp ảnh gốc để lưu trữ',
        sourcePath,
      );
    }

    final storageDir = await getProofStorageDirectory();
    final destinationPath = p.join(storageDir.path, fileName);
    final savedFile = await sourceFile.copy(destinationPath);
    final sizeBytes = await savedFile.length();

    return StoredProofImage(
      savedPath: savedFile.path,
      fileName: fileName,
      fileSizeBytes: sizeBytes,
      savedAt: now,
    );
  }

  /// Xóa tệp ảnh minh chứng đã lưu khỏi bộ nhớ máy (khi người dùng chọn chụp lại).
  Future<bool> deleteStoredImage(String? savedPath) async {
    if (savedPath == null || savedPath.isEmpty || kIsWeb) return false;
    try {
      final file = File(savedPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
