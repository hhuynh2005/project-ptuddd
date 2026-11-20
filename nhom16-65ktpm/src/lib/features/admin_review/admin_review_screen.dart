import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../analytics/data/mock_fund_data.dart';
import 'widgets/proof_card.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: giao diện danh sách minh chứng chờ duyệt bằng dữ liệu
// mẫu, xếp cũ nhất trước để duyệt theo thứ tự nộp.
// Commit 4: bấm vào thẻ mở hộp thoại chi tiết (OCR + số tiền).
// Xử lý Duyệt/Từ chối thuộc Commit 5.
class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({super.key});

  String _time(DateTime d) => DateFormat('dd/MM HH:mm').format(d);

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  void _showDetail(BuildContext context, MockProof proof) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(proof.challengeName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 48),
              ),
              const SizedBox(height: 12),
              Text('Thành viên: ${proof.memberName}'),
              Text('Nộp lúc: ${_time(proof.submittedAt)}'),
              Text('Tiền tài trợ: ${_money(proof.sponsorAmount)}'),
              const SizedBox(height: 8),
              Text('Ghi chú: ${proof.note}'),
              const SizedBox(height: 8),
              Chip(label: Text('OCR gợi ý: ${proof.ocrText}')),
              Text('Giờ OCR đọc được: ${proof.detectedTime}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = List.of(mockProofs)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt minh chứng')),
      body: pending.isEmpty
          ? const Center(child: Text('Chưa có minh chứng nào đang chờ duyệt.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pending.length,
              itemBuilder: (ctx, i) {
                final proof = pending[i];
                return ProofCard(
                  proof: proof,
                  timeText: _time(proof.submittedAt),
                  onTap: () => _showDetail(ctx, proof),
                );
              },
            ),
    );
  }
}
