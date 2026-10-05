class User {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class AuthState {
  final bool isLoginLoading;
  final bool isRegisterLoading;
  final String? error;
  final User? user;
  final String? accessToken;

  AuthState({
    this.isLoginLoading = false,
    this.isRegisterLoading = false,
    this.error,
    this.user,
    this.accessToken,
  });

  bool get isAuthenticated => user != null && accessToken != null;

  AuthState copyWith({
    bool? isLoginLoading,
    bool? isRegisterLoading,
    String? error,
    User? user,
    String? accessToken,
  }) {
    return AuthState(
      isLoginLoading: isLoginLoading ?? this.isLoginLoading,
      isRegisterLoading: isRegisterLoading ?? this.isRegisterLoading,
      error: error,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
