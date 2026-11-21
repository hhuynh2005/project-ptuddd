import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/repositories/fund_repository.dart';

/// Màn hình Dashboard / Trang chủ GoodDeeds Fund
/// Phụ trách: Nguyễn Văn Huỳnh (Team Lead)
class DashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FundRepository _fundRepo = FundRepository.instance;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isLoading = true;
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  int _proofCount = 0;
  int _challengeCount = 0;

  // Mục tiêu chiến dịch thiện nguyện mùa 1
  static const double _targetFund = 100000000; // 100 triệu VNĐ

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _fundRepo.getBalance();
      final income = await _fundRepo.getTotalIncome();
      final expense = await _fundRepo.getTotalExpense();
      final proofs = await _fundRepo.getProofs();
      final challenges = await _fundRepo.getChallenges();

      if (mounted) {
        setState(() {
          _balance = balance;
          _totalIncome = income;
          _totalExpense = expense;
          _proofCount = proofs.length;
          _challengeCount = challenges.isNotEmpty ? challenges.length : 4;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Dữ liệu dự phòng nếu DB chưa khởi tạo
      if (mounted) {
        setState(() {
          _balance = 2000000;
          _totalIncome = 2000000;
          _totalExpense = 0;
          _proofCount = 3;
          _challengeCount = 4;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_balance / _targetFund).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. BANNER CHÀO MỪNG & TỔNG SỐ DƯ QUỸ
          _buildFundOverviewCard(isDark),
          const SizedBox(height: 16),

          // 2. TIẾN ĐỘ MỤC TIÊU CHIẾN DỊCH (GOAL PROGRESS)
          _buildGoalProgressCard(theme, progress, percent),
          const SizedBox(height: 16),

          // 3. THỐNG KÊ NHANH (QUICK STATS GRID)
          _buildQuickStats(theme),
          const SizedBox(height: 16),

          // 4. PHÍM TẮT THAO TÁC NHANH (QUICK ACTIONS)
          _buildQuickActions(theme),
          const SizedBox(height: 20),

          // 5. BẢNG VINH DANH THÀNH VIÊN TÍCH CỰC (LEADERBOARD)
          _buildLeaderboard(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Card tổng quan số dư quỹ và dòng tiền
  Widget _buildFundOverviewCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [AppColors.primary, const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.volunteer_activism, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Số dư Quỹ Hiện Tại',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mùa 1 - 2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Text(
                  _currencyFormat.format(_balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng Thu',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          _currencyFormat.format(_totalIncome),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.orangeAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã Giải Ngân',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          _currencyFormat.format(_totalExpense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card tiến độ mục tiêu chiến dịch thiện nguyện
  Widget _buildGoalProgressCard(
      ThemeData theme, double progress, String percent) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tiến độ Mục tiêu Chiến dịch',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đạt: ${_currencyFormat.format(_balance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Mục tiêu: ${_currencyFormat.format(_targetFund)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lưới thống kê nhanh các chỉ số hoạt động
  Widget _buildQuickStats(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.task_alt_rounded,
            color: Colors.blue,
            title: 'Thử thách',
            value: '$_challengeCount mục',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.verified_rounded,
            color: Colors.green,
            title: 'Minh chứng',
            value: '$_proofCount lượt',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.groups_rounded,
            color: Colors.purple,
            title: 'Thành viên',
            value: '4 người',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Cụm phím tắt điều hướng nhanh
  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => widget.onNavigateTab?.call(2), // Tab Nộp minh chứng
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Nộp minh chứng'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => widget.onNavigateTab?.call(3), // Tab Sổ quỹ
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
            label: const Text('Xem Sổ Quỹ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bảng vinh danh Leaderboard 4 thành viên
  Widget _buildLeaderboard(ThemeData theme) {
    final members = [
      {
        'rank': 1,
        'name': 'Nguyễn Văn Huỳnh',
        'role': 'Nhóm trưởng (2351170599)',
        'amount': 720000.0,
        'count': 15,
        'badge': '🏆',
      },
      {
        'rank': 2,
        'name': 'Lê Anh Tuấn',
        'role': 'Thành viên (2151060296)',
        'amount': 540000.0,
        'count': 12,
        'badge': '🥈',
      },
      {
        'rank': 3,
        'name': 'Nguyễn Trung Kiên',
        'role': 'Thành viên (2251172394)',
        'amount': 460000.0,
        'count': 10,
        'badge': '🥉',
      },
      {
        'rank': 4,
        'name': 'Trần Anh Tuấn',
        'role': 'Thành viên (2351170629)',
        'amount': 380000.0,
        'count': 8,
        'badge': '⭐',
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Bảng Vinh Danh Việc Tốt',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Top Nhóm 16',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final m = members[index];
                return Row(
                  children: [
                    Text(
                      m['badge'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            m['role'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${_currencyFormat.format(m['amount'])}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '${m['count']} việc tốt',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
