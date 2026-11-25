import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình Cài đặt của Thống kê (Giai đoạn 4 - C7).
/// Mở từ nút bánh răng trên AppBar của AnalyticsScreen.
/// Hiện có: đổi mục tiêu quỹ (lưu bằng SharedPreferences) + giới thiệu.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.currentGoal});

  /// Mục tiêu quỹ hiện tại (đ), dùng làm giá trị mặc định của ô nhập.
  final double currentGoal;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.currentGoal.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final digits = _goalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = double.tryParse(digits);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số tiền mục tiêu lớn hơn 0.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fund_goal', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu mục tiêu quỹ.')));
    Navigator.pop(context, true);
  }

  Widget _memberTile(String initials, String name, String role) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text(initials),
      ),
      title: Text(name),
      subtitle: Text(role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mục tiêu quỹ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền mục tiêu (đ)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveGoal,
            icon: const Icon(Icons.save),
            label: const Text('Lưu mục tiêu'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giới thiệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 30,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GoodDeeds Fund',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Quản lý Thử thách Việc Tốt & Quỹ Từ Thiện'),
                        SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Đội ngũ phát triển — Nhóm 16 · Lớp 65KTPM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _memberTile('H', 'Nguyễn Văn Huỳnh', 'Trưởng nhóm'),
                _memberTile('TT', 'Trần Anh Tuấn', 'Thống kê & Kiểm duyệt'),
                _memberTile('K', 'Nguyễn Trung Kiên', 'Nộp minh chứng & OCR'),
                _memberTile('LT', 'Lê Anh Tuấn', 'Sổ Quỹ & Cơ sở dữ liệu'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
