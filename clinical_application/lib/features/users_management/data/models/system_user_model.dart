enum UserRole {
  manager,
  user,
  accountant;

  String get label {
    switch (this) {
      case UserRole.manager:
        return 'مدير';
      case UserRole.user:
        return 'مستخدم';
      case UserRole.accountant:
        return 'محاسب';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.manager:
        return 'manager';
      case UserRole.user:
        return 'user';
      case UserRole.accountant:
        return 'accountant';
    }
  }

  static UserRole fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'manager':
        return UserRole.manager;
      case 'accountant':
        return UserRole.accountant;
      default:
        return UserRole.user;
    }
  }
}

class SystemUser {
  // id == username (the API's primary key)
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String? createdAt;

  const SystemUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.createdAt,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String;
    return SystemUser(
      id: username,
      username: username,
      password: json['password'] as String? ?? '',
      role: UserRole.fromApiValue(json['role'] as String? ?? 'user'),
      createdAt: json['createdat']?.toString(),
    );
  }

  SystemUser copyWith({
    String? username,
    String? password,
    UserRole? role,
  }) {
    return SystemUser(
      id: username ?? this.username,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
