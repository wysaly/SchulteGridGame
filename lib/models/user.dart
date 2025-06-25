/// 用户模型类
class User {
  final int id;
  final String account;
  final String password;
  final DateTime createdAt;

  User({
    required this.id,
    required this.account,
    required this.password,
    required this.createdAt,
  });

  /// 从Map构造User对象
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      account: map['account']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      createdAt: DateTime.parse(
        map['created_at']?.toString() ?? DateTime.now().toString(),
      ),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account': account,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
