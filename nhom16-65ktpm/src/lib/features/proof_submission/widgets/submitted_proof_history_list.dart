import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/proof_model.dart';

/// Widget hiển thị danh sách minh chứng vừa nộp và lưu trong bộ nhớ máy (Sprint 2).
class SubmittedProofHistoryList extends StatelessWidget {
  const SubmittedProofHistoryList({
    super.key,
    required this.proofs,
  });

  final List<ProofModel> proofs;

  String _formatCurrency(double amount) =>
      '${NumberFormat.decimalPattern('vi_VN').format(amount.round())} đ';

  (String, Color) _statusBadge(ProofStatus status) {
    switch (status) {
      case ProofStatus.approved:
        return ('Đã duyệt', Colors.green);
      case ProofStatus.rejected:
        return ('Từ chối', Colors.red);
      case ProofStatus.pending:
        return ('Chờ duyệt', Colors.orange);
    }
  }

  Widget _buildLeadingThumbnail(ProofModel proof) {
    if (!kIsWeb &&
        proof.imagePath.isNotEmpty &&
        !proof.imagePath.startsWith('mock://')) {
      final file = File(proof.imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: Colors.deepPurple.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minh chứng đã lưu trên máy (${proofs.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (proofs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có minh chứng nào được lưu. Hãy chụp ảnh và nhấn Gửi minh chứng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: proofs.length,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = proofs[index];
                  final (statusText, statusColor) = _statusBadge(item.status);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeadingThumbnail(item),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.challengeTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Người nộp: ${item.memberName} • Tài trợ: ${_formatCurrency(item.rewardAmount)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Nộp lúc: ${dateFormat.format(item.submittedAt)}'
                              '${item.detectedTime != null ? ' • Giờ OCR: ${item.detectedTime}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (item.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Ghi chú: ${item.note}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Tệp ảnh: ${item.imagePath}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
