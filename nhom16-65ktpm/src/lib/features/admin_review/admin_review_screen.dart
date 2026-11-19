import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../analytics/data/mock_fund_data.dart';
import 'widgets/proof_card.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: giao diện danh sách minh chứng chờ duyệt bằng dữ liệu
// mẫu, xếp cũ nhất trước để duyệt theo thứ tự nộp.
// Xử lý Duyệt/Từ chối thuộc giai đoạn 3.
class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({super.key});

  String _time(DateTime d) => DateFormat('dd/MM HH:mm').format(d);

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
                  onTap: () {},
                );
              },
            ),
    );
  }
}
