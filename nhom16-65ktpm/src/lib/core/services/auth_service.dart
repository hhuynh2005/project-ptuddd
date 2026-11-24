import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';

/// Dịch vụ Xác thực & Quản lý Phiên đăng nhập (Authentication Service)
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Danh sách 4 tài khoản của 4 thành viên nhóm (Seed Demo Accounts)
  static const List<UserModel> demoAccounts = [
    UserModel(
      id: 'usr_01',
      name: 'Nguyễn Văn Huỳnh',
      studentId: '2351170599',
      email: 'huynh@gooddeeds.vn',
      role: 'admin',
      password: '123',
    ),
    UserModel(
      id: 'usr_02',
      name: 'Lê Anh Tuấn',
      studentId: '2151060296',
      email: 'latuan@gooddeeds.vn',
      role: 'member',
      password: '123',
    ),
    UserModel(
      id: 'usr_03',
      name: 'Nguyễn Trung Kiên',
      studentId: '2251172394',
      email: 'kien@gooddeeds.vn',
      role: 'member',
      password: '123',
    ),
    UserModel(
      id: 'usr_04',
      name: 'Trần Anh Tuấn',
      studentId: '2351170629',
      email: 'tatuan@gooddeeds.vn',
      role: 'member',
      password: '123',
    ),
  ];

  /// Đăng nhập bằng email/MSSV và mật khẩu
  Future<bool> login(String input, String password) async {
    final cleanInput = input.trim().toLowerCase();
    for (final acc in demoAccounts) {
      if ((acc.email.toLowerCase() == cleanInput ||
              acc.studentId == cleanInput ||
              acc.name.toLowerCase().contains(cleanInput)) &&
          (acc.password == password.trim() || password.trim() == '123')) {
        _currentUser = acc;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Đăng nhập nhanh 1-chạm (Quick Login Demo cho nhóm 16)
  void quickLogin(UserModel account) {
    _currentUser = account;
    notifyListeners();
  }

  /// Đăng xuất phiên làm việc
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
