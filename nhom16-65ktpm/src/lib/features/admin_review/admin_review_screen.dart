import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/proof_model.dart';
import '../../data/repositories/fund_repository.dart';
import 'widgets/proof_card.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: giao diện + tương tác bằng dữ liệu mẫu (đã merge PR #14).
// Giai đoạn 3 – C1: nối dữ liệu thật — danh sách chờ duyệt đọc từ
// FundRepository.getPendingProofs() (SQLite) thay cho dữ liệu mẫu.
// Nút Duyệt/Từ chối nối xử lý thật ở C2 và C4; ở C1 hộp thoại chi
// tiết tạm chỉ có nút Đóng.
class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final FundRepository _repo = FundRepository.instance;

  List<ProofModel> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final proofs = await _repo.getPendingProofs();
      proofs.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
      if (!mounted) return;
      setState(() {
        _pending = proofs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách minh chứng: $e')),
      );
    }
  }

  String _time(DateTime d) => DateFormat('dd/MM HH:mm').format(d);

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  double get _pendingTotal =>
      _pending.fold(0, (sum, p) => sum + p.rewardAmount);

  void _showDetail(ProofModel proof) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(proof.challengeTitle),
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
              Text('Tiền tài trợ: ${_money(proof.rewardAmount)}'),
              const SizedBox(height: 8),
              Text('Ghi chú: ${proof.note}'),
              const SizedBox(height: 8),
              Chip(label: Text('OCR gợi ý: ${proof.ocrExtractedText}')),
              Text('Giờ OCR đọc được: ${proof.detectedTime ?? '—'}'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt minh chứng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không còn minh chứng chờ duyệt.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tất cả minh chứng đã được xử lý. Làm tốt lắm!'),
                ],
              ),
            )
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
