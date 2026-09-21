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
  final bool isLoading;
  final String? error;
  final User? user;
  final String? accessToken;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.accessToken,
  });

  bool get isAuthenticated => user != null && accessToken != null;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    String? accessToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
