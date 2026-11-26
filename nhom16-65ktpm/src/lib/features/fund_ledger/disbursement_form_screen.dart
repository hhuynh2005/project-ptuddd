import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/fund_transaction_model.dart';
import '../../data/repositories/fund_repository.dart';

/// Màn hình Lập Phiếu Chi Giải Ngân Từ Thiện (Disbursement Form Screen)
/// Cho phép Thủ quỹ / Quản trị viên lập lệnh chi tiền minh bạch kèm chứng từ sao kê
class DisbursementFormScreen extends StatefulWidget {
  final double currentBalance;

  const DisbursementFormScreen({
    super.key,
    required this.currentBalance,
  });

  @override
  State<DisbursementFormScreen> createState() => _DisbursementFormScreenState();
}

class _DisbursementFormScreenState extends State<DisbursementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _categories = [
    'Hỗ trợ giáo dục & Trường học',
    'Cứu trợ thiên tai & Khẩn cấp',
    'Hỗ trợ y tế & Viện phí',
    'Chăm sóc trẻ em có hoàn cảnh khó khăn',
    'Bữa ăn tình thương & Thực phẩm',
    'Hoạt động thiện nguyện cộng đồng',
    'Khác',
  ];

  late String _selectedCategory;
  String? _selectedImagePath;
  bool _isSubmitting = false;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toInt().toString();
  }

  Future<void> _submitDisbursement() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0đ'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Số tiền chi (${currencyFormatter.format(amount)}) vượt quá số dư quỹ hiện có (${currencyFormatter.format(widget.currentBalance)})!',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Xác nhận trước khi ghi nhận chi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 28),
            SizedBox(width: 10),
            Text('Xác nhận giải ngân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn lập phiếu chi giải ngân với thông tin sau?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Mục đích: ${_titleController.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• Số tiền chi: ${currencyFormatter.format(amount)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• Thụ hưởng: ${_recipientController.text.trim()}'),
                  const SizedBox(height: 4),
                  Text('• Danh mục: $_selectedCategory'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ bỏ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý giải ngân'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final tx = FundTransactionModel(
        id: 'tx_exp_${now.millisecondsSinceEpoch}',
        type: TransactionType.chi,
        amount: amount,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        proofImagePath: _selectedImagePath,
        note: _noteController.text.trim(),
        recipientOrSponsor: _recipientController.text.trim(),
        createdAt: now,
      );

      await FundRepository.instance.recordTransaction(tx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lập phiếu chi thành công: -${currencyFormatter.format(amount)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi ghi nhận phiếu chi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập Phiếu Chi Giải Ngân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ thông tin số dư hiện có
              _buildBalanceSummaryCard(isDark),

              const SizedBox(height: 20),

              // Trường 1: Tiêu đề khoản chi
              const Text(
                'Mục đích chi giải ngân *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'VD: Mua 50 bộ sách giáo khoa tặng học sinh nghèo',
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập mục đích chi';
                  }
                  if (val.trim().length < 5) {
                    return 'Mục đích chi cần tối thiểu 5 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Trường 2: Số tiền chi
              const Text(
                'Số tiền giải ngân (VNĐ) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền (VD: 500000)',
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.danger),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền chi';
                  }
                  final amount = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount == null || amount <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  if (amount > widget.currentBalance) {
                    return 'Vượt quá số dư quỹ hiện có';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Gợi ý chọn số tiền nhanh
              _buildQuickAmountChips(),

              const SizedBox(height: 16),

              // Trường 3: Danh mục chi
              const Text(
                'Danh mục giải ngân *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Trường 4: Người / Đơn vị thụ hưởng
              const Text(
                'Đơn vị / Người thụ hưởng *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  hintText: 'VD: Điểm trường Tiểu học Nậm Cần / Bà con vùng lũ',
                  prefixIcon: const Icon(Icons.handshake_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập đơn vị hoặc người thụ hưởng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Trường 5: Ghi chú diễn giải
              const Text(
                'Ghi chú / Chi tiết sử dụng quỹ (tuỳ chọn)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập thông tin chi tiết về đợt giải ngân, địa điểm bàn giao, cam kết sử dụng...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Trường 6: Đính kèm ảnh chứng từ chuyển khoản
              const Text(
                'Đính kèm ảnh chứng từ / Uỷ nhiệm chi / Sao kê',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Minh bạch là tôn chỉ của GoodDeeds Fund. Vui lòng đính kèm ảnh hoá đơn hoặc uỷ nhiệm chi.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildProofImagePicker(isDark),

              const SizedBox(height: 28),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitDisbursement,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSubmitting ? 'Đang ghi nhận...' : 'Xác Nhận Lập Phiếu Chi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư quỹ khả dụng hiện tại',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormatter.format(widget.currentBalance),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    final chips = [
      100000.0,
      200000.0,
      500000.0,
      1000000.0,
      widget.currentBalance,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips.where((amt) => amt > 0 && amt <= widget.currentBalance).map((amt) {
        final isMax = amt == widget.currentBalance;
        final label = isMax ? 'Toàn bộ số dư' : currencyFormatter.format(amt);

        return ActionChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          backgroundColor: isMax ? AppColors.accentLight : null,
          onPressed: () => _selectQuickAmount(amt),
        );
      }).toList(),
    );
  }

  Widget _buildProofImagePicker(bool isDark) {
    if (_selectedImagePath != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              _buildSelectedImagePreview(),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() => _selectedImagePath = null);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            label: const Text('Chọn từ thư viện'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            label: const Text('Chụp ảnh mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    if (_selectedImagePath == null) return const SizedBox.shrink();

    if (!kIsWeb) {
      final file = File(_selectedImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.network(
      _selectedImagePath!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 180,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.image_rounded, size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}
