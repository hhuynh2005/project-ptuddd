import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../analytics/data/mock_fund_data.dart';
import 'widgets/proof_card.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: danh sách minh chứng chờ duyệt bằng dữ liệu mẫu,
// xếp cũ nhất trước để duyệt theo thứ tự nộp.
// Commit 5: Duyệt/Từ chối ở mức mock — gỡ khỏi danh sách chờ
// trong bộ nhớ và báo SnackBar; lưu thật là giai đoạn sau.
// Commit 6: header tóm tắt số minh chứng + tổng tiền đang chờ.
class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late List<MockProof> _pending;

  @override
  void initState() {
    super.initState();
    _pending = List.of(mockProofs)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  String _time(DateTime d) => DateFormat('dd/MM HH:mm').format(d);

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  double get _pendingTotal =>
      _pending.fold(0, (sum, p) => sum + p.sponsorAmount);

  void _approve(MockProof proof) {
    setState(() => _pending.remove(proof));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã duyệt (mock): +${_money(proof.sponsorAmount)} vào quỹ',
        ),
      ),
    );
  }

  Future<void> _reject(MockProof proof) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối minh chứng'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối (bắt buộc)',
            hintText: 'vd: Ảnh mờ, không đọc được giờ',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần nhập lý do mới từ chối được.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _pending.remove(proof));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã từ chối (mock). Lý do: $reason')),
    );
  }

  void _showDetail(MockProof proof) {
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
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reject(proof);
            },
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approve(proof);
            },
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt minh chứng')),
      body: _pending.isEmpty
          ? const Center(child: Text('Chưa có minh chứng nào đang chờ duyệt.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang chờ duyệt: ${_pending.length} minh chứng',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng tiền tài trợ đang chờ: '
                        '${_money(_pendingTotal)}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pending.length,
                    itemBuilder: (ctx, i) {
                      final proof = _pending[i];
                      return ProofCard(
                        proof: proof,
                        timeText: _time(proof.submittedAt),
                        onTap: () => _showDetail(proof),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
