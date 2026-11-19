import 'package:flutter/material.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: xây dựng giao diện danh sách minh chứng chờ duyệt
// bằng dữ liệu mẫu; xử lý Duyệt/Từ chối thuộc giai đoạn 3.
class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt minh chứng')),
      body: const Center(child: Text('Chưa có minh chứng nào đang chờ duyệt.')),
    );
  }
}
