import 'package:flutter/material.dart';

import '../../data/repositories/fund_repository.dart';
import '../../features/admin_review/admin_review_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/chatbot/chatbot_sheet.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/proof_submission/proof_submission_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Màn hình điều hướng trung tâm MainNavigationScreen chuẩn Senior Product Designer
/// - BottomNavigationBar 5 tabs với nút FAB tròn cam ấm nổi ở giữa cho Nộp minh chứng
/// - AppBar tích hợp nút Kiểm duyệt Admin kèm Badge số lượng chờ duyệt (Admin Review)
/// - Kết nối trực tiếp DashboardScreen thực tế từ FundRepository
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _pendingProofsCount = 0;
  final FundRepository _fundRepo = FundRepository.instance;

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
  }

  Future<void> _fetchPendingCount() async {
    try {
      final pending = await _fundRepo.getPendingProofs();
      if (mounted) {
        setState(() {
          _pendingProofsCount = pending.length;
        });
      }
    } catch (_) {
      // Dữ liệu dự phòng
      if (mounted) {
        setState(() {
          _pendingProofsCount = 3;
        });
      }
    }
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _fetchPendingCount();
    }
  }

  Future<void> _openAdminReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminReviewScreen()),
    );
    _fetchPendingCount();
  }

  List<Widget> get _screens => [
        DashboardScreen(onNavigateTab: _onSelectTab),
        _buildChallengesView(),
        const ProofSubmissionScreen(),
        _buildFundLedgerView(),
        const AnalyticsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Quỹ việc tốt thanh niên',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // NÚT TRỢ LÝ HỎI ĐÁP AI CHATBOT
          IconButton(
            tooltip: 'Trợ lý AI Hỏi Đáp GoodDeeds',
            icon: const Icon(Icons.smart_toy_rounded),
            color: AppColors.primary,
            onPressed: () => ChatbotSheet.show(context),
          ),

          // NÚT KIỂM DUYỆT ADMIN KÈM BADGE SỐ LƯỢNG CHỜ DUYỆT (Trần Anh Tuấn)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Kiểm duyệt minh chứng (Admin)',
                icon: const Icon(Icons.admin_panel_settings_rounded),
                color: AppColors.primary,
                onPressed: _openAdminReview,
              ),
              if (_pendingProofsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_pendingProofsCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // NÚT CHUYỂN CHẾ ĐỘ SÁNG / TỐI
          IconButton(
            tooltip: isDark ? 'Chuyển chế độ sáng' : 'Chuyển chế độ tối',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // NÚT FAB TRÒN NỔI Ở GIỮA MÀU CAM ẤM CHO NỘP MINH CHỨNG
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nộp minh chứng việc tốt (Camera/AI)',
        elevation: 4,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _onSelectTab(2),
        child: const Icon(Icons.photo_camera_rounded, size: 28),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onSelectTab,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_flags_outlined),
            selectedIcon: Icon(Icons.emoji_flags_rounded),
            label: 'Thử thách',
          ),
          NavigationDestination(
            icon: SizedBox(height: 24), // Chỗ trống cho FAB ở giữa
            label: 'Nộp ảnh',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Sổ Quỹ',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }

  /// Tab Thử thách việc tốt
  Widget _buildChallengesView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh Mục Thử Thách',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _onSelectTab(2),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tham gia'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildChallengeCardItem(
          title: 'Dậy sớm trước 6:00 sáng học bài',
          desc: 'Chụp ảnh bàn học kèm đồng hồ rõ mốc thời gian.',
          reward: '+20.000 đ',
          category: 'Kỷ luật',
          icon: Icons.alarm_rounded,
          color: Colors.amber.shade800,
        ),
        _buildChallengeCardItem(
          title: 'Gia sư dạy học cho trẻ em vùng cao',
          desc: 'Dạy học 1 buổi toán, tiếng Việt hoặc kỹ năng sống.',
          reward: '+50.000 đ',
          category: 'Cộng đồng',
          icon: Icons.school_rounded,
          color: AppColors.primary,
        ),
        _buildChallengeCardItem(
          title: 'Giải 5 bài toán tư duy / code thuật toán',
          desc: 'Rèn luyện tư duy logic trên LeetCode/HackerRank.',
          reward: '+30.000 đ',
          category: 'Học tập',
          icon: Icons.psychology_rounded,
          color: Colors.purple,
        ),
        _buildChallengeCardItem(
          title: 'Chạy bộ 3km hoặc thể thao nâng cao sức khỏe',
          desc: 'Chụp ảnh màn hình ứng dụng Strava / Smartwatch.',
          reward: '+25.000 đ',
          category: 'Sức khỏe',
          icon: Icons.directions_run_rounded,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildChallengeCardItem({
    required String title,
    required String desc,
    required String reward,
    required String category,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reward,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  /// Tab Sổ Quỹ Thu - Chi
  Widget _buildFundLedgerView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sổ Quỹ Thu - Chi Minh Bạch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toàn bộ lịch sử tài trợ và giải ngân được bảo vệ bằng SQLite CSDL cục bộ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _onSelectTab(4),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Xem Biểu Đồ Phân Tích (fl_chart)'),
            ),
          ],
        ),
      ),
    );
  }
}
