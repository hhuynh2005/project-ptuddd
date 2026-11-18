/// Model cho bảng `challenges`
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final double rewardAmount;
  final String category; // vd: 'Học tập', 'Gia sư', 'Sức khỏe', 'Môi trường'
  final String icon;
  final bool isActive;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardAmount,
    required this.category,
    required this.icon,
    this.isActive = true,
  });

  /// Chuyển đối tượng thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'category': category,
      'icon': icon,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Khởi tạo đối tượng từ Map lấy từ SQLite
  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      rewardAmount: (map['rewardAmount'] as num).toDouble(),
      category: map['category'] as String,
      icon: map['icon'] as String,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    double? rewardAmount,
    String? category,
    String? icon,
    bool? isActive,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}
