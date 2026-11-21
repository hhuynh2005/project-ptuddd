import 'package:flutter/material.dart';

import '../../analytics/data/mock_fund_data.dart';

// Một thẻ minh chứng trong danh sách chờ duyệt.
// Chỉ hiển thị đúng những gì Commit 2 đã có: tên thử thách,
// tên người nộp + giờ nộp. OCR và số tiền thêm ở Commit 4.
class ProofCard extends StatelessWidget {
  const ProofCard({
    super.key,
    required this.proof,
    required this.timeText,
    required this.onTap,
  });

  final MockProof proof;
  final String timeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(proof.memberName.isNotEmpty ? proof.memberName[0] : '?'),
        ),
        title: Text(proof.challengeName),
        subtitle: Text('${proof.memberName} • $timeText'),
        onTap: onTap,
      ),
    );
  }
}
