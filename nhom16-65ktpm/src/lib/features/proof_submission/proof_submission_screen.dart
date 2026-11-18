import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'data/mock_ocr_samples.dart';
import 'mlkit_ocr_service.dart';

/// Màn hình Nộp minh chứng & Kiểm thử AI OCR (Sprint 1: Cấu hình Camera/Gallery & mẫu ML Kit).
class ProofSubmissionScreen extends StatefulWidget {
  const ProofSubmissionScreen({super.key});

  @override
  State<ProofSubmissionScreen> createState() => _ProofSubmissionScreenState();
}

class _ProofSubmissionScreenState extends State<ProofSubmissionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final MlKitOcrService _ocrService = MlKitOcrService();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedImagePath;
  MockOcrSample _selectedSample = mockOcrSamples.first;
  OcrScanResult? _ocrResult;
  bool _isProcessing = false;
  DateTime? _capturedAt;

  @override
  void initState() {
    super.initState();
    // Khởi tạo sẵn kết quả mẫu ở Sprint 1 để thuận tiện kiểm thử nhanh.
    _runSampleOcr(_selectedSample);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndRecognizeImage(ImageSource source) async {
    setState(() => _isProcessing = true);
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final now = DateTime.now();
      OcrScanResult result;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        result = await _ocrService.recognizeFromImagePath(pickedFile.path);
      } else {
        // Trên môi trường Desktop/Web không hỗ trợ native ML Kit, dùng phân tích mẫu.
        result = _ocrService.analyzeText(_selectedSample.sampleText);
      }

      if (!mounted) return;
      setState(() {
        _selectedImagePath = pickedFile.path;
        _capturedAt = now;
        _ocrResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể truy cập Camera/Thư viện hoặc xử lý ảnh: $e'),
        ),
      );
    }
  }

  void _runSampleOcr(MockOcrSample sample) {
    final result = _ocrService.analyzeText(sample.sampleText);
    setState(() {
      _selectedSample = sample;
      _selectedImagePath = null;
      _capturedAt = DateTime.now();
      _ocrResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss - dd/MM/yyyy');
    final result = _ocrResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nộp minh chứng & AI OCR'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Khu vực chọn ảnh từ Camera hoặc Thư viện
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Chụp hoặc chọn ảnh minh chứng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hỗ trợ chụp trực tiếp từ Camera hoặc tải ảnh từ bộ nhớ thiết bị (Android / iOS).',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _pickAndRecognizeImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Chụp Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _pickAndRecognizeImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Thư viện ảnh'),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImagePath != null && !kIsWeb) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Khu vực chạy mẫu thử nghiệm Google ML Kit OCR (Sprint 1)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Mẫu thử nghiệm AI OCR (Google ML Kit)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MockOcrSample>(
                    initialValue: _selectedSample,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn kịch bản ảnh check-in mẫu',
                      border: OutlineInputBorder(),
                    ),
                    items: mockOcrSamples.map((sample) {
                      return DropdownMenuItem<MockOcrSample>(
                        value: sample,
                        child: Text(
                          '${sample.challengeTitle} (${sample.description})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (sample) {
                      if (sample != null) {
                        _runSampleOcr(sample);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Kết quả bóc tách văn bản & thời gian từ AI OCR
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.isEarlyWakeUpValid
                              ? Icons.verified
                              : Icons.info_outline,
                          color: result.isEarlyWakeUpValid
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '3. Kết quả bóc tách từ AI OCR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_capturedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Thời điểm ghi nhận: ${timeFormat.format(_capturedAt!)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    Row(
                      children: [
                        const Text(
                          'Giờ đọc trên ảnh: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Chip(
                          label: Text(
                            result.extractedTime ?? 'Chưa phát hiện',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: result.isEarlyWakeUpValid
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Văn bản nhận diện được:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.rawText.isEmpty
                            ? '(Không có văn bản)'
                            : result.rawText,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    if (result.detectedKeywords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Từ khóa thử thách phát hiện:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: result.detectedKeywords
                            .map((kw) => Chip(label: Text(kw)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: result.isEarlyWakeUpValid
                            ? Colors.green.shade50
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: result.isEarlyWakeUpValid
                              ? Colors.green.shade300
                              : Colors.amber.shade300,
                        ),
                      ),
                      child: Text(result.validationMessage),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 4. Ghi chú bổ sung của thành viên
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú minh chứng (tùy chọn)',
              hintText: 'Nhập mô tả ngắn về hoạt động thử thách vừa hoàn thành...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
