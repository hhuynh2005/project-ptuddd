import 'package:flutter/material.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/proof_submission/proof_submission_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

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

  List<Widget> get _screens => [
        _buildDashboardPlaceholder(),
        _buildChallengesPlaceholder(),
        const ProofSubmissionScreen(),
        _buildFundLedgerPlaceholder(),
        const AnalyticsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Chuyển chế độ sáng' : 'Chuyển chế độ tối',
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: AppStrings.navDashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: AppStrings.navChallenges,
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: AppStrings.navProof,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: AppStrings.navLedger,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: AppStrings.navAnalytics,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPlaceholder() {
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
              child: const Icon(Icons.dashboard_customize_rounded, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Trang Tổng Quan Quỹ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Huỳnh đang hoàn thiện chi tiết Dashboard ở Task tiếp theo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Thử chức năng Nộp minh chứng (Kiên)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 4),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Xem biểu đồ fl_chart (Anh Tuấn)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_rounded, size: 56, color: Colors.amber.shade700),
            const SizedBox(height: 16),
            const Text(
              'Danh Mục Thử Thách Việc Tốt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dậy sớm trước 6h00 • Gia sư trẻ em • Toán tư duy • Chạy bộ 3km',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundLedgerPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.savings_rounded, size: 56, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Sổ Quỹ Thu - Chi Từ Thiện (SQLite)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tầng dữ liệu DatabaseHelper và FundRepository của Lê Anh Tuấn đã sẵn sàng kết nối.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
